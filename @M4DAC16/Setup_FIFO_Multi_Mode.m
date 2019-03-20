% File:     Setup_FIFO_Multi_Mode.m @ FastDAQ
% Mail:     johannesrebling@gmail.com

function Setup_FIFO_Multi_Mode(DAQ,nChannels,nShots)

  fprintf('[FastDAQ] Setting up FIFO Mode.\n');

  % helper maps to use label names for registers and errors
  mRegs = spcMCreateRegMap();
  mErrors = spcMCreateErrorMap();

  % no need to set trigger frequency since this is done by Initialize_Hardware.m
  % no need to set trigger mode since this is done by Initialize_Hardware.m
  % no need to program input channels since this is already done

  % *** Set the recording mode to FIFO multi ***
  [success, DAQ.cardInfo] = spcMSetupModeRecFIFOMulti (...
    DAQ.cardInfo, ... % cardInfo
    DAQ.fifoMode.chMaskH, ... % mask for upper 32 channels
    DAQ.fifoMode.chMaskL, ... % mask for lower 32 channels
    DAQ.fifoMode.nSamples, ... % segment size
    DAQ.fifoMode.postSamples, ... % postSamples
    DAQ.fifoMode.loopsToRec); % segments to record

  if (success == false)
      spcMErrorMessageStdOut (DAQ.cardInfo, ...
        'Error: spcMSetupModeRecFIFOSingle:\n\t', true);
      return;
  end

  % *** Allocate buffer memory ***
  errorCode = spcm_dwSetupFIFOBuffer(...
    DAQ.cardInfo.hDrv, ...
    1, ... % dwBufType
    1, ... % bAllocate
    1, ... % bRead
    DAQ.fifoMode.nSamples * DAQ.fifoMode.loopsToRec, ... % dwBuffer
    0); % dwNotify

  % dwBufType:
  %   0 - sample data
  %   1 - timestamp data
  %   2 - slow ABA data
  % bAllocate:
  %   1 - allocation of the FIFO buffer
  %   0 - set the buffer free again
  % bRead:
  %   1 - Reading data from card to PC memory
  %   0 - Writing data from the PC memory to the card
  % dwBuffer:
  %   Length of the buffer to allocate in bytes
  % dwNotify:
  %   notify size in bytes, block size that can be read from the FIFO buffer
  %   using GetData and GetRAWData functions

  if (errorCode ~= 0)
      [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
      spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetupFIFOBuffer:\n\t', true);
      return;
  end

  % *** Set timeout ***

  errorCode = spcm_dwSetParam_i32 (...
    DAQ.cardInfo.hDrv, ...
    mRegs('SPC_TIMEOUT'), ...
    50000);

  if (errorCode ~= 0)
    [success, DAQ.cardInfo] = spcMCheckSetError (errorCode, DAQ.cardInfo);
    spcMErrorMessageStdOut (...
      DAQ.cardInfo, ...
      'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
  end

end
