%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupModeRecFIFOGate:
% record FIFO mode gated sampling
%**************************************************************************

function [success, cardInfo] = spcMSetupModeRecFIFOGate (cardInfo, chEnableH, chEnableL, preSamples, postSamples, gatesToRec)

    error = 0;
    
    % ----- setup the mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 9500,                     64); %  9500 = SPC_CARDMODE, 64 = SPC_REC_FIFO_GATE
    error = error + spcm_dwSetParam_i64m (cardInfo.hDrv, 11000, chEnableH, chEnableL); % 11000 = SPC_CHENABLE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10030,            preSamples); % 10030 = SPC_PRETRIGGER
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10100,           postSamples); % 10100 = SPC_POSTTRIGGER
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10020,            gatesToRec); % 10020 = SPC_LOOPS
    
    % ----- store some information in the structure -----
    cardInfo.setMemsize      = 0;
    cardInfo.setChEnableHMap = chEnableH;
    cardInfo.setChEnableLMap = chEnableL;
    
    [errorCode, cardInfo.setChannels] = spcm_dwGetParam_i32 (cardInfo.hDrv, 11001);  % 11001 = SPC_CHCOUNT
    error = error + errorCode;
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);
    
    
    
    
    

    