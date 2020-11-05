% File: Poll_Time_Stamp_Data.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description: because notify size of data and timestamps is different,
% we might end up with some time stamp data left after the last data
% has been acquired, this function polls that last bit of data
% also used in the Get_Next_Fifo_Block function to keep things clean

function [tsDataBlock,freqData] = Poll_Time_Stamp_Data(Obj,updateFreqInfo,targetFreq)

  nTimeStamps = Obj.tsBytesAvailable/8; % 1 Timestamp = 8 Byte

  % ----- get available timestamps -----
  [errCode, tsDataBlock] = spcm_dwGetTimestampData(Obj.cardInfo.hDrv, nTimeStamps);
  tsDataBlock = tsDataBlock(1:2:end); % get only lower 8-bytes

  Obj.Handle_Error(errCode);

  % if we want real time DAQ updates, get info on frequencies...
  if updateFreqInfo
    iBlock = Obj.FiFo.currentBlock;

    % collect freq. info for real time plotting
    timeData = single(tsDataBlock)./Obj.samplingRate;
    freqData = (1./diff(timeData))*1e-3; % trig. freq. in kHz
    targetFreq = targetFreq*1e-3; % convert target to kHz
      
    % theoretical max. freq. based on stage speed and step size
    lowFreqLim = targetFreq.*0.2; % we expect to have quite a few slower shots...

    % truncate low freq. data to not distort histogram too much...
    freqData(freqData<lowFreqLim) = lowFreqLim;
    Obj.StausData(iBlock, 8) = median(freqData);
    Obj.StausData(iBlock, 9) = min(freqData);
    Obj.StausData(iBlock, 10) = max(freqData);
  else
    freqData = [];
  end


end
