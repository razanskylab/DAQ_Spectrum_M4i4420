%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupClockPLL:
% internal clock using PLL
%**************************************************************************

function [success, cardInfo] = spcMSetupClockPLL (cardInfo, samplerate, clockOut)

    if (clockOut ~= 0) & (clockOut ~= 1)
        sprintf (cardInfo.errorText, 'spcMSetupClockPLL: clockOut must be 0 (disable) or 1 (enable)');
        success = false;
        return;
    end

    % ----- check for clock borders -----
    if (samplerate < cardInfo.minSamplerate)
        samplerate = cardInfo.minSamplerate;
    end
    if (samplerate > cardInfo.maxSamplerate)
        samplerate = cardInfo.maxSamplerate;
    end

    error = 0;

    % ----- setup the clock mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 20200,          1);  % 20200 = SPC_CLOCKMODE, 1 = SPC_CM_INTPLL
    error = error + spcm_dwSetParam_i64 (cardInfo.hDrv, 20000, samplerate);  % 20000 = SPC_SAMPLERATE
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 20110,   clockOut);  % 20110 = SPC_CLOCKOUT

    [errorCode, cardInfo.setSamplerate] = spcm_dwGetParam_i64 (cardInfo.hDrv,  20000);  % 20000 = SPC_SAMPLERATE
    error = error + errorCode;

    [errorCode, cardInfo.oversampling]  = spcm_dwGetParam_i32 (cardInfo.hDrv, 200123);  % 200123 = SPC_OVERSAMPLINGFACTOR
    error = error + errorCode;

    [success, cardInfo] = spcMCheckSetError (error, cardInfo);
end
