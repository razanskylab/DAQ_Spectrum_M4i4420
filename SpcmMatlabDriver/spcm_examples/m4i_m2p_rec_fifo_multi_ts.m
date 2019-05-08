%**************************************************************************
%
% m4i_m2p_rec_fifo_multi_ts.m                   (c) Spectrum GmbH, 04/2018
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
segmentSize = 4096;

% ----- set only 1 channel -----
[success, cardInfo] = spcMSetupModeRecFIFOMulti (cardInfo, 0, 1, segmentSize, segmentSize - 128, 0);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecFIFOMulti:\n\t', true);
    return;
end

% ----- we try to set the samplerate to 10 MHz on internal PLL, no clock output -----
[success, cardInfo] = spcMSetupClockPLL (cardInfo, 10000000, 0);  % clock output : enable = 1, disable = 0
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupClockPLL:\n\t', true);
    return;
end
fprintf ('\n Sampling rate set to %.1f MHz\n', cardInfo.setSamplerate / 1000000);

% ----- we set trigger to external positive edge, please connect the trigger line! -----

% ----- extMode = 1, trigTerm = 0, pulseWidth = 0, singleSrc = 1, extLine = 0 -----
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

% ----- setup timestamp -----
mode = bitor (mRegs('SPC_TSMODE_STARTRESET'), mRegs('SPC_TSCNT_INTERNAL'));
[success, cardInfo] = spcMSetupTimestamp (cardInfo, mode, 0);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTimestamp:\n\t', true);
    return;
end
    
% ----- buffer and notify sizes for data transfer -----
bufferSize = 16 * 1024 * 1024;  % 16 MSample
notifySize = 4096; % 4 kSample

% ----- buffer and notify sizes for timestamps -----
bufferSizeTS = 1024 * 1024; % 1 MByte
notifySizeTS = 4096; % 4 kBytes

% ----- allocate data buffer memory -----
fprintf ('\n allocate memory for FIFO transfer ... ');
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 0, 1, 1, cardInfo.bytesPerSample * bufferSize, cardInfo.bytesPerSample * notifySize);
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetupFIFOBuffer:\n\t', true);
    return;
end

% ----- allocate timestamps buffer memory -----
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 1, 1, 1, bufferSizeTS, notifySizeTS); 
    
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetupFIFOBuffer:\n\t', true);
    return;
end

fprintf ('ready.\n');

% ***** open files to write data to harddisk *****
fIdCh0 = fopen ('ch0.dat', 'w');
fIdTime = fopen('timestamps.dat','w');

% ----- set dataType: 0 = RAW (int16), 1 = Amplitude calculated (float) -----
dataType = 0;

% ----- set number of blocks to get -----
blocksToGet = 1000;

% ----- set timeout -----
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_TIMEOUT'), 100000);
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
end

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
timestampValLast = 0;

for blockCounter=1 : blocksToGet
    
    % ***** wait for the next block *****
    errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_DATA_WAITDMA'));
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
        return;
    end

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
    end
        
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetData:\n\t', true);
        return;
    end    

    samplesTransferred = blockCounter * notifySize / 1024 / 1024;

    % ***** write data to disk *****
     if cardInfo.cardFunction == mRegs('SPCM_TYPE_AI')
        
         % ----- analog data -----
         
         % ----- write data block channel 0 to file -----
         if dataType == 1
            fwrite (fIdCh0, Dat_Block_Ch0, 'float');
         else
            fwrite (fIdCh0, Dat_Block_Ch0, 'int16');    
         end
        
         fprintf ('\n%.2f MSamples written to [ch0.dat]', samplesTransferred);
     end

    % ***** read available timestamp bytes *****
    [errorCode, TS_Bytes_Available] = spcm_dwGetParam_i32(cardInfo.hDrv, mRegs('SPC_TS_AVAIL_USER_LEN'));
    
    if (TS_Bytes_Available >= notifySizeTS)
        NrOfTimestamps = TS_Bytes_Available / 8; % 1 Timestamp = 8 Byte

        % ----- get available timestamps -----
        [errorCode, Dat_Timestamp] = spcm_dwGetTimestampData (cardInfo.hDrv, NrOfTimestamps);
        
        % M4i timestamp value is 128 bit (16 Bytes) long
        % Dat_Timestamp[1] : 64 bit low 
        % Dat_Timestamp[2] : 64 bit high
        % Using standard data format we only need to read the low parts
        % Please check the timestamp section in the hardware manual for more infos
        for Idx = 1 : 2 : NrOfTimestamps
            timestampVal = double(Dat_Timestamp(Idx));
            
            timestampVal_ms  = 1000 * (timestampVal / cardInfo.setSamplerate);
            timestampDiff_ms = 1000 * ((timestampVal - timestampValLast) / cardInfo.setSamplerate);
            
            % ----- write timestamp to file -----
            fprintf (fIdTime, '[%03d] %12.6f ms, Diff: %6.6f ms\n', TS_Count, timestampVal_ms, timestampDiff_ms);
            
            timestampValLast = timestampVal;
            
            TS_Count = TS_Count + 1;
        end    
    end
end
    
% ----- stop card -----
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_CARD_STOP'));

fprintf ('\n\nTIMESTAMP COUNT : %d\n', TS_Count);    
   
% ***** free allocated buffer memory *****
spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 0, 0, 1, 0, 0);
spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 1, 0, 1, 0, 0); 

% ***** close card *****
spcMCloseCard (cardInfo);

% ***** close files *****
fclose(fIdCh0);
fclose(fIdTime);
