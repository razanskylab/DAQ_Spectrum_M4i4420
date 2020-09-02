% File: Full_Start.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description: starts card and enables triggers at the same time
% see also Start() Stop() Enable_Trigger() Force_Trigger()

function Full_Start(Obj)
  commandMask = bitor(Obj.mRegs('M2CMD_CARD_START'), Obj.mRegs('M2CMD_CARD_ENABLETRIGGER'));
  errCode = spcm_dwSetParam_i32(Obj.cardInfo.hDrv, Obj.mRegs('SPC_M2CMD'), commandMask);
  if (errCode ~= 0)
    [success, Obj.cardInfo] = spcMCheckSetError (errCode, Obj.cardInfo);
    spcMErrorMessageStdOut (Obj.cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    error(Obj.cardInfo.errorText);
  end
end
