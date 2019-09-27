%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 11/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMDemuxDigitalData
% demultiplex RAW digital data to a [ChannelIndex, Value] matrix
%**************************************************************************

function [DigData] = spcMDemuxDigitalData (RAWData, RAWDataLen, channels)

    DigData = int8(zeros (channels, RAWDataLen * 16 / channels));
    
    dataIdx = 0;
    
    for rawIdx=1 : RAWDataLen
        
      %  fprintf ('rawIdx = %d\n', rawIdx);
        
        % ----- get 16 bit RAW data value -----
        bitVal16 = double(RAWData (1, rawIdx));

        % ----- convert to complement if sample is less zero -----  
        if (bitVal16 < 0)
            bitVal16 = bitcmp (bitVal16*-1 -1, 16);
        end  
        
        switch channels
        
            case { 1, 2, 4, 8 }
            
                % ----- 1, 2, 4, 8 channels : one 16 bit sample contains more than one sample for all channels -----
                for chIdx=1 : 16
                    if (mod(chIdx-1, channels) == 0)
                        dataIdx = dataIdx + 1;
                    end
                    bitVal = bitand (bitVal16, 1);
                    bitVal16 = bitshift (bitVal16, -1);    
                    
                    DigData (mod(chIdx-1, channels)+1, dataIdx) = bitVal;
                end
            case 16
                
                % ----- 16 channels : one 16 bit sample contains one sample for all channels -----
                dataIdx = rawIdx;
                
                for chIdx=1 : 16
                    bitVal = bitand (bitVal16, 1);
                    bitVal16 = bitshift (bitVal16, -1);
                    
                    DigData (chIdx, dataIdx) = bitVal;
                end
            
            case 32
                
                % ----- 32 channels : two 16 bit samples contains one sample for all channels -----
                if (mod (rawIdx-1, 2) == 0)
                    idxOffset = 0;
                    dataIdx = dataIdx + 1;
                else
                    idxOffset = 16;
                end
                
                for chIdx=1 : 16
                    bitVal = bitand (bitVal16, 1);
                    bitVal16 = bitshift (bitVal16, -1);   
						
                    DigData (chIdx+idxOffset, dataIdx) = bitVal;
                end
                    
            case 64
                
                % ----- 64 channels : four 16 bit samples contains one sample for all channels -----
                switch mod (rawIdx-1, 4)
                    case 0
                        idxOffset = 0;
                        dataIdx = dataIdx + 1;
                    case 1
                        idxOffset = 32;
                    case 2
                        idxOffset = 16;
                    case 3
                        idxOffset = 48;
                end
                
                for chIdx=1 : 16
                    bitVal = bitand (bitVal16, 1);
                    bitVal16 = bitshift (bitVal16, -1);   
                
                    DigData (chIdx+idxOffset, dataIdx) = bitVal;
                end
        end
   end
        
  