%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupTrigSoftware:
% software trigger
%**************************************************************************

function [success, cardInfo] = spcMSetupTrigSoftware (cardInfo, trigOut)

    if (trigOut ~= 0) & (trigOut ~= 1)
        sprintf (cardInfo.errorText, 'spcMSetupTrigSoftware: trigOut must be 0 (disable) or 1 (enable)');
        success = false;
        return;
    end

    error = 0;

    % ----- setup the trigger mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40410,       1);  % 40410 = SPC_TRIG_ORMASK, 1 = SPC_TMASK_SOFTWARE
      % Enables the software trigger for the OR mask.
      % The card will trigger immediately after start.
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40430,       0);  % 40430 = SPC_TRIG_ANDMASK
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40460,       0);  % 40460 = SPC_TRIG_CH_ORMASK0
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40461,       0);  % 40461 = SPC_TRIG_CH_ORMASK1
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40480,       0);  % 40480 = SPC_TRIG_CH_ANDMASK0
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40481,       0);  % 40481 = SPC_TRIG_CH_ANDMASK1
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40100, trigOut);  % 40100 = SPC_TRIGGEROUT

    [success, cardInfo] = spcMCheckSetError (error, cardInfo);
