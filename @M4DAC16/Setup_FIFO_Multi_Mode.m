% File:     Setup_FIFO_Multi_Mode.m @ FastObj
% Mail:     johannesrebling@gmail.com

function Setup_FIFO_Multi_Mode(Obj)
  
  Obj.VPrintf('[M4DAC16] Preparing Multi-FiFo acquisition...');

  % SETUP FIFO SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % spcMSetupModeRecFIFOMulti (Obj.cardInfo, chEnableH, chEnableL, segmentSize, postSamples,segmentsToRec);
  % NOTE segmentSize in SAMPLES

  chEnableL = bitshift(1,Obj.FiFo.nChannels) - 1;
  [success, Obj.cardInfo] = spcMSetupModeRecFIFOMulti (Obj.cardInfo, 0, ...
    chEnableL, Obj.FiFo.shotSize, Obj.FiFo.postSamples, Obj.FiFo.nShots);
  if (success == false)
    spcMErrorMessageStdOut (Obj.cardInfo, 'Error: spcMSetupModeRecFIFOSingle:\n\t', true);
    error(Obj.cardInfo.errorText);
  end

  % allocate FIFO buffer memory %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Obj.VPrintF_With_ID('   Allocating FIFO data buffer (%2.1f MB).\n',Obj.FiFo.bufferSize*1e-6);
  %spcm_dwSetupFIFOBuffer(hDrv, dwBufType, bAllocate, bRead, dwBufferInBytes, dwNotifyInBytes);
  % bAllocate = 1 for allocation of FIFO buffer and 0 to set the FIFO buffer free a
  % bRead defines the direction of FIFO transfer: 1 is reading
  % The value dwBufferInBytes defines the length of the buffer to allocate in bytes.
  % The value dwNotifyInBytes defines the notify size in bytes.
  % This is the block size that can be read out from the FIFO buffer using the GetData
  % and the GetRAWData functions.

  errCode = spcm_dwSetupFIFOBuffer (Obj.cardInfo.hDrv, Obj.SAMPLE_DATA, 1, 1, ...
    Obj.FiFo.bufferSize, Obj.FiFo.notifySize);
  % NOTE bufferSize in Bytes,
  % NOTE notifySize in Bytes

  if (errCode ~= 0)
    [~, Obj.cardInfo] = spcMCheckSetError (errCode, Obj.cardInfo);
    spcMErrorMessageStdOut (Obj.cardInfo, 'spcm_dwSetupFIFOBuffer:\n\t', true);
    error(Obj.cardInfo.errorText);
  end


  % allocate timestamps buffer memory %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % In this example the notify size is set to zero, meaning that we don’t want to
  % be notified until all extra data has been transferred. Please have a look at
  % the sample data transfer in an earlier chapter to see more details on the
  % notify size.
  % Obj.VPrintF_With_ID('   Allocating FIFO time stamp buffer (%1.0f kB).\n',Obj.FiFo.bufferSizeTS*1e-3);
  errCode = spcm_dwSetupFIFOBuffer(Obj.cardInfo.hDrv,Obj.TIMESTAMP_DATA,1,1,...
    Obj.FiFo.bufferSizeTS,Obj.FiFo.notifySizeTS);
  if errCode
    [~, Obj.cardInfo] = spcMCheckSetError (errCode, Obj.cardInfo);
    spcMErrorMessageStdOut (Obj.cardInfo, 'Error: spcm_dwSetupFIFOBuffer:\n\t', true);
    error(Obj.cardInfo.errorText);
  end

  Obj.VPrintf('done!\n');

end
