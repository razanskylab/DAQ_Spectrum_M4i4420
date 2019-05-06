% File: Enable_Trigger.m @ FastDAQ
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description: enable the trigger, DOES NOT start the card
% NOTE probably has to be send after START!?!
  % "The trigger detection is enabled. This command can be either sent together
  % with the start command to enable trigger immediately or in a second call after
  % some external hardware has been started."
% see also Start() Stop() Enable_Trigger() Force_Trigger()

function Enable_Trigger(DAQ)
  errCode = spcm_dwSetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_M2CMD'), DAQ.mRegs('M2CMD_CARD_ENABLETRIGGER'));
  if (errCode ~= 0)
    [success, DAQ.cardInfo] = spcMCheckSetError (errCode, DAQ.cardInfo);
    spcMErrorMessageStdOut (DAQ.cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    error(DAQ.cardInfo.errorText);
  end
end
