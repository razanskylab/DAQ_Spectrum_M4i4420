%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMCloseCard:
% closes the driver
%**************************************************************************

function spcMCloseCard (cardInfo)
    
    if (cardInfo.hDrv ~= 0)
        spcm_vClose (cardInfo.hDrv);
    end








