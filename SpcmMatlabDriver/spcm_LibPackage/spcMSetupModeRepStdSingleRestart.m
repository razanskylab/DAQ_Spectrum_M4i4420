%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 11/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupModeRepStdSingleRestart:
% replay single restart mode
%**************************************************************************

function [success, cardInfo] = spcMSetupModeRepStdSingleRestart (cardInfo, chEnableH, chEnableL, memSamples, loops)
    
    error = 0;
    
    % ----- setup the mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 9500,                  32768);  %  9500 = SPC_CARDMODE, 32768 = SPC_REP_STD_SINGLERESTART
    error = error + spcm_dwSetParam_i64m (cardInfo.hDrv, 11000, chEnableH, chEnableL);  % 11000 = SPC_CHENABLE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10000,            memSamples);  % 10000 = SPC_MEMSIZE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10020,                 loops);  % 10020 = SPC_LOOPS
    
    % ----- store some information in the structure -----
    cardInfo.setMemsize      = memSamples;
    cardInfo.setChEnableHMap = chEnableH;
    cardInfo.setChEnableLMap = chEnableL;
    
    [errorCode, cardInfo.setChannels] = spcm_dwGetParam_i32 (cardInfo.hDrv, 11001);  % 11001 = SPC_CHCOUNT
    error = error + errorCode;
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);
 