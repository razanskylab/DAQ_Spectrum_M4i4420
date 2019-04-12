function [ch0,ch1,tsData] = Acquire_Multi_FIFO_Data(DAQ,ch0,ch1)
  if nargin == 2
    ch1 = [];
  end
  tsData = [];

  % get all required variables once
  % calculate the fifo parameters which are used a lot once to safe time
  % during actual data acquisition
  DAQ.FiFo.Set_shotsPerNotify(); % make sure we calculate correct value for this
  nCh = DAQ.FiFo.nChannels;
  notifySize = DAQ.FiFo.notifySize;
  samplesPerChannel = notifySize./nCh./DAQ.FiFo.BYTES_PER_SAMPLE;
  nBlocks = DAQ.FiFo.nBlocks;
  shotSize = DAQ.FiFo.shotSize;
  shotsPerNotify = DAQ.FiFo.shotsPerNotify;
  notifySizeTS = DAQ.FiFo.notifySizeTS;

  DAQ.VPrintF('[M4DAC16] Starting data acquisition!\n'); tic;
  cpb = prep_console_progress_bar(nBlocks);
  cpb.start();
  if nBlocks > 50
    updateBlocks = round(nBlocks./50); % update ~100 times
  else
    updateBlocks = 2;
  end

  tic
  % do the actual data acquisition %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % this code is unrolled so we only calculate all the required variables once
  % instead of every for loop...it's not pretty but it's faster...
  for iBlock = 1:nBlocks
    if ~mod(iBlock,updateBlocks)
      text = sprintf('Block %d/%d', iBlock, nBlocks);
      cpb.setValue(iBlock);  cpb.setText(text);
    end
    DAQ.FiFo.currentBlock = iBlock; % required to update depended properties!

    % ***** wait for the next block -> one block = n shots... *****
    errCode = spcm_dwSetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_M2CMD'), DAQ.mRegs('M2CMD_DATA_WAITDMA'));
    DAQ.Handle_Error(errCode);

    switch nCh
    case 1
      [errCode, ch0Block] = spcm_dwGetData(DAQ.cardInfo.hDrv, 0, ...
        samplesPerChannel, nCh, DAQ.FiFo.dataType);
      ch0(:,DAQ.FiFo.currentShots) = reshape(ch0Block,shotSize,shotsPerNotify);
    case 2
      [errCode, ch0Block, ch1Block] = spcm_dwGetData(DAQ.cardInfo.hDrv, 0, ...
        samplesPerChannel, nCh, DAQ.FiFo.dataType);
      ch0(:,DAQ.FiFo.currentShots) = reshape(ch0Block,shotSize,shotsPerNotify);
      ch1(:,DAQ.FiFo.currentShots) = reshape(ch1Block,shotSize,shotsPerNotify);
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
  tsData = single(tsData)./DAQ.samplingRate;
  % done with actual data acquisition %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if errCode
    fprintf('\n');
    short_warn('Error occured during acquisition!');
  else
    text = sprintf('Block %d/%d', nBlocks, nBlocks);
    cpb.setValue(nBlocks);  cpb.setText(text);
    cpb.stop();
    fprintf('\n');
  end

  %% ---------------------------------------------------------------------------
  if (DAQ.triggerCount ~= DAQ.FiFo.nShots)
    warnText = sprintf('Trigger count: %i Expected shots: %i!\n',...
      DAQ.triggerCount,DAQ.FiFo.nShots);
    DAQ.Verbose_Warn(warnText);
  end
  DAQ.Free_FIFO_Buffer()
  DAQ.Stop();

  DAQ.VPrintF('[M4DAC16] Data acquisition completed in %2.2f s!\n',toc);
end
