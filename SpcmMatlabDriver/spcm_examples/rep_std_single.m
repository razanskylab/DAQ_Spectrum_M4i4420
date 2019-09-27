%**************************************************************************
%
% rep_std_single.m                              (c) Spectrum GmbH, 04/2015
%
%**************************************************************************
%
% Example for all SpcMDrv based (M2i, M4i) generator cards. 
% Shows standard data replay using single mode 
%  
% Feel free to use this source for own projects and modify it in any kind
%
%**************************************************************************

% helper maps to use label names for registers and errors
mRegs = spcMCreateRegMap ();
mErrors = spcMCreateErrorMap ();

% ***** init card and store infos in cardInfo struct *****
[success, cardInfo] = spcMInitCardByIdx (0);

if (success == true)
    % ----- print info about the board -----
    cardInfoText = spcMPrintCardInfo (cardInfo);
    fprintf (cardInfoText);
else
    spcMErrorMessageStdOut (cardInfo, 'Error: Could not open card\n', true);
    return;
end

% ----- check whether we support this card type in the example -----
if ((cardInfo.cardFunction ~= mRegs('SPCM_TYPE_AO')) & (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_DO')) & (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_DIO')))
    spcMErrorMessageStdOut (cardInfo, 'Error: Card function not supported by this example\n', false);
    return;
end

% ----- replay mode selected by user -----
fprintf ('\nPlease select the output mode:\n');
fprintf ('  (1) Singleshot\n  (2) Continuous\n  (3) Single Restart\n  (0) Quit\n');

replayMode = input ('Select: ');

if (replayMode < 1) | (replayMode > 3) 
    spcMCloseCard (cardInfo);
    return;
end

% ***** do card settings *****
timeout_ms = 10000;

samplerate = 1000000;
if cardInfo.isM4i == true
    samplerate = 50000000;
end

% ----- set the samplerate and internal PLL, no clock output -----
[success, cardInfo] = spcMSetupClockPLL (cardInfo, samplerate, 0);  % clock output : enable = 1, disable = 0
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupClockPLL:\n\t', true);
    return;
end
fprintf ('\n ..... Sampling rate set to %.1f MHz\n', cardInfo.setSamplerate / 1000000);

% ----- set channel mask for max channels -----
if cardInfo.maxChannels == 64
    chMaskH = hex2dec ('FFFFFFFF');
    chMaskL = hex2dec ('FFFFFFFF');
else
    chMaskH = 0;
    chMaskL = bitshift (1, cardInfo.maxChannels) - 1;
end

switch replayMode
    
    case 1
        % ----- singleshot replay -----
        [success, cardInfo] = spcMSetupModeRepStdSingle (cardInfo, chMaskH, chMaskL, 64 * 1024);
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecStdSingle:\n\t', true);
            return;
        end
        fprintf (' .............. Set singleshot mode\n');
        
        % ----- set software trigger, no trigger output -----
        [success, cardInfo] = spcMSetupTrigSoftware (cardInfo, 0);  % trigger output : enable = 1, disable = 0
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);
            return;
        end
        fprintf (' ............. Set software trigger\n');
        
    case 2
        % ----- endless continuous mode -----
        [success, cardInfo] = spcMSetupModeRepStdLoops (cardInfo, chMaskH, chMaskL, 64 * 1024, 0);
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecStdSingle:\n\t', true);
            return;
        end
        fprintf (' .............. Set continuous mode\n');
        
        % ----- set software trigger, no trigger output -----
        [success, cardInfo] = spcMSetupTrigSoftware (cardInfo, 0);  % trigger output : enable = 1, disable = 0
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);

            return;
        end
        fprintf (' ............. Set software trigger\n Wait for timeout (%d sec) .....', timeout_ms / 1000);

    case 3
        % ----- single restart (one signal on every trigger edge) -----
        [success, cardInfo] = spcMSetupModeRepStdSingleRestart (cardInfo, chMaskH, chMaskL, 64 * 1024, 0);
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);
            return;
        end
        fprintf (' .......... Set single restart mode\n');
        
        % ----- set extern trigger, positive edge -----
        [success, cardInfo] = spcMSetupTrigExternal (cardInfo, mRegs('SPC_TM_POS'), 1, 0, 1, 0);
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);
            return;
        end
        fprintf (' ............... Set extern trigger\n Wait for timeout (%d sec) .....', timeout_ms / 1000);
