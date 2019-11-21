%**************************************************************************
%
% speedTest.m                             (c) Spectrum GmbH , 10/2015
%
%**************************************************************************

fprintf ('\n**************************************\n');
fprintf ('* Matlab transfer speed test program *\n');
fprintf ('**************************************\n');

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

[MBytesToTransfer, cardInfo.setChannels, samplerate, bufferSize, notifySize, dataType] = AcquiGetUserInput (cardInfo);

% ***** do card setup *****

% ----- FIFO mode setup, we run continuously and have 16 samples of pre data before trigger event -----
[success, cardInfo] = spcMSetupModeRecFIFOSingle (cardInfo, 0, bitshift (1, cardInfo.setChannels) - 1, 16, 0, 0);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecFIFOSingle:\n\t', true);
    return;
end

% ----- set the samplerate, use internal PLL, no clock output -----
[success, cardInfo] = spcMSetupClockPLL (cardInfo, samplerate, 0);  % clock output : enable = 1, disable = 0
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
if cardInfo.cardFunction == mRegs('SPCM_TYPE_AI')
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
end
    
% ----- allocate buffer memory -----
fprintf ('\n Allocate memory for FIFO transfer ... ');
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 0, 1, 1, cardInfo.bytesPerSample * bufferSize, cardInfo.bytesPerSample * notifySize);   
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetupFIFOBuffer:\n\t', true);
    return;
end
fprintf ('done.\n');

% ----- set command flags -----
commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));

fprintf (' Transfer started ....................')

blockCounter = 0;
MBytesTransferred = 0;

% ----- start card ----- 
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), commandMask);
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'spcm_dwSetParam_i32:\n\t', true);
    return;
end

tic;

while MBytesTransferred < MBytesToTransfer    
    
    % ***** wait for the next block *****
    errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_DATA_WAITDMA'));
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
        return;
    end
    
    blockCounter = blockCounter + 1;
    
    switch cardInfo.setChannels
        
        case 1
            % ----- get data block for one channel -----
            switch dataType
                case 1
                    [errorCode, Data] = spcm_dwGetRawData (cardInfo.hDrv, 0, notifySize, cardInfo.bytesPerSample); 
                    MBytesTransferred = blockCounter * cardInfo.bytesPerSample * notifySize / 1024 / 1024; 
                case 2
                    [errorCode, Dat_Block_Ch0] = spcm_dwGetData (cardInfo.hDrv, 0, notifySize/cardInfo.setChannels, cardInfo.setChannels, 0);
                    MBytesTransferred = blockCounter * cardInfo.bytesPerSample * notifySize / 1024 / 1024; 
                case 3
                    [errorCode, Dat_Block_Ch0] = spcm_dwGetData (cardInfo.hDrv, 0, notifySize/cardInfo.setChannels, cardInfo.setChannels, 1);
                    MBytesTransferred = blockCounter * cardInfo.bytesPerSample * notifySize / 1024 / 1024; 
            end
                
        case 2
            % ----- get data block for two channels ----- 
            switch dataType
                case 1
                    [errorCode, Data] = spcm_dwGetRawData (cardInfo.hDrv, 0, notifySize, cardInfo.bytesPerSample); 
                    MBytesTransferred = blockCounter * cardInfo.bytesPerSample * notifySize / 1024 / 1024; 
                case 2
                    [errorCode, Dat_Block_Ch0, Dat_Block_Ch1] = spcm_dwGetData (cardInfo.hDrv, 0, notifySize/cardInfo.setChannels, cardInfo.setChannels, 0);
                    MBytesTransferred = blockCounter * cardInfo.bytesPerSample * notifySize / 1024 / 1024; 
                case 3
                    [errorCode, Dat_Block_Ch0, Dat_Block_Ch1] = spcm_dwGetData (cardInfo.hDrv, 0, notifySize/cardInfo.setChannels, cardInfo.setChannels, 1);
                    MBytesTransferred = blockCounter * cardInfo.bytesPerSample * notifySize / 1024 / 1024; 
             end
                     
        case 4
            % ----- get data block for four channels with offset = 0 ----- 
            switch dataType
                case 1
                    [errorCode, Data] = spcm_dwGetRawData (cardInfo.hDrv, 0, notifySize, cardInfo.bytesPerSample); 
                    MBytesTransferred = blockCounter * cardInfo.bytesPerSample * notifySize / 1024 / 1024; 
                case 2
                    [errorCode, Dat_Block_Ch0, Dat_Block_Ch1, Dat_Block_Ch2, Dat_Block_Ch3] = spcm_dwGetData (cardInfo.hDrv, 0, notifySize/cardInfo.setChannels, cardInfo.setChannels, 0);
                    MBytesTransferred = blockCounter * cardInfo.bytesPerSample * notifySize / 1024 / 1024; 
                case 3
                    [errorCode, Dat_Block_Ch0, Dat_Block_Ch1, Dat_Block_Ch2, Dat_Block_Ch3] = spcm_dwGetData (cardInfo.hDrv, 0, notifySize/cardInfo.setChannels, cardInfo.setChannels, 1);
                    MBytesTransferred = blockCounter * cardInfo.bytesPerSample * notifySize / 1024 / 1024; 
            end
    end
end

time = toc;

fprintf (' done.\n');
fprintf ('\n ***** Result *****\n');
fprintf (' Transfer time    = %f sec\n', time);
fprintf (' Transferred data = %f MBytes\n', MBytesTransferred); 
fprintf (' ------------------------------------\n');
fprintf (' => %f MBytes/s\n', MBytesTransferred/time);

% ***** free allocated buffer memory *****
errorCode = spcm_dwSetupFIFOBuffer (cardInfo.hDrv, 0, 0, 1, cardInfo.bytesPerSample * bufferSize, cardInfo.bytesPerSample * notifySize);   
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
end

% ***** close card *****
spcMCloseCard (cardInfo);                    


























