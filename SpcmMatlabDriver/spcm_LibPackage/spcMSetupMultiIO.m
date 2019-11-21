%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupMultiIO:
% defines the M3i, M4i multi purpose i/o usage
%**************************************************************************

function [success, cardInfo] = spcMSetupMultiIO (cardInfo, modeX0, modeX1, modeX2)
    error = 0;

    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 47200, modeX0);  % 47200 = SPCM_X0_MODE
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 47201, modeX1);  % 47201 = SPCM_X1_MODE
    
    if nargin > 3
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 47202, modeX2);  % 47202 = SPCM_X2_MODE
    end
        
    [success, cardInfo] = spcMCheckSetError (error, cardInfo);



    



