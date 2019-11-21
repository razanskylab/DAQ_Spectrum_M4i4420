%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupTimestamp:
% set up the timestamp mode and performs a synchronisation with refernce 
% clock if that mode is activated. Checks for BASEXIO option if one wants 
% to use reference clock mode
%**************************************************************************

function [success, cardInfo] = spcMSetupTimestamp (cardInfo, mode, refTimeoutMS)

    error = 0;

    refClockMask = bitor (512, 1024);  % 512 = SPC_TSCNT_REFCLOCKPOS, 1024 = SPC_TSCNT_REFCLOCKNEG
    
    if (bitand (mode, refClockMask) ~= 0)
        refClockMode = true;
    else
        refClockMode = false;
    end
    
    % ----- if ref clock is activated we check for the installation of base xio as this contains the ref clock input -----
    if (refClockMode == true) & (bitand (cardInfo.featureMap, 256) == 0)  % 256 = SPCM_FEAT_BASEXIO 
        sprintf (cardInfo.errorText, 'Timestamp ref clock mode requires an installed BASEXIO feature!\n');
        success = false;
        return;
    end
    
    % ----- set the timestamp mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 47000, mode);  % 47000 = SPC_TIMESTAMP_CMD
    
    % ----- in ref clock mode we now try the synchronisation with external clock -----
    if (refClockMode == true) & (error == 0)      
        
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 47045, refTimeoutMS);  % 47045 = SPC_TIMESTAMP_TIMEOUT
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 47000,            1);  % 47000 = SPC_TIMESTAMP_CMD, 1 = SPC_TS_RESET
        
        % ----- error = synchronisation failed -----
        if error ~= 0
            sprintf (cardInfo.errorText, 'Timestamp reset: synchronisation with external ref clock failed. Check cabeling and check timeout value\n');    
            success = false;
            return;
        end
    end
    
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);
        
        
    







     











