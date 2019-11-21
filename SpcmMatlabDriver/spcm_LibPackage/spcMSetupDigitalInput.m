%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupDigitalInput:
% allows all input channel related settings
%**************************************************************************

function [success, cardInfo] = spcMSetupDigitalInput (cardInfo, group, term)
    
    if (term ~= 0) & (term ~= 1)
        sprintf (cardInfo.errorText, 'spcMSetupInputChannel: term must be 0 (disable) or 1 (enable)');
        success = false;
        return;
    end
    
    error = 0;
    
    if cardInfo.DIO.inputTermAvailable == true
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 30060 + group * 100, term);  % 30060 = SPC_110OHM0 
    end
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo); 
    