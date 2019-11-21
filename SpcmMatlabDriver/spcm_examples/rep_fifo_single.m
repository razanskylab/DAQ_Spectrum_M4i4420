%**************************************************************************
%
% rep_fifo_single.m                            (c) Spectrum GmbH , 10/2015
%
%**************************************************************************
%
% Example for all SpcMDrv based (M2i) generator cards. 
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
if ((cardInfo.cardFunction ~= mRegs('SPCM_TYPE_AO')) & (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_DO')) & (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_DIO')))
    spcMErrorMessageStdOut (cardInfo, 'Error: Card function not supported by this example\n', false);
    return;
end

% ***** do card settings *****

% ----- we try to set the samplerate to 1 MHz on internal PLL, no clock output -----
[success, cardInfo] = spcMSetupClockPLL (cardInfo, 1000000, 0);  % clock output : enable = 1, disable = 0
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
fprintf (' ............. Set software trigger\n');

% ----- type dependent card setup -----
switch cardInfo.cardFunction

    % ----- analog generator card setup -----
    case mRegs('SPCM_TYPE_AO')
        % ----- program all output channels to +/- 1 V with no offset and no filter -----
        for i=0 : cardInfo.maxChannels-1  
            [success, cardInfo] = spcMSetupAnalogOutputChannel (cardInfo, i, 1000, 0, 0, mRegs('SPCM_STOPLVL_ZERO'), 0, 0); % doubleOut = disabled, differential = disabled
            if (success == false)
                spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupInputChannel:\n\t', true);
                return;
            end
        end
          
        % ----- FIFO mode setup, we run continuously -----
        
        % ----- only one channel is activated for analog output to keep example simple -----
        [success, cardInfo] = spcMSetupModeRepFIFOSingle (cardInfo, 0, 1, 0, 0);
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRepFIFOSingle:\n\t', true);
            return;
       end
   
   % ----- digital generator card setup -----
   case { mRegs('SPCM_TYPE_DO'), mRegs('SPCM_TYPE_DIO') }
       % ----- set all output channel groups ----- 
       for i=0 : cardInfo.DIO.groups-1                             
           [success, cardInfo] = spcMSetupDigitalOutput (cardInfo, i, mRegs('SPCM_STOPLVL_LOW'), 0, 3300, 0);
       end
       
       % ----- FIFO mode setup, we run continuously -----
       
       % ----- in this example only D0 - D7 (255 = 0xff) are used -----
       [success, cardInfo] = spcMSetupModeRepFIFOSingle (cardInfo, 0, 255, 0, 0);
       if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRepFIFOSingle:\n\t', true);
            return;
       end
end

% ----- set buffer and notify size -----
bufferSize = 8 * 1024 * 1024; %  8 MSample
notifySize = 32 * 1024;       % 32 kSample 

% ***** allocate buffer memory *****
fprintf (' ............. Allocate FIFO buffer\n');
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 0, 1, 0, cardInfo.bytesPerSample * bufferSize, cardInfo.bytesPerSample * notifySize);   
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetupFIFOBuffer:\n\t', true);
    return;
end

% ----- fill half fifo buffer with data -----
fillRate = 0;
while fillRate < bufferSize/2
    
    switch cardInfo.cardFunction

        % ----- analog generator card setup -----
        case mRegs('SPCM_TYPE_AO')
            % ----- get data block of sine waveform -----
            [success, cardInfo, DataBlock] = spcMCalcSignal (cardInfo, notifySize, 1, 1, 100);
            if (success == false)
                spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
                return;
            end
    
            % ----- write data block to buffer -----
            errorCode = spcm_dwSetData (cardInfo.hDrv, 0, notifySize, cardInfo.setChannels, 0, DataBlock);
            if (errorCode ~= 0)
                [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
                spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetData:\n\t', true);
                return;
            end
        
        % ----- digital generator card setup -----
        case { mRegs('SPCM_TYPE_DO'), mRegs('SPCM_TYPE_DIO') }
            [success, DataBlock] = spcMCalcDigitalSignal (notifySize, cardInfo.setChannels);
            
            errorCode = spcm_dwSetRawData (cardInfo.hDrv, 0, notifySize, DataBlock, 1);
            if (errorCode ~= 0)
                [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
                spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetData:\n\t', true);
                return;
            end
    end          
    
    fillRate = fillRate + notifySize;  
end

% ***** after buffer is half filled, we start card and DMA transfer *****

% ----- set command flags -----

% ----- set start card and trigger enable flag -----
commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));

% ----- set start DMA flag -----
commandMask = bitor (commandMask, mRegs('M2CMD_DATA_STARTDMA'));

% ----- set wait for DMA flag -----
commandMask = bitor (commandMask, mRegs('M2CMD_DATA_WAITDMA'));

% ----- write mask to card to start card and DMA transfer ----- 
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), commandMask);
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    return;
end

fprintf (' ..................... Start replay\n');

blocksToGet = 500;

for blockCounter=1 : blocksToGet
    
    switch cardInfo.cardFunction

        % ----- analog generator card setup -----
        case mRegs('SPCM_TYPE_AO')
             % ----- get data block of sine waveform -----
            [success, cardInfo, DataBlock] = spcMCalcSignal (cardInfo, notifySize, 1, 1, 100);
            if (success == false)
                spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
                return;
            end
    
            % ----- write data block to buffer -----
            errorCode = spcm_dwSetData (cardInfo.hDrv, 0, notifySize, cardInfo.setChannels, 0, DataBlock);
            if (errorCode ~= 0)
                [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
                spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetData:\n\t', true);
                return;
            end    
    
        % ----- digital generator card setup (4 = DigitalOut, 5 = DigitalIO) -----
        case { mRegs('SPCM_TYPE_DO'), mRegs('SPCM_TYPE_DIO') }
            [success, DataBlock] = spcMCalcDigitalSignal (notifySize, cardInfo.setChannels);
            
            errorCode = spcm_dwSetRawData (cardInfo.hDrv, 0, notifySize, DataBlock, 1);
            if (errorCode ~= 0)
                [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
                spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetData:\n\t', true);
                return;
            end
    end         
            
    % ----- wait for the next block -----
    errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_DATA_WAITDMA'));
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
        return;
    end    
    
    samplesTransferred = blockCounter * notifySize / 1024 / 1024;
end

% ----- stop card -----
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_CARD_STOP'));

fprintf (' ...................... Replay done\n');
fprintf (' ....... %.2f MSamples transferred\n', samplesTransferred);  

% ***** free allocated buffer memory *****
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 0, 0, 0, cardInfo.bytesPerSample * bufferSize, cardInfo.bytesPerSample * notifySize);   
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
end

% ***** close card *****
spcMCloseCard (cardInfo);
