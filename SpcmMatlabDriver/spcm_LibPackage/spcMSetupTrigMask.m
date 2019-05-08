%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupTrigMask:
% this function sets the trigger masks (singleSrc of other commands must 
% be false to use this)
%**************************************************************************

function [success, cardInfo] = spcMSetupTrigMask (cardInfo, channelOrMask0, channelOrMask1, channelAndMask0, channelAndMask1, trigOrMask, trigAndMask)
    
    error = 0;
    
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40410,      trigOrMask);  % 40410 = SPC_TRIG_ORMASK
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40430,     trigAndMask);  % 40430 = SPC_TRIG_ANDMASK
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40460,  channelOrMask0);  % 40460 = SPC_TRIG_CH_ORMASK0
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40461,  channelOrMask1);  % 40461 = SPC_TRIG_CH_ORMASK1
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40480, channelAndMask0);  % 40480 = SPC_TRIG_CH_ANDMASK0
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40481, channelAndMask1);  % 40481 = SPC_TRIG_CH_ANDMASK1
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);    




















   
    
   



    

