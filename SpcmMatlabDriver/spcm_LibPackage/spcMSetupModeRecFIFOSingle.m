%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupModeRecFIFOSingle:
% record FIFO mode single run
%**************************************************************************

function [success, cardInfo] = spcMSetupModeRecFIFOSingle (cardInfo, chEnableH, chEnableL, preSamples, blockToRec, loopToRec)

    error = 0;

    % ----- check for invalid block/loop combinations -----
    if (blockToRec > 0 & loopToRec == 0) | (blockToRec == 0 & loopToRec > 0)
        sprintf (cardInfo.errorText, 'spcMSetupModeRecFIFOSingle: Loop and Blocks must be either both zero or both defined to non-zero\n');
        success = false;
        return;
    end
    
    % ----- segment size can't be zero, we adjust it here -----
    if blockToRec == 0 & loopToRec == 0
        blockToRec = 1024;
    end
    
    % ----- setup the mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 9500,                     16); % 9500 = SPC_CARDMODE, 16 = SPC_REC_FIFO_SINGLE
    error = error + spcm_dwSetParam_i64m (cardInfo.hDrv, 11000, chEnableH, chEnableL); % 11000 = SPC_CHENABLE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10030,            preSamples); % 10030 = SPC_PRETRIGGER
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10010,            blockToRec); % 10010 = SPC_SEGMENTSIZE
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 10020,             loopToRec); % 10020 = SPC_LOOPS
    
    % ----- store some information in the structure -----
    cardInfo.setMemsize      = 0;
    cardInfo.setChEnableHMap = chEnableH;
    cardInfo.setChEnableLMap = chEnableL;
    
    [errorCode, cardInfo.setChannels] = spcm_dwGetParam_i32 (cardInfo.hDrv, 11001);  % 11001 = SPC_CHCOUNT
    error = error + errorCode;
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);
    
    

    
    
    
    
    



    
    
    



















  
    
