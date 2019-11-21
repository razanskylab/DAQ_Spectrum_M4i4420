%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupClockExternal:
% external clock
%**************************************************************************

function [success, cardInfo] = spcMSetupClockExternal (cardInfo, extRange, clockTerm, divider)

    if (clockTerm ~= 0) & (clockTerm ~= 1)
        sprintf (cardInfo.errorText, 'spcMSetupClockExternal: clockTerm must be 0 (disable) or 1 (enable)');
        success = false;
        return;
    end

    error = 0;

    % ----- setup the clock mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 20200,         8);  % 20200 = SPC_CLOCKMODE, 8 = SPC_CM_EXTERNAL
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 20130,  extRange);  % 20130 = SPC_EXTERNRANGE
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 20040,   divider);  % 20040 = SPC_CLOCKDIV
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 20120, clockTerm);  % 20120 = SPC_CLOCK50OHM
    
    cardInfo.setSamplerate = 1;
    cardInfo.oversampling  = 1;
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);



    



