%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupTrigExternalLevel:
% external trigger with comparator levels
%**************************************************************************

function [success, cardInfo] = spcMSetupTrigExternalLevel (cardInfo, extMode, level0, level1, trigTerm, ACCoupling, pulsewidth, singleSrc, extLine)
    
    error = 0;
    
    % ----- not supported by M2i and M2i Express cards as they have plain TTL trigger
    if or ((bitand (cardInfo.cardType, 16711680) == 196608), (bitand (cardInfo.cardType, 16711680) == 262144))
        sprintf (cardInfo.errorText, 'spcMSetupTrigExternalLevel: function not uspported on M2i and M2i-Express cards\n');
        success = false;
        return;
    end
    
    % ----- setup the external trigger mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40510 + extLine,    extMode);     % 40510 = SPC_TRIG_EXT0_MODE
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40110 + extLine,    trigTerm);    % 40110 = SPC_TRIG_TERM0
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40120 + extLine,    ACCoupling);  % 40120 = SPC_TRIG_EXT0_ACDC
       

    % ----- set masks if single source is activated -----
    if singleSrc == 1
        switch (extLine)
            case 0
                error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40410, 2);  % 40410 = SPC_TRIG_ORMASK, 2 = SPC_TMASK_EXT0
            case 1
                error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40410, 4);  % 40410 = SPC_TRIG_ORMASK, 4 = SPC_TMASK_EXT1
            case 2
                error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40410, 8);  % 40410 = SPC_TRIG_ORMASK, 8 = SPC_TMASK_EXT2
        end
                
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40430, 0);  % 40430 = SPC_TRIG_ANDMASK 
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40460, 0);  % 40460 = SPC_TRIG_CH_ORMASK0
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40461, 0);  % 40461 = SPC_TRIG_CH_ORMASK1
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40480, 0);  % 40480 = SPC_TRIG_CH_ANDMASK0
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40481, 0);  % 40481 = SPC_TRIG_CH_ANDMASK1
    end
    
    % ----- Ext0 needs trigger levels -----
    if extLine == 0
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 42320,    level0);  % 42320 = SPC_TRIG_EXT0_LEVEL0
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 42330,    level1);   % 42330 = SPC_TRIG_EXT0_LEVEL1
    end
            
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);    

    

