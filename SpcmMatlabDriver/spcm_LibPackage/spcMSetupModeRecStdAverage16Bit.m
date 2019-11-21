%**************************************************************************
% Spectrum Matlab Library Package             (c) Spectrum GmbH , 11/2014
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupModeRecStdAverage:
% record standard mode Average
%**************************************************************************

function [success, cardInfo] = spcMSetupModeRecStdAverage16Bit (cardInfo, chEnableH, chEnableL, memSize, segmentSize, posttrigger, averages)
    
    error = 0;

    % ----- setup the mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 9500,                 524288);  % 9500 = SPC_CARDMODE, 524288 = SPC_REC_STD_AVERAGE_16BIT
    error = error + spcm_dwSetParam_i64m (cardInfo.hDrv, 11000, chEnableH, chEnableL);  % 11000 = SPC_CHENABLE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10000,               memSize);  % 10000 = SPC_MEMSIZE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10010,           segmentSize);  % 10010 = SPC_SEGMENTSIZE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10100,           posttrigger);  % 10100 SPC_POSTTRIGGER
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10050,              averages);  % 10050 SPC_AVERAGES
    
    % ----- store some information in the structure -----
    cardInfo.setMemsize      = memSize;
    cardInfo.setChEnableHMap = chEnableH;
    cardInfo.setChEnableLMap = chEnableL;

    [errorCode, cardInfo.setChannels] = spcm_dwGetParam_i32 (cardInfo.hDrv, 11001);  % 11001 = SPC_CHCOUNT
    error = error + errorCode;
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);
    
