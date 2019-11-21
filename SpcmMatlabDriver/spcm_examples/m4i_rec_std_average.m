%**************************************************************************
%
% rec_std_average.m                            (c) Spectrum GmbH, 10/2015
%
%**************************************************************************
%
% Example for all (M4i) acquisition cards with the option
% Average installed
%
% Shows standard data acquistion using Average mode. 
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

% ----- check if Average Option is installed -----
if (bitand (cardInfo.extFeatureMap, mRegs('SPCM_FEAT_EXTFW_SEGAVERAGE')) == 0)
    spcMErrorMessageStdOut (cardInfo, 'Error: Average Option not installed. Examples was done especially for this option!\n', false);
    return;
else
    fprintf ('\n Average Option ........ installed.');
end

% ----- check if timestamp is installed -----
if (bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_TIMESTAMP')) ~= 0)
    timestampInstalled = true; 
    fprintf ('\n Timestamp ................. installed.\n');
else
    timestampInstalled = false;
    fprintf ('\n Timestamp ................. not installed.\n');
end

% ***** do card setup *****
numOfSegments = 16;  
segmentSize   = 8192;
posttrigger   = segmentSize - 1024;
averagesPerSegment = 100;

memSize = numOfSegments * segmentSize;

% ----- set channel mask for max channels -----
chMaskH = 0;
chMaskL = bitshift (1, cardInfo.maxChannels) - 1;

% ----- standard multi, all channels, memSamples, segmentSize, posttrigger -----    
[success, cardInfo] = spcMSetupModeRecStdAverage (cardInfo, chMaskH, chMaskL, memSize, segmentSize, posttrigger, averagesPerSegment);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecStdMulti:\n\t', true);
    return;
end

% ----- we set the samplerate to maximum samplerate on internal PLL, no clock output -----
[success, cardInfo] = spcMSetupClockPLL (cardInfo, cardInfo.maxSamplerate, 0);  % clock output : enable = 1, disable = 0
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupClockPLL:\n\t', true);
    return;
end

fprintf ('\n Sampling rate set to %.1f MHz\n', cardInfo.setSamplerate / 1000000);

% ----- we set trigger to channel trigger positive edge for Ch0 -----
[success, cardInfo] = spcMSetupTrigChannel (cardInfo, 0, 1, 100, 50, 0, 0, 1);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigExternal:\n\t', true);
    return;
end

% ----- program all input channels to +/-1 V -----
for i=0 : cardInfo.maxChannels-1  
    [success, cardInfo] = spcMSetupAnalogPathInputCh (cardInfo, i, 0, 1000, 0, 0, 0, 0);  
    if (success == false)
        spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupInputChannel:\n\t', true);
        return;
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
    
    % ----- set dataType: 2 = Average (int32) -----
    dataType = 2;
    
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

% ***** close card *****
spcMCloseCard (cardInfo);

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
