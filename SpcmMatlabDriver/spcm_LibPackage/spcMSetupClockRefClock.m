%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupClockRefClock:
% reference clock
%**************************************************************************

function [success, cardInfo] = spcMSetupClockRefClock (cardInfo, refClock, samplerate, clockTerm)

    if (clockTerm ~= 0) & (clockTerm ~= 1)
        sprintf (cardInfo.errorText, 'spcMSetupClockExternal: clockTerm must be 0 (disable) or 1 (enable)');
        success = false;
        return;
    end

    error = 0;

    % ----- setup the clock mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 20200,         32);  % 20200 = SPC_CLOCKMODE, 32 = SPC_CM_EXTREFCLOCK
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 20140,   refClock);  % 20140 = SPC_REFERENCECLOCK
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 20000, samplerate);  % 20000 = SPC_SAMPLERATE
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 20120,  clockTerm);  % 20120 = SPC_CLOCK50OHM
    
    [errorCode, cardInfo.setSamplerate] = spcm_dwGetParam_i32 (cardInfo.hDrv,  20000);  % 20000 = SPC_SAMPLERATE
    error = error + errorCode;
        
    [errorCode, cardInfo.oversampling]  = spcm_dwGetParam_i32 (cardInfo.hDrv, 200123);  % 200123 = SPC_OVERSAMPLINGFACTOR
    error = error + errorCode;
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);







   




