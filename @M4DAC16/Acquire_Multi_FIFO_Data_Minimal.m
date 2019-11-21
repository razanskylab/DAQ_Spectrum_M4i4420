% File: Acquire_Mulit_FIFO_Data.m @ M4DAC16

% Output:
%     - ch0: data acquired at channel 0, int16
%     - ch1: data acquired at channel 1, int16
%     - tsData: vector (single)

function [ch0, ch1, tsData] = Acquire_Multi_FIFO_Data_Minimal(DAQ)
  
  ch0 = [];
  ch1 = [];
  tsData = [];

  % get all required variables once
  % calculate the fifo parameters which are used a lot once to safe time
  % during actual data acquisition
  DAQ.FiFo.Set_shotsPerNotify(); % make sure we calculate correct value for this
  nCh = DAQ.FiFo.nChannels;
  notifySize = DAQ.FiFo.notifySize;
  samplesPerChannel = notifySize ./ nCh ./ DAQ.FiFo.BYTES_PER_SAMPLE;
  nBlocks = DAQ.FiFo.nBlocks;
  shotSize = DAQ.FiFo.shotSize;
  shotSizePd = DAQ.FiFo.shotSizePd;
  shotsPerNotify = DAQ.FiFo.shotsPerNotify;
  notifySizeTS = DAQ.FiFo.notifySizeTS;

  forcedTriggers = 0;
  % we have to acquire same sized shots for both channels
  % but we don't need super long shots for the PD channel
  % precalculate the index of the shots/indicies we want here, and then used it
  % during the acquisition to save time

  DAQ.VPrintF('[M4DAC16] Starting data acquisition!\n');

  if nBlocks > 50
    updateBlocks = round(nBlocks ./ 50); % update ~100 times
  else
    updateBlocks = 2;
  end

  % do the actual data acquisition %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % this code is unrolled so we only calculate all the required variables once
  % instead of every for loop...it's not pretty but it's faster...
  for iBlock = 1:nBlocks
    DAQ.FiFo.currentBlock = iBlock; % required to update depended properties!

    % ***** wait for the next block -> one block = n shots... *****
    errCode = spcm_dwSetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_M2CMD'), DAQ.mRegs('M2CMD_DATA_WAITDMA'));
    
    if errCode == 263 % timeout during acq.
      % we force a trigger even and keep track of how many times this was neccesary
      [success, DAQ.cardInfo] = spcMCheckSetError(errCode, DAQ.cardInfo);
      break;
    else
      DAQ.Handle_Error(errCode);
    end

    switch nCh
      case 1
        [errCode, ch0Block] = spcm_dwGetData(DAQ.cardInfo.hDrv, 0, ...
          samplesPerChannel, nCh, DAQ.FiFo.dataType);
        ch0(:,DAQ.FiFo.currentShots) = reshape(ch0Block,shotSize,shotsPerNotify);
      case 2
        [errCode, ch0Block, ch1Block] = spcm_dwGetData(DAQ.cardInfo.hDrv, 0, ...
          samplesPerChannel, nCh, DAQ.FiFo.dataType);
        % ch0(:, DAQ.FiFo.currentShots) = reshape(ch0Block, shotSize, shotsPerNotify);
        % ch1(:, DAQ.FiFo.currentShots) = reshape(ch1Block, shotSizePd, shotsPerNotify);
        ch0 = [ch0, ch0Block];
        ch1 = [ch1, ch1Block];
    end
    DAQ.Handle_Error(errCode);

    % FIXME only do this once in a while for better performance?
    if (DAQ.tsBytesAvailable >= notifySizeTS)
      tsData = [tsData DAQ.Poll_Time_Stamp_Data()];
    end
  end

  % poll last TS data here
  tsLastShots = DAQ.Poll_Time_Stamp_Data();
  tsData = [tsData tsLastShots];
  tsData = single(tsData) ./ DAQ.samplingRate;

  % done with actual data acquisition %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if (errCode ~= 0)
    warning(['Error occured during acquisition, error code: ', num2str(errCode), '.']);
  end

  DAQ.VPrintF('[M4DAC16] Data acquisition completed in %2.2f s!\n',toc);

  %% ---------------------------------------------------------------------------
  if (DAQ.triggerCount ~= DAQ.FiFo.nShots)
    warnText = sprintf('Trigger count: %i Expected shots: %i!\n',...
      DAQ.triggerCount,DAQ.FiFo.nShots);
    DAQ.Verbose_Warn(warnText);
  end

  if forcedTriggers
    warnText = sprintf('We forced %i trigger events!\n',forcedTriggers);
    DAQ.Verbose_Warn(warnText);
  end

  size(ch0);

end
