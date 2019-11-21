%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 11/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupDigitalOutput:
% allows all digital output channel related settings
%**************************************************************************

function [success, cardInfo] = spcMSetupDigitalOutput (cardInfo, group, stopMode, lowLevel, highLevel, diffMode)

    error = 0;

    % check for programmable gain
    if cardInfo.DIO.stopLevelProgrammable == true
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 206020 + group, stopMode);  % 206020 = SPC_CH0_STOPLEVEL 
    end
    
    % check for programmable output level
    if cardInfo.DIO.outputLevelProgrammable == true
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 42100 + group, lowLevel);  % 42100 = SPC_LOWLEVEL0
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 42000 + group, highLevel);  % 42000 = SPC_HIGHLEVEL0
    end
    
    if cardInfo.DIO.diffModeAvailable == true
        % to be done
    end
    
   [success, cardInfo] = spcMCheckSetError (error, cardInfo);    