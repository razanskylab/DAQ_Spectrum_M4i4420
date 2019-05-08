%**************************************************************************
%
% rec_fifo_ABA_poll.m                       (c) Spectrum GmbH , 06/2017
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
if (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_AI'))
    spcMErrorMessageStdOut (cardInfo, 'Error: Card function not supported by this example\n', false);
    return;
end

% ----- check if Multiple Recording is installed -----
if (bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_ABA')) == 0)
    spcMErrorMessageStdOut (cardInfo, 'Error: ABA Option not installed. Example was done especially for this option!\n', false);
    return;
else
    fprintf ('\n ABA ........ installed.');
end

% ----- check if timestamp is installed -----
if (bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_TIMESTAMP')) == 0)
    spcMErrorMessageStdOut (cardInfo, 'Error: Timestamp Option not installed. Example was done especially for this option!\n', false);
    return;
else
    fprintf ('\n Timestamp ................. installed.\n');
end

% ***** do card setup *****
chMaskH = 0;
chMaskL = 1;
segmentsize = 2048;
samplerate = 100000;
ABADivider = 256;
ABA_SamplesPerBlock = 64;

% ----- set Fifo ABA mode -----
[success, cardInfo] = spcMSetupModeRecFIFOABA (cardInfo, chMaskH, chMaskL, segmentsize, segmentsize - 128, ABADivider, 0);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecFIFOABA:\n\t', true);
    return;
end
 
% ----- set the samplerate on internal PLL, no clock output -----
[success, cardInfo] = spcMSetupClockPLL (cardInfo, samplerate, 0);  % clock output : enable = 1, disable = 0
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupClockPLL:\n\t', true);
    return;
end
fprintf ('\n Sampling rate set to %.1f kHz\n', cardInfo.setSamplerate / 1000);


% ----- we set trigger to external positive edge, please connect the trigger line! -----

% ----- extMode = SPC_TM_POS, trigTerm = 0, pulseWidth = 0, singleSrc = 1, extLine = 0 -----
[success, cardInfo] = spcMSetupTrigExternal (cardInfo, mRegs('SPC_TM_POS'), 0, 0, 1, 0);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigExternal:\n\t', true);
    return;
end

% ----- program all input channels to +/-1 V and 50 ohm termination (if it's available) -----
for i=0 : cardInfo.maxChannels-1  
    [success, cardInfo] = spcMSetupAnalogInputChannel (cardInfo, i, 1000, 1, 0, 0);  
    if (success == false)
        spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupInputChannel:\n\t', true);
        return;
    end
end
   
bufferSize = 8 * 1024 * 1024; % 8 MSample
notifySize = 2048; % 4 kSample 

% ----- allocate buffer memory -----
fprintf ('\n allocate memory for FIFO transfer ... ');
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 0, 1, 1, cardInfo.bytesPerSample * bufferSize, cardInfo.bytesPerSample * notifySize);   
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetupFIFOBuffer:\n\t', true);
    return;
end
fprintf ('ready.\n');

% ***** open files to write data to harddisk *****

% ----- analog data -----
fIdCh0 = fopen ('ch0.dat', 'w');
fIdTime = fopen('timestamps.dat','w');

% ----- set dataType: 0 = RAW (int16), 1 = Amplitude calculated (float) -----
dataType = 0;

% ----- set number of blocks to get -----
blocksToGet = 100 ;

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

% ----- allocate ABA buffer memory -----
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 2, 1, 1, 40960, 4096); 
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
blockCounter = 1;
scaleX = zeros (1, ABA_SamplesPerBlock);

while blockCounter < blocksToGet
    
    % read card status and get data block if block ready status is valid
    [errorCode, Status] = spcm_dwGetParam_i32(cardInfo.hDrv, mRegs('SPC_M2STATUS'));
    
    if (bitand (Status, mRegs('M2STAT_DATA_BLOCKREADY')) == mRegs('M2STAT_DATA_BLOCKREADY'))
        
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
   
        if (errorCode ~= 0)
            [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
            spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetData:\n\t', true);
            return;
        end
    
        samplesTransferred = blockCounter * notifySize / 1024 / 1024;
    
        % ----- plot data block of channel 0 -----
        subplot (2, 1, 2); plot (Dat_Block_Ch0);
        drawnow;
        
        % ***** write data to disk *****
     
        % ----- write data block channel 0 to file -----
        if dataType == 1
            fwrite (fIdCh0, Dat_Block_Ch0, 'float');
        else
            fwrite (fIdCh0, Dat_Block_Ch0, 'int16');    
        end
        
        fprintf ('\n%.2f MSamples written to [ch0.dat]', samplesTransferred);
        
        blockCounter = blockCounter + 1;
    end
    
    
    % ***** poll ABA *****
    [errorCode, ABA_Bytes_Available] = spcm_dwGetParam_i32(cardInfo.hDrv, mRegs('SPC_ABA_AVAIL_USER_LEN'));
    if (ABA_Bytes_Available >= ABA_SamplesPerBlock * cardInfo.setChannels * cardInfo.bytesPerSample)
        
        % ----- get available ABA data for channel 0 -----
       [errorCode, Dat_ABA] = spcm_dwGetABAData (cardInfo.hDrv, ABA_SamplesPerBlock, 1, dataType);
       if (errorCode ~= 0)
         [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
         spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetTimestampData:\n\t', true);
         return;
       end
       
       % ----- plot ABA block of channel 0 -----
       scaleX = scaleX (1, ABA_SamplesPerBlock) + 1 : scaleX (1, ABA_SamplesPerBlock) + ABA_SamplesPerBlock;
       subplot(2,1,1); plot (scaleX, Dat_ABA);
       drawnow;
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
fclose (fIdCh0);
fclose (fIdTime);

% ***** free allocated buffer memory *****
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 0, 0, 1, cardInfo.bytesPerSample * bufferSize, cardInfo.bytesPerSample * notifySize);   

if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
end

% ***** close card *****
spcMCloseCard (cardInfo);


                    