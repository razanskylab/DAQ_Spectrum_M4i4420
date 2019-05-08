%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 11/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMCalcSignal:
% Calculates waveform data 
% shape: 1 : sine
%        2 : rectangel
%        3 : triangel
%        4 : sawtooth
%**************************************************************************

function [success, cardInfo, signal] = spcMCalcSignal (cardInfo, len, shape, loops, gainP)
    
    signal = zeros (1, len);

    if (gainP < 0) | (gainP > 100)
        cardInfo.errorText = 'spcMCalcSignal: gainP must be a value between 0 and 100';
        success = false;
        return;
    end

    if (shape < 1) | (shape > 4)
        cardInfo.errorText = 'spcMCalcSignal: shape must set to 1 (sine), 2 (rectangel), 3 (triangel), 4 (sawtooth)';
        success = false;
        return;
    end
    
    % ----- calculate resolution -----
    switch cardInfo.bytesPerSample
         
         case 1
             maxFS = 127;
             minFS = -128;
             scale = 127 * gainP / 100;
             
         case 2
             maxFS = 8191;
             minFS = -8192;
             scale = 8191 * gainP / 100;
     end
    
     % ----- calculate waveform -----
     block = len / loops;
     blockHalf = block / 2;
     sineXScale = 2 * pi / len * loops;
     span = maxFS - minFS;
     
     for i=1 : len
    
        posInBlock = mod (i, block);
        
        switch shape
            
            % ----- sine -----
            case 1
                signal (1, i) = scale * sin (sineXScale*i);
    
            % ----- rectangel -----
            case 2
                if posInBlock < blockHalf
                    signal (1, i) = maxFS;
                else
                    signal (1, i) = minFS;
                end
            
           % ----- triangel -----
           case 3
               if posInBlock < blockHalf
                   signal (1, i) = minFS + posInBlock * span / blockHalf;
              else
                   signal (1, i) = maxFS - (posInBlock - blockHalf) * span / blockHalf;
              end     
         
          % ----- sawtooth -----
          case 4            
            signal (1, i) = minFS + posInBlock * span / block;
        end    
    end
    
    success = true;
