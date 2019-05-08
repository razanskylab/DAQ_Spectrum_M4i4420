%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupAnalogInputChannel:
% allows all analog input channel related settings
%**************************************************************************

function [success, cardInfo] = spcMSetupAnalogInputChannel (cardInfo, channel, inputRange, term, inputOffset, diffInput)

    if (channel < 0) | (channel >= cardInfo.maxChannels)
        sprintf (cardInfo.errorText, 'spcMSetupAnalogInputChannel: channel number %d not valid. Channels range from 0 to %d\n', channel, cardInfo.maxChannels);
        success = false;
        return;
    end
    
    if (term ~= 0) & (term ~= 1)
        sprintf (cardInfo.errorText, 'spcMSetupAnalogInputChannel: term must be 0 (disable) or 1 (enable)');
        success = false;
        return;
    end
    
     if (diffInput ~= 0) & (diffInput ~= 1)
        sprintf (cardInfo.errorText, 'spcMSetupAnalogInputChannel: diffInput must be 0 (disable) or 1 (enable)');
        success = false;
        return;
    end
    
    error = 0;
   
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 30010 + channel * 100,  inputRange);  % 30010 = SPC_AMP0
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 30000 + channel * 100, inputOffset);  % 30000 = SPC_OFFS0
    
    if cardInfo.AI.inputTermAvailable == true
         error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 30030 + channel * 100,     term);  % 30030 = SPC_50OHM0
    end
   
    if cardInfo.AI.diffModeAvailable == true 
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 30040 + channel * 100, diffInput);  % 30040 = SPC_DIFF0
    end
    
    % ----- store some information in the structure -----
    cardInfo.AI.setRange(channel+1)  = inputRange;
    cardInfo.AI.setOffset(channel+1) = inputOffset;
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);    


























    
