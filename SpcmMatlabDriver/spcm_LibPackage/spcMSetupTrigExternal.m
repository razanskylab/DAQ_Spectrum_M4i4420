%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMSetupTrigExternal:
% external trigger
%**************************************************************************

function [errCode, cardInfo] = spcMSetupTrigExternal (cardInfo, extMode, trigTerm, pulsewidth, singleSrc, extLine)

    error = 0;

    % ----- setup the external trigger mode -----
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40510 + extLine,    extMode);     % 40510 = SPC_TRIG_EXT0_MODE
    error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40110 + extLine,    trigTerm);    % 40110 = SPC_TRIG_TERM

    % ----- we only use trigout on M2i cards as we otherwise would override the multi purpose i/o lines of M3i
    if or ((bitand (cardInfo.cardType, 16711680) == 196608), (bitand (cardInfo.cardType, 16711680) == 262144))
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 44210 + extLine,    pulsewidth);  % 44210 = SPC_TRIG_EXT0_PULSEWIDTH
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40100,          0);  % 40100 = SPC_TRIG_OUTPUT
    end


    % ----- set masks if single source is activated -----
    if singleSrc == 1
        switch (extLine)
            case 0
                error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40410, 2);  % 40410 = SPC_TRIG_ORMASK, 2 = SPC_TMASK_EXT0
            case 1
                error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40410, 4);  % 40410 = SPC_TRIG_ORMASK, 4 = SPC_TMASK_EXT1
            case 2
                error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40410, 8);  % 40410 = SPC_TRIG_ORMASK, 8 = SPC_TMASK_EXT2
        end

        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40430, 0);  % 40430 = SPC_TRIG_ANDMASK
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40460, 0);  % 40460 = SPC_TRIG_CH_ORMASK0
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40461, 0);  % 40461 = SPC_TRIG_CH_ORMASK1
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40480, 0);  % 40480 = SPC_TRIG_CH_ANDMASK0
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 40481, 0);  % 40481 = SPC_TRIG_CH_ANDMASK1
    end

    % ----- M3i cards need trigger level to be programmed for Ext0 = analog trigger
    if or ((bitand (cardInfo.cardType, 16711680) == 327680), (bitand (cardInfo.cardType, 16711680) == 393216))
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 42320,    1500);  % 42320 = SPC_TRIG_EXT0_LEVEL0
        error = error + spcm_dwSetParam_i32 (cardInfo.hDrv, 42330,    800);   % 42330 = SPC_TRIG_EXT0_LEVEL1
    end

    [errCode, ~, ~, cardInfo.errorText] = spcm_dwGetErrorInfo_i32(cardInfo.hDrv);
    if errCode
      spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetData:\n\t', true);
      error(cardInfo.errorText);
    end

end
