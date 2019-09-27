%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupModeRepSequence:
% replay sequence mode
%**************************************************************************

function [success, cardInfo] = spcMSetupModeRepSequence (cardInfo, chEnableH, chEnableL, numSegments, startSegment)
    
    error = 0;
    
    % ----- setup the mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 9500, 262144); % 9500 = SPC_CARDMODE, SPC_REP_STD_SEQUENCE
    error = error + spcm_dwSetParam_i64m (cardInfo.hDrv, 11000, chEnableH, chEnableL);  % 11000 = SPC_CHENABLE
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 349910, numSegments); % 349910 = SPC_SEQMODE_MAXSEGMENTS
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 349930, startSegment); % 349930 = SPC_SEQMODE_STARTSTEP
    
    cardInfo.setChEnableHMap = chEnableH;
    cardInfo.setChEnableLMap = chEnableL;
    
    [errorCode, cardInfo.setChannels] = spcm_dwGetParam_i32 (cardInfo.hDrv, 11001);  % 11001 = SPC_CHCOUNT
    error = error + errorCode;
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);
    