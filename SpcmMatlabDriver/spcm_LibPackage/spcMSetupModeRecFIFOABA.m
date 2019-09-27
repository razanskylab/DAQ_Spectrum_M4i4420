%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupModeRecFIFOABA:
% record FIFO mode ABA
%**************************************************************************

function [success, cardInfo] = spcMSetupModeRecFIFOABA (cardInfo, chEnableH, chEnableL, segmentSize, postSamples, ABADivider, segmentsToRec)

    error = 0;
    
    % ----- setup the mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv,  9500,           128);         %  9500 = SPC_CARDMODE, 128 = SPC_REC_FIFO_ABA
    error = error + spcm_dwSetParam_i64m (cardInfo.hDrv, 11000, chEnableH, chEnableL); % 11000 = SPC_CHENABLE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10010,   segmentSize);         % 10010 = SPC_SEGMENTSIZE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10100,   postSamples);         % 10100 = SPC_POSTTRIGGER
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10020, segmentsToRec);         % 10020 = SPC_LOOPS
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10040,    ABADivider);         % 10040 = SPC_ABADIVIDER

    % ----- store some information in the structure -----
    cardInfo.setMemsize      = 0;
    cardInfo.setChEnableHMap = chEnableH;
    cardInfo.setChEnableLMap = chEnableL;

    [errorCode, cardInfo.setChannels] = spcm_dwGetParam_i32 (cardInfo.hDrv, 11001);  % 11001 = SPC_CHCOUNT
    error = error + errorCode;
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);

    
    
    
    

    
 

    


    

    
    
    
    



    
    



   












