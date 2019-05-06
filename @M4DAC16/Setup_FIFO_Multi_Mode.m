% File:     Setup_FIFO_Multi_Mode.m @ FastDAQ
% Mail:     johannesrebling@gmail.com

function Setup_FIFO_Multi_Mode(DAQ)
  tic;
  DAQ.PrintF('[M4DAC16] Preparing Multi-FiFo acquisition.\n');


  % SETUP FIFO SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % spcMSetupModeRecFIFOMulti (DAQ.cardInfo, chEnableH, chEnableL, segmentSize, postSamples,segmentsToRec);
  % NOTE!!! segmentSize in SAMPLES

  chEnableL = bitshift(1,DAQ.FiFo.nChannels) - 1;
  [success, DAQ.cardInfo] = spcMSetupModeRecFIFOMulti (DAQ.cardInfo, 0, ...
    chEnableL, DAQ.FiFo.shotSize, DAQ.FiFo.postSamples, DAQ.FiFo.nShots);
  if (success == false)
    spcMErrorMessageStdOut (DAQ.cardInfo, 'Error: spcMSetupModeRecFIFOSingle:\n\t', true);
    error(DAQ.cardInfo.errorText);
  end

  % allocate FIFO buffer memory %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % DAQ.VPrintF('   Allocating FIFO data buffer (%2.1f MB).\n',DAQ.FiFo.bufferSize*1e-6);
  %spcm_dwSetupFIFOBuffer(hDrv, dwBufType, bAllocate, bRead, dwBufferInBytes, dwNotifyInBytes);
  % bAllocate = 1 for allocation of FIFO buffer and 0 to set the FIFO buffer free a
  % bRead defines the direction of FIFO transfer: 1 is reading
  % The value dwBufferInBytes defines the length of the buffer to allocate in bytes.
  % The value dwNotifyInBytes defines the notify size in bytes.
  % This is the block size that can be read out from the FIFO buffer using the GetData
  % and the GetRAWData functions.

  errCode = spcm_dwSetupFIFOBuffer (DAQ.cardInfo.hDrv, DAQ.SAMPLE_DATA, 1, 1, ...
    DAQ.FiFo.bufferSize, DAQ.FiFo.notifySize);
  % NOTE! bufferSize in Bytes,
  % NOTE! notifySize in Bytes

  if (errCode ~= 0)
    [success, DAQ.cardInfo] = spcMCheckSetError (errCode, DAQ.cardInfo);
    spcMErrorMessageStdOut (DAQ.cardInfo, 'spcm_dwSetupFIFOBuffer:\n\t', true);
    error(DAQ.cardInfo.errorText);
  end


  % allocate timestamps buffer memory %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % In this example the notify size is set to zero, meaning that we don’t want to
  % be notified until all extra data has been transferred. Please have a look at
  % the sample data transfer in an earlier chapter to see more details on the
  % notify size.
  % DAQ.VPrintF('   Allocating FIFO time stamp buffer (%1.0f kB).\n',DAQ.FiFo.bufferSizeTS*1e-3);
  errCode = spcm_dwSetupFIFOBuffer(DAQ.cardInfo.hDrv,DAQ.TIMESTAMP_DATA,1,1,...
    DAQ.FiFo.bufferSizeTS,DAQ.FiFo.notifySizeTS);
  if errCode
    [success, DAQ.cardInfo] = spcMCheckSetError (errCode, DAQ.cardInfo);
    errCode
    spcMErrorMessageStdOut (DAQ.cardInfo, 'Error: spcm_dwSetupFIFOBuffer:\n\t', true);
    error(DAQ.cardInfo.errorText);
  end

end
