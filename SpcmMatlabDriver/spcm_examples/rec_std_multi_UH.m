%**************************************************************************
%
% rec_std_multi.m                              (c) Spectrum GmbH , 10/2015
%
%**************************************************************************
%
% Example for all SpcMDrv based (M2i) acquisition cards with the option
% Multiple Recording installed
%
% Shows standard data acquistion using Multiple Recording mode. 
% If timestamp is installed the corresponding timestamp values are also read
% out and displayed.
%  
% Feel free to use this source for own projects and modify it in any kind
%
%**************************************************************************

% helper maps to use label names for registers and errors
mRegs = spcMCreateRegMap ();
mErrors = spcMCreateErrorMap ();

deviceString = '/dev/spcm0';

[success, cardInfo] = spcMInitDevice (deviceString);

% ***** do card setup *****

memSamples   = 501 * 3008;      % 512k
segmentSize  =  3008;      % 64k
posttrigger  =  3008 - 16; % -> pretrigger = 16

% ----- set channel mask for max channels -----
if cardInfo.maxChannels == 64
    chMaskH = hex2dec ('FFFFFFFF');
    chMaskL = hex2dec ('FFFFFFFF');
else
    chMaskH = 0;
    chMaskL = bitshift (1, cardInfo.maxChannels) - 1;
end


% ----- we set trigger to external positive edge, please connect the trigger line! -----

% ----- extMode = 1, trigTerm = 0, pulseWidth = 0, singleSrc = 1, extLine = 0 -----
[success, cardInfo] = spcMSetupTrigExternal (cardInfo, 1, 0, 0, 1, 1);  % 1 = SPC_TM_POS
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigExternal:\n\t', true);
    return;
end

% ----- standard multi, all channels, memSamples, segmentSize, posttrigger -----    
[success, cardInfo] = spcMSetupModeRecStdMulti (cardInfo, chMaskH, chMaskL, memSamples, segmentSize, posttrigger);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecStdMulti:\n\t', true);
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


% ***** start card for acquistion *****
for i=1:5
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
    if ((errorCode ~= 0) & (errorCode ~= mErrors('ERR_TIMEOUT')))
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
        [errorCode, Dat_Ch0, Dat_Ch1] = spcm_dwGetData (...
            cardInfo.hDrv, ...
            0, ...
            cardInfo.setMemsize, ...
            cardInfo.setChannels, ...
            dataType);
        
        if (errorCode ~= 0)
            [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
            spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetData:\n\t', true);
            return;
        end
    end
end

% ***** close card *****
spcMCloseCard (cardInfo);                    
