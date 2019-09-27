%**************************************************************************
%
% m4i_rep_fifo_single.m                        (c) Spectrum GmbH, 10/2015
%
%**************************************************************************
%
% Example for M4i generator cards. 
% Shows standard data replay using fifo mode 
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

% ***** do card settings *****

% ----- we set the samplerate to 50 MHz on internal PLL, no clock output -----
[success, cardInfo] = spcMSetupClockPLL (cardInfo, 50000000, 0);  % clock output : enable = 1, disable = 0
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupClockPLL:\n\t', true);
    return;
end
fprintf ('\n ... Sampling rate set to %.1f MHz\n', cardInfo.setSamplerate / 1000000);

% ----- set software trigger, no trigger output -----
[success, cardInfo] = spcMSetupTrigSoftware (cardInfo, 0);  % trigger output : enable = 1, disable = 0
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);
    return;
end
fprintf (' ... Set software trigger\n');

% ----- program all output channels to +/- 1 V with no offset and no filter -----
for i=0 : cardInfo.maxChannels-1  
    [success, cardInfo] = spcMSetupAnalogOutputChannel (cardInfo, i, 1000, 0, 0, mRegs('SPCM_STOPLVL_ZERO'), 0, 0); % doubleOut = disabled, differential = disabled
    if (success == false)
        spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupInputChannel:\n\t', true);
        return;
    end
end
          
% ----- FIFO mode setup, we run continuously -----
        
% ----- only one channel is activated for analog output -----
[success, cardInfo] = spcMSetupModeRepFIFOSingle (cardInfo, 0, 1, 0, 0);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRepFIFOSingle:\n\t', true);
    return;
end
   
% ----- set buffer and notify size -----
bufferSize = 16 * 1024 * 1024; % 16 MSample
notifySize = 1024 * 1024;      %  1 MSample 

replayTime_sec = 30;

% ***** allocate buffer memory *****
fprintf (' ... Allocate FIFO buffer\n\n');
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 0, 1, 0, cardInfo.bytesPerSample * bufferSize, cardInfo.bytesPerSample * notifySize);   
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetupFIFOBuffer:\n\t', true);
    return;
end

% ----- write setup to card -----
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_CARD_WRITESETUP'));
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
end

% ----- get data block of sine waveform -----
[success, cardInfo, DataBlock] = spcMCalcSignal (cardInfo, notifySize, 1, 1, 100);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
    return;
end

% ----- fill half fifo buffer with data -----
fillSize = 0;
fillSizePercent = 0;
startDMA = true;

while fillSizePercent < 50
    
    % ----- read fillsize of hardware buffer -----
    [errorCode, fillSize] = spcm_dwGetParam_i32 (cardInfo.hDrv, mRegs('SPC_FILLSIZEPROMILLE'));
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
        return;
    end
    
    if ((fillSize / 10) ~= fillSizePercent)
        fillSizePercent = fillSize / 10;
        fprintf ('Hardware buffer filled: %d%%\n', int16(fillSizePercent));
    end
    
    % ----- write data block to buffer -----
    errorCode = spcm_dwSetData (cardInfo.hDrv, 0, notifySize, cardInfo.setChannels, 0, DataBlock);
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetData:\n\t', true);
        return;
    end
            
    if (startDMA == true)
        errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_DATA_STARTDMA'));
        if (errorCode ~= 0)
            [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
            spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
            return;
        end
        startDMA = false;
    end
end

% ----- set timeout -----
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_TIMEOUT'), 5000);
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
end

% ***** after buffer is half filled, we start card *****

% ----- set start card and trigger enable flag -----
commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));

% ----- set wait for DMA flag -----
commandMask = bitor (commandMask, mRegs('M2CMD_DATA_WAITDMA'));

% ----- write mask to card to start card and DMA transfer ----- 
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), commandMask);
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    return;
end

fprintf ('\n ... Start replay (%d sec)\n\n', replayTime_sec);

tic;
endLoop = false;
while endLoop == false
    
    [errorCode, fillSize] = spcm_dwGetParam_i32 (cardInfo.hDrv, mRegs('SPC_FILLSIZEPROMILLE'));
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
        return;
    end
    
    if ((fillSize / 10) ~= fillSizePercent)
        fillSizePercent = fillSize / 10;
        fprintf ('Hardware buffer filled: %d%%\n', int16(fillSizePercent));
    end
    
    % ----- write data block to buffer -----
    errorCode = spcm_dwSetData (cardInfo.hDrv, 0, notifySize, cardInfo.setChannels, 0, DataBlock);
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetData:\n\t', true);
        return;
    end    
    
    % ----- wait for the next block -----
    errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_DATA_WAITDMA'));
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
        return;
    end    
    
    if (toc > replayTime_sec)
        endLoop = true;
    end
end

% ----- stop card -----
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_CARD_STOP'));

fprintf ('\n ... Replay done\n');

% ***** free allocated buffer memory *****
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 0, 0, 0, cardInfo.bytesPerSample * bufferSize, cardInfo.bytesPerSample * notifySize);   
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
end

% ***** close card *****
spcMCloseCard (cardInfo);
