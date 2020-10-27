% File: Stop.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description: Stops the board manually.

function Stop(Obj)
  tic;
  Obj.VPrintF_With_ID('Stopping card...');
  errCode = spcm_dwSetParam_i32 (Obj.cardInfo.hDrv, Obj.mRegs('SPC_M2CMD'),Obj.mRegs('M2CMD_CARD_STOP'));
  if (errCode ~= 0)
    error(Obj.mErrorKeys(errCode));
  end
  Obj.Done();
end