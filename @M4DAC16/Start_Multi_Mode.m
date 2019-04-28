function errorCode = Start_Multi_Mode(dac)

  commandMask = bitor (dac.mRegs('M2CMD_CARD_START'), dac.mRegs('M2CMD_CARD_ENABLETRIGGER'));
  errorCode = spcm_dwSetParam_i32(...
      dac.cardInfo.hDrv, ...
      dac.mRegs('SPC_M2CMD'), ...
      commandMask);  % 100 = SPC_M2CMD
  if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, dac.cardInfo);
    spcMErrorMessageStdOut (dac.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
  end

end
