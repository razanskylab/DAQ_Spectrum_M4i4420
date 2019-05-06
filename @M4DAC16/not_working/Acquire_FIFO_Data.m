% File:     Acquire_FIFO_Data.m @ M4DAC16
% Author:   Urs Hofmann
% Date:     27. Mar 2018
% Mail:     urshofmann@gmx.net
% Version:  1.0

% Description: DAQ will read and store all the data within its external buffer
% if its setted up in FIFO mode. This function is then used to read out the buffer.

function acquiredData = Acquire_FIFO_Data(dac)

  if ~dac.beSilent
    fprintf('[M4DAC16] Acquiring FIFO Data.\n');
  end

  mRegs = spcMCreateRegMap ();
  mErrors = spcMCreateErrorMap ();

  commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));

  errorCode = spcm_dwSetParam_i32 (...
    dac.cardInfo.hDrv, ...
    mRegs('SPC_M2CMD'), ...
    commandMask);

  % Check if error occured
  if (errorCode ~= 0)
    [success, dac.cardInfo] = spcMCheckSetError (errorCode, dac.cardInfo);
    spcMErrorMessageStdOut (dac.cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    return;
  end

  % ----- get data block for two channels with offset = 0 -----
  if ~dac.beSilent
    fprintf('[M4DAC16] Reading data from channels.\n')
  end

  [errorCode, acquiredData(1,:), acquiredData(2,:)] = spcm_dwGetData( ...
    dac.cardInfo.hDrv, ...       % physical address of card
    dac.offset, ...               % offset start address
    dac.fifoMode.nSamples * dac.fifoMode.loopsToRec, ... % lenght of buffer to read
    dac.cardInfo.setChannels, ...   % number of channels to read
    dac.dataType);    % datatype

  if (errorCode ~= 0)
    [success, dac.cardInfo] = spcMCheckSetError (errorCode, dac.cardInfo);
    spcMErrorMessageStdOut (dac.cardInfo, 'Error: spcm_dwGetData:\n\t', true);
    return;
  end

  if ~dac.beSilent
    fprintf(['[FastDAQ] Acquired ', num2str(length(acquiredData)) , ' samples.\n']);
  end

  %samplesTransferred = blockCounter * dac.fifoMode.notifySize / 1024 / 1024;
  %fprintf(['[FastDAQ] Number of samples transfered to computer ', ...
%    num2str(samplesTransferred), '.\n']);

end
