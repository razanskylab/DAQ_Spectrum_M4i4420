% File: Stop.m @ M4DAC16
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com
% Date: 17.02.2021

% Description: Stops the board manually.

function Stop(Obj)
  tic;
  Obj.VPrintf('[M4DAC16] Stopping card... ');
  errCode = spcm_dwSetParam_i32 (Obj.cardInfo.hDrv, Obj.mRegs('SPC_M2CMD'),Obj.mRegs('M2CMD_CARD_STOP'));
  if (errCode ~= 0)
    error(Obj.mErrorKeys(errCode));
  end
  Obj.VPrintf(' done!\n');
end