%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupClockQuartz:
% internal clock using high precision quartz
%**************************************************************************

function [success, cardInfo] = spcMSetupClockQuartz (cardInfo, samplerate, clockOut)

    error = 0;
    
    % ----- setup the clock mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 20200,          2);  % 20200 = SPC_CLOCKMODE, 2 = SPC_CM_QUARTZ1
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 20000, samplerate);  % 20000 = SPC_SAMPLERATE
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 20110,   clockOut);  % 20110 = SPC_CLOCKOUT
    
    [errorCode, cardInfo.setSamplerate] = spcm_dwGetParam_i32 (cardInfo.hDrv,  20000);  % 20000 = SPC_SAMPLERATE
    error = error + errorCode;
        
    [errorCode, cardInfo.oversampling]  = spcm_dwGetParam_i32 (cardInfo.hDrv, 200123);  % 200123 = SPC_OVERSAMPLINGFACTOR
    error = error + errorCode;
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);


