function [ch0,ch1,tsData] = Acquire_Multi_FIFO_Data(DAQ,ch0,ch1)
  if nargin == 2
    ch1 = [];
  end
  tsData = [];

  DAQ.VPrintF('[M4DAC16] Starting data acquisition!\n'); tic;
  cpb = prep_console_progress_bar(DAQ.FiFo.nBlocks);
  cpb.start();
  tic
  updateBlocks = round(DAQ.FiFo.nBlocks./100); % update ~100 times
  for iBlock = 1:DAQ.FiFo.nBlocks
    if ~mod(iBlock,updateBlocks)
      text = sprintf('Block %d/%d', iBlock, DAQ.FiFo.nBlocks);
      cpb.setValue(iBlock);  cpb.setText(text);
    end

    DAQ.FiFo.currentBlock = iBlock; % required to update depended properties!
    switch DAQ.FiFo.nChannels
    case 1
      [tsShots,ch0Shots] = DAQ.Get_Next_Fifo_Block();
      ch0(:,DAQ.FiFo.currentShots) = ch0Shots;
    case 2
      [tsShots,ch0Shots,ch1Shots] = DAQ.Get_Next_Fifo_Block();
      ch0(:,DAQ.FiFo.currentShots) = ch0Shots;
      ch1(:,DAQ.FiFo.currentShots) = ch1Shots;
    end
    if ~isempty(tsShots) % we got time stamps (does not happen every block)
      tsData = [tsData tsShots];
    end
  end
  % poll last TS data here
  tsLastShots = DAQ.Poll_Time_Stamp_Data();
  tsData = [tsData tsLastShots];

  text = sprintf('Block %d/%d', DAQ.FiFo.nBlocks, DAQ.FiFo.nBlocks);
  cpb.setValue(DAQ.FiFo.nBlocks);  cpb.setText(text);
  cpb.stop();
  fprintf('\n');

  %% ---------------------------------------------------------------------------

  if (DAQ.triggerCount ~= DAQ.FiFo.nShots)
    warnText = sprintf('Trigger count: %i Expected shots: %i!\n',...
    DAQ.triggerCount,DAQ.FiFo.nShots)
    DAQ.Verbose_Warn(warnText);
  end
  DAQ.Free_FIFO_Buffer()
  DAQ.Stop();

  DAQ.VPrintF('[M4DAC16] Data acquisition completed in %2.2f s!\n',toc);
end
