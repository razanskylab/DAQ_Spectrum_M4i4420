%**************************************************************************
%
% m4i_m2p_rec_std_multi.m                       (c) Spectrum GmbH, 04/2018
%
%**************************************************************************
%
% Example for M4i/M2p acquisition cards with the option
% Multiple Recording and Timestamps installed
%  
% Feel free to use this source for own projects and modify it in any kind
%
%**************************************************************************

% helper maps to use label names for registers and errors
mRegs = spcMCreateRegMap ();
mErrors = spcMCreateErrorMap ();

% ***** init device and store infos in cardInfo struct *****

% ***** use device string to open single card or digitizerNETBOX *****
% digitizerNETBOX
%deviceString = 'TCPIP::XX.XX.XX.XX::inst0'; % XX.XX.XX.XX = IP Address, as an example : 'TCPIP::169.254.119.42::inst0'

% single card
deviceString = '/dev/spcm0';

[success, cardInfo] = spcMInitDevice (deviceString);

if (success == true)
    % ----- print info about the board -----
    cardInfoText = spcMPrintCardInfo (cardInfo);
    fprintf (cardInfoText);
else
    spcMErrorMessageStdOut (cardInfo, 'Error: Could not open card\n', true);
    return;
end

% ----- check whether we support this card type in the example -----
if (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_AI')) & (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_DI'))
    spcMErrorMessageStdOut (cardInfo, 'Error: Card function not supported by this example\n', false);
    return;
end

% ----- check if Multiple Recording is installed -----
if (bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_MULTI')) == 0)
    spcMErrorMessageStdOut (cardInfo, 'Error: Multiple Recording Option not installed. Examples was done especially for this option!\n', false);
    return;
else
    fprintf ('\n Multiple Recording ........ installed.');
end

% ----- check if timestamp is installed -----
if (bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_TIMESTAMP')) == 0)
    spcMErrorMessageStdOut (cardInfo, 'Error: Timestamp Option not installed. Examples was done especially for this option!\n', false);
    return;
else    
    fprintf ('\n Timestamp ................. installed.\n');
end
    
% ***** do card setup *****
memSamples   = 16 * 4096;
segmentSize  = 4096;
posttrigger  = 4096 - 16;

% ----- set channel mask for max channels -----
if cardInfo.maxChannels == 64
    chMaskH = hex2dec ('FFFFFFFF');
    chMaskL = hex2dec ('FFFFFFFF');
else
    chMaskH = 0;
    chMaskL = bitshift (1, cardInfo.maxChannels) - 1;
end

% ----- standard multi, all channels, memSamples, segmentSize, posttrigger -----    
[success, cardInfo] = spcMSetupModeRecStdMulti (cardInfo, chMaskH, chMaskL, memSamples, segmentSize, posttrigger);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecStdMulti:\n\t', true);
    return;
end

% ----- we try to set the samplerate to maximum internal PLL, no clock output -----
[success, cardInfo] = spcMSetupClockPLL (cardInfo, cardInfo.maxSamplerate, 0); % clock output : enable = 1, disable = 0
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupClockPLL:\n\t', true);
    return;
end

fprintf ('\n Sampling rate set to %.1f MHz\n', cardInfo.setSamplerate / 1000000);

% ----- we set trigger to external positive edge, please connect the trigger line! -----

% ----- extMode = SPC_TM_POS, trigTerm = 0, pulseWidth = 0, singleSrc = 1, extLine = 0 -----
[success, cardInfo] = spcMSetupTrigExternal (cardInfo, mRegs('SPC_TM_POS'), 0, 0, 1, 0);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigExternal:\n\t', true);
    return;
end

fprintf ('\n  !!! Using external trigger - please connect a signal to the trigger input !!!\n\n');

% ----- program all input channels to +/-1 V and 50 ohm termination (if it's available) -----
for i=0 : cardInfo.maxChannels-1  
    [success, cardInfo] = spcMSetupAnalogPathInputCh (cardInfo, i, 0, 1000, 1, 0, 0, 0);  
    if (success == false)
        spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupInputChannel:\n\t', true);
        return;
    end
end

% ----- set up timestamp -----
mode = bitor (mRegs('SPC_TSMODE_STARTRESET'), mRegs('SPC_TSCNT_INTERNAL'));
[success, cardInfo] = spcMSetupTimestamp (cardInfo, mode, 0);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTimestamp:\n\t', true);
    return;
end
    
nrOfTimestamps = memSamples / segmentSize;
    
% ----- allocate buffer memory: number of timestamps * 16 (each timestamp is 128 bit = 16 bytes) -----
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 1, 1, 1, nrOfTimestamps * 16, 0); 
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetupFIFOBuffer:\n\t', true);
    return;
end

% ***** start card for acquistion *****

% ----- we'll start and wait until the card has finished or until a timeout occurs -----
timeout_ms = 5000;
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_TIMEOUT'), timeout_ms);
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
end

fprintf (' Card timeout is set to %d ms\n', timeout_ms);
fprintf (' Starting the card and waiting for ready interrupt\n');

% ----- set command flags -----
commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));
commandMask = bitor (commandMask, mRegs('M2CMD_CARD_WAITREADY'));

errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), commandMask);
if ((errorCode ~= 0) & (errorCode ~= 263))
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
end

if errorCode == mErrors('ERR_TIMEOUT')
   spcMErrorMessageStdOut (cardInfo, ' ... Timeout occurred !!!', false);
   return;
else
    % ***** transfer data from card to PC memory *****
    fprintf (' Starting the DMA transfer and waiting until data is in PC memory ...\n');
    
    % ----- set dataType: 0 = RAW (int16), 1 = Amplitude calculated (float) -----
    dataType = 0;
    
    switch cardInfo.setChannels
        
        case 1
            % ----- get the whole data for one channel with offset = 0 ----- 
            [errorCode, Dat_Ch0] = spcm_dwGetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, dataType);
        case 2
            % ----- get the whole data for two channels with offset = 0 ----- 
            [errorCode, Dat_Ch0, Dat_Ch1] = spcm_dwGetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, dataType);
        case 4
            % ----- get the whole data for four channels with offset = 0 ----- 
            [errorCode, Dat_Ch0, Dat_Ch1, Dat_Ch2, Dat_Ch3] = spcm_dwGetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, dataType);
    end
   
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetData:\n\t', true);
        return;
    end
end

fprintf (' ... acquistion ended, data has been transferred to PC memory.\n');

% ----- we wait for the end of the timestamps transfer -----
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_EXTRA_WAITDMA'));
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
end
    
% ----- get the timestamp data -----
[errorCode, Dat_Timestamp] = spcm_dwGetTimestampData (cardInfo.hDrv, 2* nrOfTimestamps);  
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetTimestampData:\n\t', true);
    return;
end
    
fprintf (' ... timestamps have been transferred to PC memory\n');   
    
% ----- calculate the timestamps to milli seconds and print the result -----
    
fprintf ('\n%8s %15s %10s\n', 'Segment', 'Timestamp', 'Timediff');
    
for Idx = 1 : nrOfTimestamps
        
    timestampVal = double(Dat_Timestamp(2 * Idx - 1));
        
    fprintf ('%8d %12.6f us', Idx - 1, 1000000 * (timestampVal / cardInfo.setSamplerate / cardInfo.oversampling));
        
    % ----- print the difference, starting with segment 1 -----
    if Idx > 1
        timestampValLast = double(Dat_Timestamp(2*Idx-3));
        fprintf ('%7.2f us', 1000000 * ((timestampVal - timestampValLast) / cardInfo.setSamplerate / cardInfo.oversampling));
    end
        
    fprintf ('\n');
end
    
% ----- free timestamp buffer memory -----
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 1, 0, 1, 0, 0); 
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetupFIFOBuffer:\n\t', true);
    return;
end
          
% ***** close card *****
spcMCloseCard (cardInfo);

% ***** plot data *****
if cardInfo.cardFunction == 1
    
    % ***** plot analog data *****
    
    % ----- set time array for display -----
    t = 0 : cardInfo.setMemsize - 1; 

    % ----- plot data of the first four channels -----
    switch (cardInfo.setChannels)
    
        case 1
            plot (t, Dat_Ch0);
        
        case 2
            plot (t, Dat_Ch0, 'b', t, Dat_Ch1, 'g');
        
        case 4
            plot (t, Dat_Ch0, 'b', t, Dat_Ch1, 'g', t, Dat_Ch2, 'r', t, Dat_Ch3, 'y');
    end
end

                    
    
