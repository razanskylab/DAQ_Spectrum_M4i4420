%**************************************************************************
% Reads binary data (SBench6 export)
% *************************************************************************
% Return values:
% numChannels: Number of channels
% ChData_mV (1): Data of channel 0 (Unit: mV)
% ChData_mV (2): Data of channel 1 (Unit: mV)
% ChData_mV (n): Data of channel n-1 (Unit: mV)
% ScaleX_us: Time base data vector (Unit: us)
% *************************************************************************
% Example:
% Call: [ChData_mV, ScaleX_us, numChannels] = spcMReadSBench6BinaryExport ('export.bin')
% Reads the complete data from the file
%
% Call: [ChData_mV, ScaleX_us, numChannels] = spcMReadSBench6BinaryExport ('export.bin', 1024, 65536)
% Reads 64kS for each available channel starting at offset position 1kS
%**************************************************************************
function [ChData_mV, ScaleX_us, numChannels] = spcMReadSBench6BinaryExport (binaryFilePath, offset, length)

[pathstr, name, ext] = fileparts (binaryFilePath);

% create header file path
if isempty (pathstr)
    headerFilePath = strcat (name, '_binheader.txt');
else
    headerFilePath = strcat (pathstr, '\', name, '_binheader.txt');
end

maxIRangeCnt = 0;

% get some infos from header file
fileID = fopen (headerFilePath);

textLine = fgets (fileID);
while ischar (textLine)
    
    lineSplit = strsplit (textLine);
    
    if strfind (textLine, 'OrigMaxRange') == 1
        maxIRangeCnt = maxIRangeCnt + 1;
        maxIRanges(maxIRangeCnt) = str2double (lineSplit (3));
    end
        
    if strfind (textLine, 'FileType') == 1
      fileType = lineSplit (3); 
    end
    
    if strfind (textLine, 'NumAChannels') == 1
      numChannels = str2double (lineSplit (3));    
    end
    
    if strfind (textLine, 'MaxADCValue') == 1
      maxADCValue = str2double (lineSplit (3));    
    end
    
    if strfind (textLine, 'LenL') == 1
        lengthPerChL = str2double (lineSplit (3));
    end
    
    if strfind (textLine, 'LenH') == 1
        lengthPerChH = str2double (lineSplit (3));
    end
    
    if strfind (textLine, 'TrigPosL') == 1
        trigPosL = str2double (lineSplit (3));
    end
    
    if strfind (textLine, 'TrigPosH') == 1
        trigPosH = str2double (lineSplit (3));
    end
    
    if strfind (textLine, 'TrigDelayL') == 1
        trigDelayL = str2double (lineSplit (3));
    end
    
    if strfind (textLine, 'TrigDelayH') == 1
        trigDelayH = str2double (lineSplit (3));
    end
    
    if strfind (textLine, 'Samplerate') == 1
        samplerate = str2double (lineSplit (3));
    end
    
    if strfind (textLine, 'Resolution') == 1
        resolution = str2double (lineSplit (3));
    end
    
    textLine = fgets (fileID);
end

fclose (fileID);

lengthPerCh = bitor (bitshift (lengthPerChH, 32), lengthPerChL);
trigPos = bitor (bitshift (trigPosH, 32), trigPosL);
trigDelay = bitor (bitshift (trigDelayH, 32), trigDelayL);

if resolution == 8
    bytesPerSample = 1;
    dataFormat = 'int8';
else
    bytesPerSample = 2;
    dataFormat = 'int16';
end
    
if ~exist ('offset', 'var')
  offset = 0;
else
  offset = bytesPerSample * offset * numChannels;
end

if ~exist ('length', 'var')
  length = 0;
end

fileID = fopen (binaryFilePath);

if (offset > 0)
  fseek (fileID, offset, 'bof');
end

if (length > 0)
  lengthPerCh = length;
  DataBuffer = fread (fileID, numChannels * lengthPerCh, dataFormat);
else
  DataBuffer = fread (fileID, dataFormat);
end  
  
fclose (fileID);

% demultiplex data and convert samples to mVolt values
for Idx = 1 : numChannels
    ChData_mV (Idx, 1 : 1 : lengthPerCh) = DataBuffer (Idx : numChannels : numChannels * lengthPerCh) * maxIRanges (Idx) / maxADCValue;
end

% calculate time base data
timeBase_us = 1 / samplerate * 1000000;
for samplePos = 0 : lengthPerCh - 1
    timePos_us = (samplePos - trigPos + trigDelay) * timeBase_us;
    ScaleX_us (samplePos + 1) = timePos_us;
end    
