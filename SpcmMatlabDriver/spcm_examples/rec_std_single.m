%**************************************************************************
%
% rec_std_single.m                             (c) Spectrum GmbH , 10/2015
%
%**************************************************************************
%
% Example for all SpcMDrv based (M2i) acquisition cards. 
% Shows standard data acquistion using single mode (one shot)
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

% ----- standard single, all channels, memsize=16k, posttrigge=8k -> pretrigger=8k  -----    
[success, cardInfo] = spcMSetupModeRecStdSingle (cardInfo, chMaskH, chMaskL, 16 * 1024, 8 * 1024);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecStdSingle:\n\t', true);
    return;
end

% ----- we try to set the samplerate to 10 MHz on internal PLL, no clock output -----
if cardInfo.maxSamplerate >= 10000000
    [success, cardInfo] = spcMSetupClockPLL (cardInfo, 10000000, 0);  % clock output : enable = 1, disable = 0
else
    % ----- set samplerate to the max samplerate of the card, if max samplerate is less than 10 MHz -----
    [success, cardInfo] = spcMSetupClockPLL (cardInfo, cardInfo.maxSamplerate, 0); % clock output : enable = 1, disable = 0
end
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
       % ----- set all input channel groups, no 110 ohm termination ----- 
       for i=0 : cardInfo.DIO.groups-1
           [success, cardInfo] = spcMSetupDigitalInput (cardInfo, i, 0);
       end
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
fprintf (' Starting the card and waiting for ready interrupt ...\n');

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
    
    % ***** get analog input data *****
    if cardInfo.cardFunction == mRegs ('SPCM_TYPE_AI')
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
            case 8
                % ----- get the whole data for eight channels with offset = 0 ----- 
                [errorCode, Dat_Ch0, Dat_Ch1, Dat_Ch2, Dat_Ch3, Dat_Ch4, Dat_Ch5, Dat_Ch6, Dat_Ch7] = spcm_dwGetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, dataType);
            case 16
                % ----- get the whole data for sixteen channels with offset = 0 ----- 
                [errorCode, Dat_Ch0, Dat_Ch1, Dat_Ch2, Dat_Ch3, Dat_Ch4, Dat_Ch5, Dat_Ch6, Dat_Ch7, Dat_Ch8, Dat_Ch9, Dat_Ch10, Dat_Ch11, Dat_Ch12, Dat_Ch13, Dat_Ch14, Dat_Ch15] = spcm_dwGetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, dataType);
        end
    else
        % ***** get digital input data *****
        
        % ----- get whole digital data in one multiplexed data block -----
        [errorCode, RAWData] = spcm_dwGetRAWData (cardInfo.hDrv, 0, cardInfo.setMemsize, 2);
        
        % ----- demultiplex digital data (DigData (channelIndex, value)) -----
        DigData = spcMDemuxDigitalData (RAWData, cardInfo.setMemsize, cardInfo.setChannels);
    end
    
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetData:\n\t', true);
        return;
    end
end

fprintf (' ... acquistion ended, data has been transferred to PC memory.\n');


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
        
        case {4, 8, 16}
            plot (t, Dat_Ch0, 'b', t, Dat_Ch1, 'g', t, Dat_Ch2, 'r', t, Dat_Ch3, 'y');
    end
else
    
    % ***** plot digital data *****
    
    % ----- plot first 1000 samples for each channel -----
    spcMPlotDigitalData (DigData, cardInfo.setChannels, 1000);
end

% ***** close card *****
spcMCloseCard (cardInfo);
        