end

% ----- type dependent card setup -----
switch cardInfo.cardFunction

    % ----- analog generator card setup -----
    case mRegs('SPCM_TYPE_AO')
        % ----- program all output channels to +/- 1 V with no offset and no filter -----
        for i=0 : cardInfo.maxChannels-1  
            [success, cardInfo] = spcMSetupAnalogOutputChannel (cardInfo, i, 1000, 0, 0, 16, 0, 0); % 16 = SPCM_STOPLVL_ZERO, doubleOut = disabled, differential = disabled
            if (success == false)
                spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupInputChannel:\n\t', true);
                return;
            end
        end
   
   % ----- digital acquisition card setup -----
   case { mRegs('SPCM_TYPE_DO'), mRegs('SPCM_TYPE_DIO') }
       % ----- set all output channel groups ----- 
       for i=0 : cardInfo.DIO.groups-1                             
           [success, cardInfo] = spcMSetupDigitalOutput (cardInfo, i, mRegs('SPCM_STOPLVL_LOW'), 0, 3300, 0);
       end
end

if cardInfo.cardFunction == mRegs('SPCM_TYPE_AO')

    % ----- analog data -----

    % ***** calculate waveforms *****

    if cardInfo.setChannels >= 1
        % ----- ch0 = sine waveform -----
        [success, cardInfo, Dat_Ch0] = spcMCalcSignal (cardInfo, cardInfo.setMemsize, 1, 1, 100);
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
            return;
        end
    end

    if cardInfo.setChannels >= 2
        % ----- ch1 = rectangle waveform -----
        [success, cardInfo, Dat_Ch1] = spcMCalcSignal (cardInfo, cardInfo.setMemsize, 2, 1, 100);
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
            return;
        end
    end

    if cardInfo.setChannels == 4
        % ----- ch2 = triangle waveform -----
        [success, cardInfo, Dat_Ch2] = spcMCalcSignal (cardInfo, cardInfo.setMemsize, 3, 1, 100);
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
            return;
        end
    
        % ----- ch3 = sawtooth waveform -----
        [success, cardInfo, Dat_Ch3] = spcMCalcSignal (cardInfo, cardInfo.setMemsize, 4, 1, 100);
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
            return;
        end
    end

    switch cardInfo.setChannels
        
        case 1
            % ----- get the whole data for one channel with offset = 0 ----- 
            errorCode = spcm_dwSetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, 0, Dat_Ch0);
        case 2
            % ----- get the whole data for two channels with offset = 0 ----- 
            errorCode = spcm_dwSetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, 0, Dat_Ch0, Dat_Ch1);
        case 4
            % ----- set data for four channels with offset = 0 ----- 
            errorCode = spcm_dwSetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, 0, Dat_Ch0, Dat_Ch1, Dat_Ch2, Dat_Ch3);
    end
    
else
 
    % ----- digital data -----
    [success, Data] = spcMCalcDigitalSignal (cardInfo.setMemsize, cardInfo.setChannels);
    
    errorCode = spcm_dwSetRawData (cardInfo.hDrv, 0, length (Data), Data, 1);
end

if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetData:\n\t', true);
    return;
end

% ----- we'll start and wait until the card has finished or until a timeout occurs -----
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_TIMEOUT'), timeout_ms);
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
end

% ----- set command flags -----
commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));
commandMask = bitor (commandMask, mRegs('M2CMD_CARD_WAITREADY'));

errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), commandMask);
if (errorCode ~= 0)
    
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    
    if errorCode == 263  % 263 = ERR_TIMEOUT 
        errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_CARD_STOP'));
        fprintf (' OK\n ................... replay stopped\n');

    else
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
        return;
    end
end

fprintf (' ...................... replay done\n');

% ***** close card *****
spcMCloseCard (cardInfo);
  