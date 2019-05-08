%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupTrigChannel:
% channel trigger is set for each channel separately
%**************************************************************************

function [success, cardInfo] = spcMSetupTrigChannel (cardInfo, channel, trigMode, trigLevel0, trigLevel1, pulsewidth, trigOut, singleSrc)
    
    if (channel < 0) | (channel > cardInfo.maxChannels)
        sprintf (cardInfo.errorText, 'spcMSetupTrigChannel: channel number %d not valid. Channels range from 0 to %d\n', channel, cardInfo.maxChannels);
        success = false;
        return;
    end
    
    if (trigOut ~= 0) & (trigOut ~= 1)
        sprintf (cardInfo.errorText, 'spcMSetupTrigChannel: trigOut must be 0 (disable) or 1 (enable)');
        success = false;
        return;
    end
    
    if (singleSrc ~= 0) & (singleSrc ~= 1)
        sprintf (cardInfo.errorText, 'spcMSetupTrigChannel: singleSrc must be 0 (disable) or 1 (enable)');
        success = false;
        return;
    end
    
    error = 0;
    
    % ----- setup the trigger mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40610 + channel, trigMode);    % 40610 = SPC_TRIG_CH0_MODE
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 44101 + channel, pulsewidth);  % 44101 = SPC_TRIG_CH0_PULSEWIDTH
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 42200 + channel, trigLevel0);  % 42200 = SPC_TRIG_CH0_LEVEL0
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 42300 + channel, trigLevel1);  % 42300 = SPC_TRIG_CH0_LEVEL1
    
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40100, trigOut);  % 40100 = SPC_TRIG_OUTPUT
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40110, 0);  % 40110 = SPC_TRIG_TERM
    
    % ----- on singleSrc flag no other trigger source is used -----
    if singleSrc == 1
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40410, 0);  % 40410 = SPC_TRIG_ORMASK
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40430, 0);  % 40430 = SPC_TRIG_ANDMASK
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40461, 0);  % 40461 = SPC_TRIG_CH_ORMASK1
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40481, 0);  % 40481 = SPC_TRIG_CH_ANDMASK1    
        
        % ----- some cards need the and mask to use on pulsewidth mode -> to be sure we set the AND mask for all pulsewidth cards -----
        if (bitand (trigMode, 67108864) ~= 0) | (bitand (trigMode, 33554432) ~= 0) % 67108864 = SPC_TM_PW_GREATER, 33554432 = SPC_TM_PW_SMALLER
            error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40460,                     0);  % 40460 = SPC_TRIG_CH_ORMASK0
            error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40480, bitshift (1, channel));  % 40480 = SPC_TRIG_CH_ANDMASK0
        else
            error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40460, bitshift (1, channel));  % 40460 = SPC_TRIG_CH_ORMASK0
            error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40480,                     0);  % 40480 = SPC_TRIG_CH_ANDMASK0
        end
    end
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);    
    

    

