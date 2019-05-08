%**************************************************************************
%
% rep_sequence.m                              (c) Spectrum GmbH, 10/2015
%
%**************************************************************************
%
% Example for all SpcMDrv based (M2i, M4i) generator cards. 
% Shows replay sequence mode 
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
if (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_AO'))
    spcMErrorMessageStdOut (cardInfo, 'Error: Card function not supported by this example\n', false);
    return;
end

% ----- check if Sequence Mode is installed -----
if (bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_SEQUENCE')) == 0)
    spcMErrorMessageStdOut (cardInfo, 'Error: Sequence Mode Option not installed. Example was done especially for this option!\n', false);
    return;
else
    fprintf ('\n Sequence Mode ........ installed.');
end

% ----- set the samplerate and internal PLL, no clock output -----
[success, cardInfo] = spcMSetupClockPLL (cardInfo, 50000000, 0);  % clock output : enable = 1, disable = 0
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupClockPLL:\n\t', true);
    return;
end
fprintf ('\n ..... Sampling rate set to %.1f MHz\n', cardInfo.setSamplerate / 1000000);

% ----- set software trigger, no trigger output -----
[success, cardInfo] = spcMSetupTrigSoftware (cardInfo, 0);  % trigger output : enable = 1, disable = 0
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);
    return;
end

% ----- program all output channels to +/- 1 V with no offset and no filter -----
for i=0 : cardInfo.maxChannels-1  
    [success, cardInfo] = spcMSetupAnalogOutputChannel (cardInfo, i, 1000, 0, 0, mRegs('SPCM_STOPLVL_ZERO'), 0, 0); % doubleOut = disabled, differential = disabled
    if (success == false)
        spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupInputChannel:\n\t', true);
        return;
    end
end

% ----- setup sequence mode, 1 channel, 4 segments, start segment 0 -----
[success, cardInfo] = spcMSetupModeRepSequence (cardInfo, 0, 1, 4, 0);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRepSequence:\n\t', true);
    return;
end

% ----- set segment 0 -----
error = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_SEQMODE_WRITESEGMENT'), 0);
error = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_SEQMODE_SEGMENTSIZE'), 4096);

% create sine waveform
[success, cardInfo, Signal] = spcMCalcSignal (cardInfo, 4096, 1, 1, 100);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
    return;
end

errorCode = spcm_dwSetData (cardInfo.hDrv, 0, 4096, 1, 0, Signal);

% ----- set segment 1 -----
error = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_SEQMODE_WRITESEGMENT'), 1);
error = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_SEQMODE_SEGMENTSIZE'), 4096);

% create rectangel waveform
[success, cardInfo, Signal] = spcMCalcSignal (cardInfo, 4096, 2, 1, 100);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
    return;
end
errorCode = spcm_dwSetData (cardInfo.hDrv, 0, 4096, 1, 0, Signal);

% ----- set segment 2 -----
error = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_SEQMODE_WRITESEGMENT'), 2);
error = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_SEQMODE_SEGMENTSIZE'), 4096);

% create triangel waveform
[success, cardInfo, Signal] = spcMCalcSignal (cardInfo, 4096, 3, 1, 100);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
    return;
end
errorCode = spcm_dwSetData (cardInfo.hDrv, 0, 4096, 1, 0, Signal);

% ----- set segment 3 -----
error = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_SEQMODE_WRITESEGMENT'), 3);
error = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_SEQMODE_SEGMENTSIZE'), 4096);

% create sawtooth waveform
[success, cardInfo, Signal] = spcMCalcSignal (cardInfo, 4096, 4, 1, 100);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
    return;
end
errorCode = spcm_dwSetData (cardInfo.hDrv, 0, 4096, 1, 0, Signal);

%----- set sequence steps -----
%                               step, nextStep, segment, loops, condition (0 => End loop always, 1 => End loop on trigger, 2 => End sequence)
spcMSetupSequenceStep (cardInfo,   0,        1,       0, 20000, 0);
spcMSetupSequenceStep (cardInfo,   1,        2,       1, 50000, 0);
spcMSetupSequenceStep (cardInfo,   2,        3,       0, 20000, 0);
spcMSetupSequenceStep (cardInfo,   3,        4,       2, 50000, 0);
spcMSetupSequenceStep (cardInfo,   4,        5,       0, 20000, 0);
spcMSetupSequenceStep (cardInfo,   5,        0,       3, 50000, 2);

% ----- set command flags -----
commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));
commandMask = bitor (commandMask, mRegs('M2CMD_CARD_WAITREADY'));

errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), commandMask);
if (errorCode ~= 0)
    
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    
    if errorCode == mErrors('ERR_TIMEOUT')
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
