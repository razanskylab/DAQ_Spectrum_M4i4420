% File: Force_Trigger.m @ FastDAQ
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description: enable the trigger, DOES NOT start the card
  % "This command forces a trigger even if none has been detected so far.
  % Sending this command together with the start command is similar to using the
  % software trigger"
% see also Start() Stop() Enable_Trigger() Force_Trigger()

function Force_Trigger(DAQ)
  errCode = spcm_dwSetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_M2CMD'), DAQ.mRegs('M2CMD_CARD_FORCETRIGGER'));
  if (errCode ~= 0)
    [success, DAQ.cardInfo] = spcMCheckSetError (errCode, DAQ.cardInfo);
    spcMErrorMessageStdOut (DAQ.cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    error(DAQ.cardInfo.errorText);
  end
end
