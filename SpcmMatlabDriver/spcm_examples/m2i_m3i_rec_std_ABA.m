%**************************************************************************
%
% rec_std_ABA.m                              (c) Spectrum GmbH , 10/2015
%
%**************************************************************************
%
% Example for all SpcMDrv based (M2i) acquisition cards with the option
% ABA installed
%
% Shows standard data acquistion using ABA mode. 
% If timestamp is installed the corresponding timestamp values are also read
% out and displayed.
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
if (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_AI'))
    spcMErrorMessageStdOut (cardInfo, 'Error: Card function not supported by this example\n', false);
    return;
end

% ----- check if ABA is installed -----
if (bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_ABA')) == 0)
    spcMErrorMessageStdOut (cardInfo, 'Error: ABA Option not installed. Example was done especially for this option!\n', false);
    return;
else
    fprintf ('\n ABA ................... installed.');
end

% ----- check if timestamp is installed -----
if (bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_TIMESTAMP')) ~= 0)
    timestampInstalled = true;
    fprintf ('\n Timestamp ............. installed.\n');
else
    timestampInstalled = false;
    fprintf ('\n Timestamp ............. not installed.\n');
end

% ***** do card setup *****

memSamples   = 32 * 1024; % 32k
segmentSize  =  4 * 1024; %  4k  
posttrigger  = segmentSize - 16;

% ----- we try to set the samplerate to 1 MHz on internal PLL, no clock output -----
[success, cardInfo] = spcMSetupClockPLL (cardInfo, 1000000, 0);  % clock output : enable = 1, disable = 0
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupClockPLL:\n\t', true);
    return;
end

fprintf ('\n Sampling rate set to %.1f MHz\n', cardInfo.setSamplerate / 1000000);

% ----- set divider of the ABA samplerate -----
divABA = 16; 

% ----- standard ABA, all channels, memSamples, segmentSize, posttrigger -----    
[success, cardInfo] = spcMSetupModeRecStdABA (cardInfo, 0, bitshift (1, cardInfo.maxChannels) - 1, memSamples, segmentSize, posttrigger, divABA); 
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecStdABA:\n\t', true);
    return;
end

% ----- extMode = SPC_TM_POS, trigTerm = 0, pulseWidth = 0, singleSrc = 1, extLine = 0 -----
[success, cardInfo] = spcMSetupTrigExternal (cardInfo, mRegs('SPC_TM_POS'), 0, 0, 1, 0);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigExternal:\n\t', true);
    return;
end

% ----- program all input channels to +/-1 V and 50 ohm termination (if it's available) -----
for i=0 : cardInfo.maxChannels-1  
    [success, cardInfo] = spcMSetupAnalogInputChannel (cardInfo, i, 1000, 1, 0, 0);  
    %setup for M3i card series including new features:
    %[success, cardInfo] = spcMSetupAnalogPathInputCh (cardInfo, i, 0, 1000, 1, 0, 0, 0);  
    if (success == false)
        spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupInputChannel:\n\t', true);
        return;
    end
end

% ***** set up timestamp if timestamp is installed *****
if timestampInstalled == true
    
    % ----- set up timestamp mode to standard -----
    mode = bitor (mRegs('SPC_TSMODE_STANDARD'), mRegs('SPC_TSCNT_INTERNAL'));
    [success, cardInfo] = spcMSetupTimestamp (cardInfo, mode, 0);
    if (success == false)
        spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTimestamp:\n\t', true);
        return;
    end
    
    nrOfTimestamps = memSamples / segmentSize;
    
    % ----- allocate buffer memory: number of timestamps * 8 (each timestamp is 64 bit = 8 bytes) -----
    errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 1, 1, 1, nrOfTimestamps * 8, 0); 
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetupFIFOBuffer:\n\t', true);
        return;
    end
end

% ----- allocate buffer memory for ABA -----
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 2, 1, 1, (memSamples / divABA) * cardInfo.setChannels * cardInfo.bytesPerSample, 0); 
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

fprintf ('\n Card timeout is set to %d ms\n', timeout_ms);
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
    % ----- we wait for the end of the ABA transfer -----
    [errorCode] = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_EXTRA_WAITDMA'));
    
    % ***** transfer data from card to PC memory *****
    fprintf (' Starting the DMA transfer and waiting until data and ABA is in PC memory ...\n');
    
    % ----- set dataType: 0 = RAW (int16), 1 = Amplitude calculated (float) -----
    dataType = 0;
    
    switch cardInfo.setChannels
        
        case 1
            % ----- get the whole data for one channel with offset = 0 ----- 
            [errorCode, Dat_Ch0] = spcm_dwGetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, dataType);
            
            % ----- get the ABA data for one channel -----
            [errorCode, ABA_Ch0] = spcm_dwGetABAData (cardInfo.hDrv, memSamples / divABA, cardInfo.setChannels, dataType);
            
        case 2
            % ----- get the whole data for two channels with offset = 0 ----- 
            [errorCode, Dat_Ch0, Dat_Ch1] = spcm_dwGetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, dataType);
            
            % ----- get the ABA data for two channels -----
            [errorCode, ABA_Ch0, ABA_Ch1] = spcm_dwGetABAData (cardInfo.hDrv, memSamples / divABA, cardInfo.setChannels, dataType);
            
        case 4
            % ----- get the whole data for four channels with offset = 0 ----- 
            [errorCode, Dat_Ch0, Dat_Ch1, Dat_Ch2, Dat_Ch3] = spcm_dwGetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, dataType);
            
            % ----- get the ABA data for four channels -----
            [errorCode, ABA_Ch0, ABA_Ch1, ABA_Ch2, ABA_Ch3] = spcm_dwGetABAData (cardInfo.hDrv, memSamples / divABA, cardInfo.setChannels, dataType);
            
        case 8
            % ----- get the whole data for eight channels with offset = 0 ----- 
            [errorCode, Dat_Ch0, Dat_Ch1, Dat_Ch2, Dat_Ch3, Dat_Ch4, Dat_Ch5, Dat_Ch6, Dat_Ch7] = spcm_dwGetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, dataType);
            
            % ----- get the ABA data for eight channels -----
            [errorCode, ABA_Ch0, ABA_Ch1, ABA_Ch2, ABA_Ch3, ABA_Ch4, ABA_Ch5, ABA_Ch6, ABA_Ch7] = spcm_dwGetABAData (cardInfo.hDrv, memSamples / divABA, cardInfo.setChannels, dataType);
        case 16
            % ----- get the whole data for sixteen channels with offset = 0 ----- 
            [errorCode, Dat_Ch0, Dat_Ch1, Dat_Ch2, Dat_Ch3, Dat_Ch4, Dat_Ch5, Dat_Ch6, Dat_Ch7, Dat_Ch8, Dat_Ch9, Dat_Ch10, Dat_Ch11, Dat_Ch12, Dat_Ch13, Dat_Ch14, Dat_Ch15] = spcm_dwGetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, dataType);
            
            % ----- get the ABA data for eight channels -----
            [errorCode, ABA_Ch0, ABA_Ch1, ABA_Ch2, ABA_Ch3, ABA_Ch4, ABA_Ch5, ABA_Ch6, ABA_Ch7, ABA_8, ABA_9, ABA_10, ABA_11, ABA_12, ABA_13, ABA_14, ABA_15] = spcm_dwGetABAData (cardInfo.hDrv, memSamples / divABA, cardInfo.setChannels, dataType);
    end
    
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetData:\n\t', true);
        return;
    end
