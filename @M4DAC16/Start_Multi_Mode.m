% File: Start_Multi_Mode.m @ M4DAC16
% Author: Urs Hofmann
% Mail: hofmannu@ethz.ch
% Date: 17.02.2021

% Description: Starts data acquisition through the multi mode

% Warning: Function deprecated and will be removed soon
% Replace with Start() followed by Enable_Trigger()

function errorCode = Start_Multi_Mode(Obj)

  error('Use of Start_Multi_Mode() deprecated, use Start and Enable_Trigger()!');
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
