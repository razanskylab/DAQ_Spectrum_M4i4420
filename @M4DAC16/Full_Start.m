% File: Full_Start.m @ FastDAQ
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description: starts card and enables triggers at the same time
% see also Start() Stop() Enable_Trigger() Force_Trigger()

function Full_Start(DAQ)
  commandMask = bitor (DAQ.mRegs('M2CMD_CARD_START'), DAQ.mRegs('M2CMD_CARD_ENABLETRIGGER'));
  errCode = spcm_dwSetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_M2CMD'), commandMask);
  if (errCode ~= 0)
    [success, DAQ.cardInfo] = spcMCheckSetError (errCode, DAQ.cardInfo);
    spcMErrorMessageStdOut (DAQ.cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    error(DAQ.cardInfo.errorText);
  end
end