end

fprintf (' ... acquistion ended, data has been transferred to PC memory.\n');
fprintf (' ... ABA data has been transferred to PC memory\n');

% ----- free ABA buffer memory -----
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 2, 0, 1, 0, 0); 
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetupFIFOBuffer:\n\t', true);
    return;
end

% ***** only if timestamp is installed *****
if timestampInstalled == true
    
    % ----- get the timestamp data -----
    [errorCode, Dat_Timestamp] = spcm_dwGetTimestampData (cardInfo.hDrv, nrOfTimestamps);  
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetTimestampData:\n\t', true);
        return;
    end
    
    fprintf (' ... timestamps have been transferred to PC memory\n');   
    
    % ----- calculate the timestamps to milli seconds and print the result -----
    
    fprintf ('\n%8s %15s %10s\n', 'Segment', 'Timestamp', 'Timediff');
    
    for Idx = 1 : nrOfTimestamps
        
        timestampVal = double(Dat_Timestamp(Idx));
        
        fprintf ('%8d %12.6f ms', Idx - 1, 1000 * (timestampVal / cardInfo.setSamplerate / cardInfo.oversampling));
        
        % ----- print the difference, starting with segment 1 -----
        if Idx > 1
            timestampValLast = double(Dat_Timestamp(Idx-1));
            fprintf ('%7.2f ms', 1000 * ((timestampVal - timestampValLast) / cardInfo.setSamplerate / cardInfo.oversampling));
        end
        
        fprintf ('\n');
    end
    
    % ----- free timestamp buffer memory -----
    errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 1, 0, 1, 0, 0); 
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetTimestampData:\n\t', true);
        return;
    end
end            

% ***** close card *****
spcMCloseCard (cardInfo);                    

% ***** plot data of channel 0 and ABA *****

% ----- set time arrays for channel 0 and ABA -----
t_Data = 0 : memSamples - 1; 
t_ABA  = 0 : divABA : memSamples - 1;

plot (t_Data, Dat_Ch0, '.b', t_ABA, ABA_Ch0, '.r');

title ('ABA example: Ch0 (blue), ABA (red)');
