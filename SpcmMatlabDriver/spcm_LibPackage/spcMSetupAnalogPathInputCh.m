%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupAnalogPathInputCh:
% allows all analog input channel related settings (M3i version)
%**************************************************************************

function [success, cardInfo] = spcMSetupAnalogPathInputCh (cardInfo, channel, path, inputRange, term, ACCoupling, BWLimit, diffInput)

    if (channel < 0) | (channel >= cardInfo.maxChannels)
        sprintf (cardInfo.errorText, 'spcMSetupAnalogPathInputCh: channel number %d not valid. Channels range from 0 to %d\n', channel, cardInfo.maxChannels);
        success = false;
        return;
    end

    if (term ~= 0) & (term ~= 1)
        sprintf (cardInfo.errorText, 'spcMSetupAnalogPathInputCh: term must be 0 (disable) or 1 (enable)');
        success = false;
        return;
    end

    if (ACCoupling ~= 0) & (ACCoupling ~= 1)
        sprintf (cardInfo.errorText, 'spcMSetupAnalogPathInputCh: ACCoupling must be 0 (DC) or 1 (AC)');
        success = false;
        return;
    end

    if (BWLimit ~= 0) & (BWLimit ~= 1)
        sprintf (cardInfo.errorText, 'spcMSetupAnalogPathInputCh: BWLimit must be 0 (full bandwidth) or 1 (BW filter active)');
        success = false;
        return;
    end

    if (diffInput ~= 0) & (diffInput ~= 1)
        sprintf (cardInfo.errorText, 'spcMSetupAnalogPathInputCh: diffInput must be 0 (disable) or 1 (enable)');
        success = false;
        return;
    end

    error = 0;

    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 30090 + channel * 100,      path);         % 30090 = SPC_PATH0
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 30010 + channel * 100,      inputRange);   % 30010 = SPC_AMP0

    if ((cardInfo.AI.inputTermAvailable == true) && (path == 0))
         error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 30030 + channel * 100, term);         % 30030 = SPC_50OHM0
    end

    if cardInfo.AI.ACCouplingAvailable == true
         error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 30020 + channel * 100, ACCoupling);   % 30020 = SPC_ACDC0
    end

    if cardInfo.AI.BWLimitAvailable == true
         error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 30080 + channel * 100, BWLimit);      % 30080 = SPC_FILTER0
    end

    if cardInfo.AI.diffModeAvailable == true
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 30040 + channel * 100,  diffInput);    % 30040 = SPC_DIFF0
    end

    % ----- store some information in the structure -----
    cardInfo.AI.setRange(channel+1)  = inputRange;
    cardInfo.AI.setOffset(channel+1) = 0;

    [success, cardInfo] = spcMCheckSetError (error, cardInfo);
end
