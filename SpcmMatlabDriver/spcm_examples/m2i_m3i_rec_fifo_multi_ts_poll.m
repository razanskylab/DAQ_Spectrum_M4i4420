%**************************************************************************
%
% rec_fifo_multi_ts_poll.m                     (c) Spectrum GmbH , 10/2015
%
%**************************************************************************
%
% Does a continous FIFO transfer while using the Multiple Recording mode
% and polls Timestamps.
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
if (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_AI')) & (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_DI')) & (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_DIO'))
    spcMErrorMessageStdOut (cardInfo, 'Error: Card function not supported by this example\n', false);
    return;
end

% ----- check if Multiple Recording is installed -----
if (bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_MULTI')) == 0)
    spcMErrorMessageStdOut (cardInfo, 'Error: Multiple Recording Option not installed. Example was done especially for this option!\n', false);
    return;
else
    fprintf ('\n Multiple Recording ........ installed.');
end

% ----- check if timestamp is installed -----
if (bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_TIMESTAMP')) == 0)
    spcMErrorMessageStdOut (cardInfo, 'Error: Timestamp Option not installed. Example was done especially for this option!\n', false);
    return;
else
    fprintf ('\n Timestamp ................. installed.\n');
end

% ***** do card setup *****

segmentsize = 2048;

if cardInfo.cardFunction == 1
    % ----- set only 1 channel for analog card -----
    [success, cardInfo] = spcMSetupModeRecFIFOMulti (cardInfo, 0, 1, segmentsize, segmentsize - 128, 0);
else
    % ----- set 8 channels for digital card -----
    [success, cardInfo] = spcMSetupModeRecFIFOMulti (cardInfo, 0, 255, segmentsize, segmentsize - 128, 0);
end
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecFIFOSingle:\n\t', true);
    return;
end
 
% ----- we try to set the samplerate to 1 MHz on internal PLL, no clock output -----
[success, cardInfo] = spcMSetupClockPLL (cardInfo, 1000000, 0);  % clock output : enable = 1, disable = 0
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

% ----- type dependent card setup -----
switch cardInfo.cardFunction
    
    % ----- analog acquistion card setup -----
    case mRegs('SPCM_TYPE_AI')
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
   
   % ----- digital acquisition card setup -----
   case { mRegs('SPCM_TYPE_DI'), mRegs('SPCM_TYPE_DIO') }
       % ----- set all input channel groups to 110 ohm termination (if it's available) ----- 
       for i=0 : cardInfo.DIO.groups-1
           [success, cardInfo] = spcMSetupDigitalInput (cardInfo, i, 1);
       end
end

bufferSize = 64 * 1024;  % 64 kSample
notifySize = 4096;       % 4  kSample 

% ----- allocate buffer memory -----
fprintf ('\n allocate memory for FIFO transfer ... ');
if cardInfo.cardFunction == 1
    errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 0, 1, 1, cardInfo.bytesPerSample * bufferSize, cardInfo.bytesPerSample * notifySize);   
else
    errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 0, 1, 1, cardInfo.bytesPerSample * bufferSize, 2 * notifySize);   
end
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetupFIFOBuffer:\n\t', true);
    return;
end
fprintf ('ready.\n');

% ***** open files to write data to harddisk *****
if cardInfo.cardFunction == 1
    
    % ----- analog data -----
    fIdCh0 = fopen ('ch0.dat', 'w');
else
    % ----- digital data -----
    fIdDigital = fopen ('digital.dat', 'w');
end

fIdTime = fopen('timestamps.dat','w');

% ----- set dataType: 0 = RAW (int16), 1 = Amplitude calculated (float) -----
dataType = 0;

% ----- set number of blocks to get -----
blocksToGet = 100;

% ----- set up timestamp mode to standard -----
mode = bitor (mRegs('SPC_TSMODE_STANDARD'), mRegs('SPC_TSCNT_INTERNAL'));
[success, cardInfo] = spcMSetupTimestamp (cardInfo, mode, 0);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTimestamp:\n\t', true);
    return;
end
    
% ----- allocate buffer memory: number of timestamps -----
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 1, 1, 1, 40960, 4096); 
    
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetupFIFOBuffer:\n\t', true);
    return;
end

% ----- set timeout -----
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_TIMEOUT'), 10000);
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
end

% ----- activate polling mode for timestamp transfer -----
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_EXTRA_POLL'));

% ----- set command flags -----
commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));

% ----- start card ----- 
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), commandMask);
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    return;
end

TS_Count = 0;

