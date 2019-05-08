%**************************************************************************
% Spectrum Matlab Library Package             (c) Spectrum GmbH , 11/2014
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupModeRecFifoAverage16Bit:
% record fifo mode Average
%**************************************************************************

function [success, cardInfo] = spcMSetupModeRecFifoAverage16Bit (cardInfo, chEnableH, chEnableL, segmentSize, posttrigger, averages, loops)
    
    error = 0;

    % ----- setup the mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 9500,                4194304);  % 9500 = SPC_CARDMODE, 4194304 = SPC_REC_FIFO_AVERAGE_16BIT
    error = error + spcm_dwSetParam_i64m (cardInfo.hDrv, 11000, chEnableH, chEnableL);  % 11000 = SPC_CHENABLE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10010,           segmentSize);  % 10010 = SPC_SEGMENTSIZE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10100,           posttrigger);  % 10100 SPC_POSTTRIGGER
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10050,              averages);  % 10050 SPC_AVERAGES
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10020,                 loops);  % 10020 = SPC_LOOPS
    
    % ----- store some information in the structure -----
    cardInfo.setChEnableHMap = chEnableH;
    cardInfo.setChEnableLMap = chEnableL;

    [errorCode, cardInfo.setChannels] = spcm_dwGetParam_i32 (cardInfo.hDrv, 11001);  % 11001 = SPC_CHCOUNT
    error = error + errorCode;
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);
    
