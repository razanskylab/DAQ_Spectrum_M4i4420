%**************************************************************************
%
% rec_fifo_single.m                            (c) Spectrum GmbH , 10/2015
%
%**************************************************************************
%
% Does a continous FIFO transfer and writes data to binary files.
% Afterwards the first four channels will read out from the files 
% and will be plotted.
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

% ***** do card setup *****

% ----- set channel mask for max channels -----
if cardInfo.maxChannels == 64
    chMaskH = hex2dec ('FFFFFFFF');
    chMaskL = hex2dec ('FFFFFFFF');
else
    chMaskH = 0;
    chMaskL = bitshift (1, cardInfo.maxChannels) - 1;
end

% ----- FIFO mode setup, we run continuously and have 16 samples of pre data before trigger event -----
[success, cardInfo] = spcMSetupModeRecFIFOSingle (cardInfo, chMaskH, chMaskL, 16, 0, 0);
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

% ----- we set software trigger, no trigger output -----
[success, cardInfo] = spcMSetupTrigSoftware (cardInfo, 0);  % trigger output : enable = 1, disable = 0
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);
    return;
end

% ----- type dependent card setup -----
switch cardInfo.cardFunction
    
    % ----- analog acquistion card setup (1 = AnalogIn) -----
    case 1
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
   
   % ----- digital acquisition card setup (3 = DigitalIn, 5 = DigitalIO) -----
   case { 3, 5 }
       % ----- set all input channel groups to 110 ohm termination (if it's available) ----- 
       for i=0 : cardInfo.DIO.groups-1
           [success, cardInfo] = spcMSetupDigitalInput (cardInfo, i, 1);
       end
end

bufferSize = 8 * 1024 * 1024; % 8 MSample
notifySize = 4096;            % 4 kSample 

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
    
    % ----- analog data (max. 4 channels) -----
    
    % ----- open file channel 0 -----
    if cardInfo.setChannels >= 1
        fIdCh0 = fopen ('ch0.dat', 'w');
    end

    % ----- open file channel 1 -----
    if cardInfo.setChannels >= 2
        fIdCh1 = fopen ('ch1.dat', 'w');
    end

    % ----- open file channel 2 and channel 3 -----
    if cardInfo.setChannels >= 4
        fIdCh2 = fopen ('ch2.dat', 'w');
        fIdCh3 = fopen ('ch3.dat', 'w');
    end
else
    % ----- digital data -----
    fIdDigital = fopen ('digital.dat', 'w');
end

% ----- set dataType: 0 = RAW (int16), 1 = Amplitude calculated (float) -----
dataType = 0;

% ----- set number of blocks to get -----
blocksToGet = 500;

% ----- set command flags -----
commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));

% ----- start card ----- 
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), commandMask);
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    return;
end

for blockCounter=1 : blocksToGet
    
    % ***** wait for the next block *****
    errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_DATA_WAITDMA'));
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
        return;
    end
    
    if cardInfo.cardFunction == mRegs ('SPCM_TYPE_AI')
        
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
        [errorCode, RAWData] = spcm_dwGetRawData (cardInfo.hDrv, 0, notifySize, 2);
    end    
        
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetData:\n\t', true);
        return;
    end
    
    samplesTransferred = blockCounter * notifySize / 1024 / 1024;
    
    % ***** write data to disk *****
    if cardInfo.cardFunction == mRegs ('SPCM_TYPE_AI')
        
        % ----- analog data -----
         
        % ----- write data block channel 0 to file -----
        if cardInfo.setChannels >= 1
            if dataType == 1
                fwrite (fIdCh0, Dat_Block_Ch0, 'float');
            else
                fwrite (fIdCh0, Dat_Block_Ch0, 'int16');    
            end
        
            fprintf ('\n%.2f MSamples written to [ch0.dat]', samplesTransferred);  
        end
    
        % ----- write data block channel 1 to file -----
        if cardInfo.setChannels >= 2
            if dataType == 1
                fwrite (fIdCh1, Dat_Block_Ch1, 'float');
            else
                fwrite (fIdCh1, Dat_Block_Ch1, 'int16');
            end
        
            fprintf (' [ch1.dat]');
        end
    
        % ----- write data block channel 2, channel 3 to file -----
        if cardInfo.setChannels >= 4
            if dataType == 1
                fwrite (fIdCh2, Dat_Block_Ch2, 'float');   
                fwrite (fIdCh3, Dat_Block_Ch3, 'float');   
            else
                fwrite (fIdCh2, Dat_Block_Ch2, 'int16');   
                fwrite (fIdCh3, Dat_Block_Ch3, 'int16');   
            end
        
            fprintf (' [ch2.dat] [ch3.dat]');
        end
    else
        % ----- digital data -----
        fwrite (fIdDigital, RAWData, 'int16');
        
        fprintf ('\n%.2f MSamples written to [digital.dat]', samplesTransferred);  
    end
end
  
% ***** close files *****

if cardInfo.cardFunction == 1
    
    % ----- analog -----
    
    % ----- close file channel 0 -----
    if cardInfo.setChannels >= 1
        fclose(fIdCh0);    
    end

    % ----- close file channel 1 -----
    if cardInfo.setChannels >= 2
        fclose(fIdCh1);
    end

    % ----- close file channel 2 and channel 3 -----
    if cardInfo.setChannels >= 4
        fclose(fIdCh2);
        fclose(fIdCh3);
    end
else
    
    % ----- digital -----
    fclose (fIdDigital);
end

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
   
       % ----- channel 0 -----
        if cardInfo.setChannels >= 1
        
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
        
            titleText = 'FIFO example: Ch0';
        end

        % ----- channel 1 -----
        if cardInfo.setChannels >= 2 
        
            % ----- read data of channel 1 from file -----
            fIdCh1 = fopen ('ch1.dat', 'r');
            if dataType == 1
                Dat_Ch1 = fread (fIdCh1, 'float');
            else
                Dat_Ch1 = fread (fIdCh1, 'int16');
            end
            fclose (fIdCh1);
        
            % ----- plot channel 1 -----
            hold on;
            plot (Dat_Ch1, 'g');
        
            titleText = 'FIFO example: Ch0 (blue), Ch1 (green)';
        end

        % ----- channel 2, channel 3 -----
        if cardInfo.setChannels >= 4
        
            % ----- read data of channel 2 and 3 from file -----
            fIdCh2 = fopen ('ch2.dat', 'r');
            fIdCh3 = fopen ('ch3.dat', 'r');
        
            if dataType == 1
                Dat_Ch2 = fread (fIdCh2, 'float');
                Dat_Ch3 = fread (fIdCh3, 'float');
            else
                Dat_Ch2 = fread (fIdCh2, 'int16');
                Dat_Ch3 = fread (fIdCh3, 'int16');
            end
            fclose (fIdCh2);
            fclose (fIdCh3);
        
            % ----- plot channel 2 and channel 3 -----
            plot (Dat_Ch2, 'r');
            plot (Dat_Ch3, 'y');
        
            titleText = 'FIFO example: Ch0 (blue), Ch1 (green), Ch2 (red), Ch3 (yellow)';
        end
    
        title (titleText);
    
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


























