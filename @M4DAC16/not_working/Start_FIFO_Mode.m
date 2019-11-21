function Start_FIFO_Mode(dac)

  mRegs = spcMCreateRegMap ();
  mErrors = spcMCreateErrorMap ();
 
  % set command flags
  commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));

  if ~dac.beSilent
    fprintf('[M4DAC16] Starting FIFO mode... ');
  end
  % start card
  errorCode = spcm_dwSetParam_i32 (...
    dac.cardInfo.hDrv, ...
    mRegs('SPC_M2CMD'), ...
    commandMask);

  % Check if error occured
  if (errorCode ~= 0)
    [success, dac.cardInfo] = spcMCheckSetError (errorCode, dac.cardInfo);
    spcMErrorMessageStdOut (dac.cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    return;
  else
    fprintf(' success!\n');
  end

end