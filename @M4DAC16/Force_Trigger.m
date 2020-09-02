% File: Force_Trigger.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description: enable the trigger, DOES NOT start the card
  % "This command forces a trigger even if none has been detected so far.
  % Sending this command together with the start command is similar to using the
  % software trigger"
% see also Start() Stop() Enable_Trigger() Force_Trigger()

function Force_Trigger(Obj)
  errCode = spcm_dwSetParam_i32(Obj.cardInfo.hDrv, Obj.mRegs('SPC_M2CMD'), Obj.mRegs('M2CMD_CARD_FORCETRIGGER'));
  if (errCode ~= 0)
    [success, Obj.cardInfo] = spcMCheckSetError (errCode, Obj.cardInfo);
    spcMErrorMessageStdOut (Obj.cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    error(Obj.cardInfo.errorText);
  end
end
