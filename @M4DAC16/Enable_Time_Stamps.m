% File: Enable_Time_Stamps.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description:

function Enable_Time_Stamps(Obj)
  % SETUP timestamp %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  mode = bitor(Obj.mRegs('SPC_TSMODE_STARTRESET'),Obj.mRegs('SPC_TSCNT_INTERNAL'));
  % SPC_TSMODE_STARTRESET = Counter is reset on every card start, all timestamps are in relation to card start.
  % SPC_TSCNT_INTERNAL = Counter is running with complete width on sampling clock
  [success, Obj.cardInfo] = spcMSetupTimestamp (Obj.cardInfo, mode, 0);
  if (success == false)
    spcMErrorMessageStdOut (Obj.cardInfo, 'Error: spcMSetupTimestamp:\n\t', true);
    error('Enable_Time_Stamps failed');
  end
end
