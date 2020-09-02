function errorCode = Start_Multi_Mode(Obj)

  short_warn('Use of Start_Multi_Mode() deprecated, use Start and Enable_Trigger()!');
  commandMask = bitor (Obj.mRegs('M2CMD_CARD_START'), Obj.mRegs('M2CMD_CARD_ENABLETRIGGER'));
  errorCode = spcm_dwSetParam_i32(...
      Obj.cardInfo.hDrv, ...
      Obj.mRegs('SPC_M2CMD'), ...
      commandMask);  % 100 = SPC_M2CMD
  if (errorCode ~= 0)
    [~, ~] = spcMCheckSetError (errorCode, Obj.cardInfo);
    spcMErrorMessageStdOut (Obj.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
  end

end
