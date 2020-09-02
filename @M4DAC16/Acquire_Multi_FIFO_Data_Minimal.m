% File: Acquire_Mulit_FIFO_Data.m @ M4DAC16

% Output:
%     - ch0: data acquired at channel 0, int16
%     - ch1: data acquired at channel 1, int16
%     - tsData: vector (single)

function [ch0, ch1, tsData] = Acquire_Multi_FIFO_Data_Minimal(Obj)
  
  ch0 = [];
  ch1 = [];
  tsData = [];

  % get all required variables once
  % calculate the fifo parameters which are used a lot once to safe time
  % during actual data acquisition
  Obj.FiFo.Set_shotsPerNotify(); % make sure we calculate correct value for this
  nCh = Obj.FiFo.nChannels;
  notifySize = Obj.FiFo.notifySize;
  samplesPerChannel = notifySize ./ nCh ./ Obj.FiFo.BYTES_PER_SAMPLE;
  nBlocks = Obj.FiFo.nBlocks;
  shotSize = Obj.FiFo.shotSize;
  shotSizePd = Obj.FiFo.shotSizePd;
  shotsPerNotify = Obj.FiFo.shotsPerNotify;
  notifySizeTS = Obj.FiFo.notifySizeTS;

  forcedTriggers = 0;
  % we have to acquire same sized shots for both channels
  % but we don't need super long shots for the PD channel
  % precalculate the index of the shots/indicies we want here, and then used it
  % during the acquisition to save time

  if nBlocks > 50
    updateBlocks = round(nBlocks ./ 50); % update ~100 times
  else
    updateBlocks = 2;
  end

  % do the actual data acquisition %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % this code is unrolled so we only calculate all the required variables once
  % instead of every for loop...it's not pretty but it's faster...
  for iBlock = 1:nBlocks
    Obj.FiFo.currentBlock = iBlock; % required to update depended properties!

    % ***** wait for the next block -> one block = n shots... *****
    errCode = spcm_dwSetParam_i32(Obj.cardInfo.hDrv, Obj.mRegs('SPC_M2CMD'), Obj.mRegs('M2CMD_DATA_WAITDMA'));
    
    if errCode == 263 % timeout during acq.
      % we force a trigger even and keep track of how many times this was neccesary
      [success, Obj.cardInfo] = spcMCheckSetError(errCode, Obj.cardInfo);
      break;
    else
      Obj.Handle_Error(errCode);
    end

    switch nCh
      case 1
        [errCode, ch0Block] = spcm_dwGetData(Obj.cardInfo.hDrv, 0, ...
          samplesPerChannel, nCh, Obj.FiFo.dataType);
        ch0(:,Obj.FiFo.currentShots) = reshape(ch0Block, shotSize, shotsPerNotify);
      case 2
        [errCode, ch0Block, ch1Block] = spcm_dwGetData(Obj.cardInfo.hDrv, 0, ...
          samplesPerChannel, nCh, Obj.FiFo.dataType);
        % ch0(:, Obj.FiFo.currentShots) = reshape(ch0Block, shotSize, shotsPerNotify);
        % ch1(:, Obj.FiFo.currentShots) = reshape(ch1Block, shotSizePd, shotsPerNotify);
        ch0 = [ch0, ch0Block];
        ch1 = [ch1, ch1Block];
    end
    Obj.Handle_Error(errCode);

    % FIXME only do this once in a while for better performance?
    if (Obj.tsBytesAvailable >= notifySizeTS)
      tsData = [tsData Obj.Poll_Time_Stamp_Data()];
    end
  end

  % poll last TS data here
  tsLastShots = Obj.Poll_Time_Stamp_Data();
  tsData = [tsData tsLastShots];
  tsData = single(tsData) ./ single(Obj.samplingRate);

  % done with actual data acquisition %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if (errCode ~= 0)
    txtMsg = ['Error occured during acquisition, error code: ', num2str(errCode), '.'];
    warning(txtMsg);
  end

  if (Obj.triggerCount ~= Obj.FiFo.nShots)
    warnText = sprintf('Trigger count: %i Expected shots: %i!\n',...
      Obj.triggerCount, Obj.FiFo.nShots);
    Obj.Verbose_Warn(warnText);
  end

  if forcedTriggers
    warnText = sprintf('We forced %i trigger events!\n', forcedTriggers);
    Obj.Verbose_Warn(warnText);
  end

end
