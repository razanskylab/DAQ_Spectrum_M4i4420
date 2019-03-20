% File: Start.m @ FastDAQ
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description: starts card but DOES NOT enable the trigger
  % "Starts the card with all selected settings. This command automatically
  % writes all settings to the card if any of the settings has been changed
  % since the last one was written. After card has been started none of the
  % settings can be changed while the card is running"
% see also Start() Stop() Enable_Trigger() Force_Trigger()

function Start(DAQ)
  errCode = spcm_dwSetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_M2CMD'), DAQ.mRegs('M2CMD_CARD_START'));
  if (errCode ~= 0)
    [success, DAQ.cardInfo] = spcMCheckSetError (errCode, DAQ.cardInfo);
    spcMErrorMessageStdOut (DAQ.cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    error(DAQ.cardInfo.errorText);
  end
end