for blockCounter=1 : blocksToGet
    
    % ***** wait for the next block *****
    errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_DATA_WAITDMA'));
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
        return;
    end
    
    if cardInfo.cardFunction == 1
        
        % ***** get analog input data *****
        switch cardInfo.setChannels
        
            case 1
                % ----- get data block for one channel with offset = 0 ----- 
                [errorCode, Dat_Block_Ch0] = spcm_dwGetData (cardInfo.hDrv, 0, notifySize/cardInfo.setChannels, cardInfo.setChannels, dataType);
            case 2
                 % ----- get data block for two channels with offset = 0 ----- 
                [errorCode, Dat_Block_Ch0, Dat_Block_Ch1] = spcm_dwGetData (cardInfo.hDrv, 0, notifySize/cardInfo.setChannels, cardInfo.setChannels, dataType);
            case 4
                % ----- get data block for four channels with offset = 0 ----- 
                [errorCode, Dat_Block_Ch0, Dat_Block_Ch1, Dat_Block_Ch2, Dat_Block_Ch3] = spcm_dwGetData (cardInfo.hDrv, 0, notifySize/cardInfo.setChannels, cardInfo.setChannels, dataType);
            case 8
                % ----- get data block for eight channels with offset = 0 ----- 
                [errorCode, Dat_Block_Ch0, Dat_Block_Ch1, Dat_Block_Ch2, Dat_Block_Ch3, Dat_Block_Ch4, Dat_Block_Ch5, Dat_Block_Ch6, Dat_Block_Ch7] = spcm_dwGetData (cardInfo.hDrv, 0, notifySize/cardInfo.setChannels, cardInfo.setChannels, dataType);
            case 16
                % ----- get data block for sixteen channels with offset = 0 ----- 
                [errorCode, Dat_Block_Ch0, Dat_Block_Ch1, Dat_Block_Ch2, Dat_Block_Ch3, Dat_Block_Ch4, Dat_Block_Ch5, Dat_Block_Ch6, Dat_Block_Ch7, Dat_Block_Ch8, Dat_Block_Ch9, Dat_Block_Ch10, Dat_Block_Ch11, Dat_Block_Ch12, Dat_Block_Ch13, Dat_Block_Ch14, Dat_Block_Ch15] = spcm_dwGetData (cardInfo.hDrv, 0, notifySize/cardInfo.setChannels, cardInfo.setChannels, dataType);
        end
    else
        % ***** get digital input data *****
        
        % ----- get whole digital data in one multiplexed data block -----
        [errorCode, RAWData] = spcm_dwGetRAWData (cardInfo.hDrv, 0, notifySize, 2);
    end    
        
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetData:\n\t', true);
        return;
    end
    
    samplesTransferred = blockCounter * notifySize / 1024 / 1024;
    
    % ***** write data to disk *****
     if cardInfo.cardFunction == 1
        
         % ----- analog data -----
         
         % ----- write data block channel 0 to file -----
         if dataType == 1
            fwrite (fIdCh0, Dat_Block_Ch0, 'float');
         else
            fwrite (fIdCh0, Dat_Block_Ch0, 'int16');    
         end
        
         fprintf ('\n%.2f MSamples written to [ch0.dat]', samplesTransferred);  
     else
        % ----- digital data -----
        fwrite (fIdDigital, RAWData, 'int16');
        
        fprintf ('\n%.2f MSamples written to [digital.dat]', samplesTransferred);  
    end
    
    % ***** poll timestamps *****
    [errorCode, TS_Bytes_Available] = spcm_dwGetParam_i32(cardInfo.hDrv, mRegs('SPC_TS_AVAIL_USER_LEN'));
    
    if (TS_Bytes_Available >= 8)
        NrOfTimestamps = TS_Bytes_Available / 8; % 1 Timestamp = 8 Byte
        
        % ----- get available timestamps -----
        [errorCode, Dat_Timestamp] = spcm_dwGetTimestampData (cardInfo.hDrv, NrOfTimestamps);
 
        for Idx = 1 : NrOfTimestamps
            timestampVal = double(Dat_Timestamp(Idx));
            
            % ----- write timestamp to file -----
            fprintf (fIdTime, '[%d] %12.6f ms\n', TS_Count, 1000 * (timestampVal / cardInfo.setSamplerate / cardInfo.oversampling));
            
            TS_Count = TS_Count + 1;
        end
    end
end
  
fprintf ('\n\nTIMESTAMP COUNT : %d\n', TS_Count);

% ***** close files *****
if cardInfo.cardFunction == 1
    % ----- analog -----
    fclose(fIdCh0);    
else
    % ----- digital -----
    fclose (fIdDigital);
end

fclose(fIdTime);

% ***** free allocated buffer memory *****
if cardInfo.cardFunction == 1
    errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 0, 0, 1, cardInfo.bytesPerSample * bufferSize, cardInfo.bytesPerSample * notifySize);   
else
    errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 0, 0, 1, cardInfo.bytesPerSample * bufferSize, 2 * notifySize);   
end
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
end

% ***** plot data from file *****

% ----- disable plotting if recorded data gets too large -----
plotChannels = true;

if plotChannels == true;
        
   if cardInfo.cardFunction == 1
   
       % ----- plot analog data from file -----     
   
       % ----- read data of channel 0 from file -----
       fIdCh0 = fopen ('ch0.dat', 'r');
       if dataType == 1
          Dat_Ch0 = fread (fIdCh0, 'float');
       else
          Dat_Ch0 = fread (fIdCh0, 'int16');    
       end
       fclose (fIdCh0);
        
       % ----- plot channel 0 -----
       plot (Dat_Ch0);        
        
       title ('FIFO example: Ch0');
       
       if dataType == 1
          ylabel ('Amplitude: Volt');
       else
          ylabel ('Amplitude: RAW');
       end
    else
    
        % ----- plot digital data -----
    
        % ----- read digital data from file -----
        fIdDigital = fopen ('digital.dat', 'r');
        DigDataRaw = int16(fread (fIdDigital, 'int16'));
    
        % ----- convert column vector to row  vector -----
        DigDataRaw = DigDataRaw';
    
        % ----- demultiplex digital data (DigData (channelIndex, value)), demultiplex only the data of the first block -----
        DigData = spcMDemuxDigitalData (DigDataRaw, notifySize, cardInfo.setChannels);
        
        % ----- plot first 1000 samples for each channel -----
        spcMPlotDigitalData (DigData, cardInfo.setChannels, 1000);
    end
end

% ***** close card *****
spcMCloseCard (cardInfo);                    