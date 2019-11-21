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

function [success, cardInfo] = spcMSetupModeRecStdSegmStat (cardInfo, chEnableH, chEnableL, memSize, segmentSize, posttrigger, averages)
    
    error = 0;

    % ----- setup the mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv,   9500,                65536);  %  9500 = SPC_CARDMODE, 65536 = SPC_REC_STD_SEGSTATS
    error = error + spcm_dwSetParam_i64m (cardInfo.hDrv, 11000, chEnableH, chEnableL);  % 11000 = SPC_CHENABLE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv,  10000,              memSize);  % 10000 = SPC_MEMSIZE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv,  10010,          segmentSize);  % 10010 = SPC_SEGMENTSIZE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv,  10100,          posttrigger);  % 10100 = SPC_POSTTRIGGER
    
    % ----- store some information in the structure -----
    cardInfo.setMemsize      = memSize;
    cardInfo.setChEnableHMap = chEnableH;
    cardInfo.setChEnableLMap = chEnableL;

    [errorCode, cardInfo.setChannels] = spcm_dwGetParam_i32 (cardInfo.hDrv, 11001);  % 11001 = SPC_CHCOUNT
    error = error + errorCode;
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);
    
