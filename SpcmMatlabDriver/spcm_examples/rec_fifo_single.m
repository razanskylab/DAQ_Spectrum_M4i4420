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

%[success, cardInfo] = spcMInitDevice (deviceString);

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
[success, cardInfo] = spcMSetupClockPLL (cardInfo, 200e6, 0);  % clock output : enable = 1, disable = 0
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupClockPLL:\n\t', true);
    return;
end

fprintf ('\n Sampling rate set to %.1f MHz\n', cardInfo.setSamplerate / 1e6);

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
errorCode = spcm_dwSetupFIFOBuffer (...
    cardInfo.hDrv, ...
    0, ...
    1, ...
    1, ...
    cardInfo.bytesPerSample * bufferSize, ...
    cardInfo.bytesPerSample * notifySize);   

if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetupFIFOBuffer:\n\t', true);
    return;
end
fprintf ('ready.\n');


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

outData = [];
tic
for blockCounter=1:blocksToGet
    
    % ***** wait for the next block *****
    errorCode = spcm_dwSetParam_i32 (...
        cardInfo.hDrv, ...
        mRegs('SPC_M2CMD'), ...
        mRegs('M2CMD_DATA_WAITDMA'));

    % if (errorCode ~= 0)
    %     [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    %     spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    %     return;
    % end

    [errorCode, Dat_Block_Ch0, Dat_Block_Ch1] = spcm_dwGetData (...
        cardInfo.hDrv, ...
        0, ...
        notifySize/cardInfo.setChannels, ...
        cardInfo.setChannels, ...
        dataType);

    % outData = [outData Dat_Block_Ch0];
        
    % if (errorCode ~= 0)
    %     [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    %     spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetData:\n\t', true);
    %     return;
    % end
    
    % samplesTransferred = blockCounter * notifySize / 1024 / 1024;
end

toc

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

errorCode = spcm_dwSetupFIFOBuffer (...
    cardInfo.hDrv, ...
    0, ...
    0, ...
    1, ...
    0, ...
    0);   


% ***** close card *****
%spcMCloseCard (cardInfo);                    


























