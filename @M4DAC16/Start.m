% File: Start.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description: starts card but DOES NOT enable the trigger
  % "Starts the card with all selected settings. This command automatically
  % writes all settings to the card if any of the settings has been changed
  % since the last one was written. After card has been started none of the
  % settings can be changed while the card is running"
% see also Stop() Enable_Trigger() Force_Trigger()

function Start(Obj)
  tic;
  Obj.VPrintF_With_ID('Starting (trigger not enabled!)...');
  errCode = spcm_dwSetParam_i32(Obj.cardInfo.hDrv, Obj.mRegs('SPC_M2CMD'), Obj.mRegs('M2CMD_CARD_START'));
  if (errCode ~= 0)
    [~, Obj.cardInfo] = spcMCheckSetError (errCode, Obj.cardInfo);
    spcMErrorMessageStdOut (Obj.cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    error(Obj.cardInfo.errorText);
  end
  Obj.Done();
end
