% File: Poll_Time_Stamp_Data.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description: because notify size of data and timestamps is different,
% we might end up with some time stamp data left after the last data
% has been acquired, this function polls that last bit of data
% also used in the Get_Next_Fifo_Block function to keep things clean

function [tsDataBlock] = Poll_Time_Stamp_Data(Obj)
  nTimeStamps = Obj.tsBytesAvailable/8; % 1 Timestamp = 8 Byte
  % ----- get available timestamps -----
  [errCode, tsDataBlock] = spcm_dwGetTimestampData(Obj.cardInfo.hDrv, nTimeStamps);
  tsDataBlock = tsDataBlock(1:2:end); % get only lowwer 8-bytes
end
