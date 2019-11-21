% File: Enable_Time_Stamps.m @ FastDAQ
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description:

function Enable_Time_Stamps(DAQ)
  % SETUP timestamp %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  mode = bitor(DAQ.mRegs('SPC_TSMODE_STARTRESET'),DAQ.mRegs('SPC_TSCNT_INTERNAL'));
  % SPC_TSMODE_STARTRESET = Counter is reset on every card start, all timestamps are in relation to card start.
  % SPC_TSCNT_INTERNAL = Counter is running with complete width on sampling clock
  [success, DAQ.cardInfo] = spcMSetupTimestamp (DAQ.cardInfo, mode, 0);
  if (success == false)
    spcMErrorMessageStdOut (DAQ.cardInfo, 'Error: spcMSetupTimestamp:\n\t', true);
    error();
  end
end
