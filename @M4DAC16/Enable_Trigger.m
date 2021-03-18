% File: Enable_Trigger.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description: enable the trigger, DOES NOT start the card
% NOTE probably has to be send after START!?!
  % "The trigger detection is enabled. This command can be either sent together
  % with the start command to enable trigger immediately or in a second call after
  % some external hardware has been started."
% see also Start() Stop() Enable_Trigger() Force_Trigger()

function Enable_Trigger(Obj)
  tic;
  Obj.VPrintf('[M4DAC16] Enabling trigger input...');
  errCode = spcm_dwSetParam_i32(...
  	Obj.cardInfo.hDrv, Obj.mRegs('SPC_M2CMD'), Obj.mRegs('M2CMD_CARD_ENABLETRIGGER'));
  if (errCode ~= 0)
    [~, Obj.cardInfo] = spcMCheckSetError (errCode, Obj.cardInfo);
    spcMErrorMessageStdOut (Obj.cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    error(Obj.cardInfo.errorText);
  end
  Obj.VPrintf('done!\n');
end
