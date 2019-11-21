%**************************************************************************
%
% rec_std_sync.m                               (c) Spectrum GmbH , 10/2015
%
%**************************************************************************
%
% Example for all SpcMDrv based (M2i) acquisition cards. 
% Shows the synchronization of one or more cards with acquistion mode.
%  
% The Star-Hub is accessed directly as this is very simple.
%
% Feel free to use this source for own projects and modify it in any kind.
%
%**************************************************************************

% helper maps to use label names for registers and errors
mRegs = spcMCreateRegMap ();
mErrors = spcMCreateErrorMap ();

starhubFound = false;

for cardCount = 0 : 15

    % ***** init card and store infos in cardInfo struct *****
    [success, cardInfo] = spcMInitCardByIdx (cardCount);

    if success == false
        
        if cardCount == 0
            spcMErrorMessageStdOut (cardInfo, 'Error: Could not open card\n', true);
            return;
        end
        
        break;
    else
        if bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_STARHUB5')) | bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_STARHUB16'))  % SPCM_FEAT_STARHUB5 = 32, SPCM_FEAT_STARHUB16 = 64
            starhubFound = true;
            fprintf ('Starthub found\n');
        end
        
        cardInfos (cardCount+1) = cardInfo;
    end
end        

% ----- printf info of all cards -----
for idx = 1 : cardCount 
    cardInfoText = spcMPrintCardInfo (cardInfos(idx));
    fprintf ('\nCard%d:\n', idx-1);
    fprintf (cardInfoText);
end

% ----- not our example if there's no starhub -----
if (starhubFound == false)
    fprintf ('\nThere is no starhub in the system, this example can not run\n');
    starhubOk = false;
else
    starhubOk = true;  
end

% ----- the star hub is accessed under it's own handle -----
if starhubOk == true
    hSync = spcm_hOpen ('sync0');
    if hSync == 0
        fprintf ('\nCan not open starhub handle\n');
        starhubOk = false;
    end

    if starhubOk == true
        [errorCode, syncCards] = spcm_dwGetParam_i32 (hSync, mRegs('SPC_SYNC_READ_SYNCCOUNT'));
        
        % ----- show cable connection info -----
        fprintf ('\nStar-hub information:\n');
        fprintf ('Star-hub is connected with %d cards\n', syncCards);
        for idx = 0 : syncCards - 1
            [errorCode, cable] = spcm_dwGetParam_i32 (hSync, mRegs('SPC_SYNC_READ_CABLECON0') + idx);
            fprintf ('  Card Idx %d (sn %05d) is', idx, cardInfos(idx+1).serialNumber);
            if cable ~= -1
                fprintf (' connected on cable %d\n', cable);
            else
                fprintf (' not connected with the star-hub\n');
            end
        end
        fprintf ('\n');
        
        % ----- all cards got a similar setup -----
        for idx = 1 : cardCount
            
            % ----- standard single, one channel, memsize=16k, posttrigge=8k -> pretrigger=8k  -----    
            [success, cardInfos(idx)] = spcMSetupModeRecStdSingle (cardInfos(idx), 0, 1, 16 * 1024, 8 * 1024);
            
            % ----- we try to set the samplerate to 1 MHz on internal PLL, no clock output -----
            [success, cardInfos(idx)] = spcMSetupClockPLL (cardInfos(idx), 1000000, 0);  % clock output : enable = 1, disable = 0
            
            fprintf ('  Card%d: Sampling rate set to %.1f MHz\n', idx-1, cardInfos(idx).setSamplerate / 1000000);

            % ----- type dependent card setup -----
            switch cardInfos(idx).cardFunction
    
                % ----- analog acquistion card setup -----
                case mRegs('SPCM_TYPE_AI')
                    % ----- program all input channels to +/-1 V and 50 ohm termination (if it's available) -----
                    for i=0 : cardInfos(idx).maxChannels-1  
                        [success, cardInfos(idx)] = spcMSetupAnalogInputChannel (cardInfos(idx), i, 1000, 1, 0, 0);  
                        %setup for M3i card series including new features:
                        %[success, cardInfo] = spcMSetupAnalogPathInputCh (cardInfo, i, 0, 1000, 1, 0, 0, 0);  
                    end
                    
               % ----- digital acquisition card setup -----
                case { mRegs('SPCM_TYPE_DI'), mRegs('SPCM_TYPE_DIO') }
                    % ----- set all input channel groups, no 110 ohm termination ----- 
                    for i=0 : cardInfos(idx).DIO.groups-1
                        [success, cardInfos(idx)] = spcMSetupDigitalInput (cardInfos(idx), i, 0);
                    end
            end
        end
        
        % ----- 1st card is used as trigger master (un-comment the second line to have external trigger on card 0 -----
        [success, cardInfos(1)] = spcMSetupTrigSoftware (cardInfos(1), 0);  % trigger output : enable = 1, disable = 0
        %[success, cardInfos(1)] = spcMSetupTrigExternal (cardInfos(1), mRegs('SPC_TM_POS'), 0, 0, 1, 0);
        
        error = 0;
        syncEnableMask = bitshift (1, cardCount) - 1;
        syncClkMask = bitshift (1, (cardCount-1));
        
        % ----- sync setup, all card activated, last card is clock master -----
        error = error + spcm_dwSetParam_i32 (hSync, mRegs('SPC_SYNC_ENABLEMASK'), syncEnableMask);
        error = error + spcm_dwSetParam_i32 (hSync, mRegs('SPC_SYNC_CLKMASK'), syncClkMask);
        
        % ----- start the card and wait for ready with timeout of 5 seconds (5000 ms) -----
        error = error + spcm_dwSetParam_i32 (hSync, mRegs('SPC_TIMEOUT'), 5000);
        
        if error == 0
            
            % ----- set command flags -----
            commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));
            commandMask = bitor (commandMask, mRegs('M2CMD_CARD_WAITREADY'));
            
            fprintf ('\n  .... Acquisition startet for all cards\n');
        
            error = spcm_dwSetParam_i32 (hSync, mRegs('SPC_M2CMD'), commandMask);
            
            if errorCode == mErrors('ERR_TIMEOUT')
                fprintf ('  .............................. Timeout');
            else
                fprintf ('  ................. Sucessfully finished\n');
                
                analogDataIdx = 0;

                for idx = 1 : cardCount
                    
                    % ***** get analog input data *****
                    if cardInfos(idx).cardFunction == 1
                        
                        % ----- set dataType: 0 = RAW (int16), 1 = Amplitude calculated (float) -----
                        dataType = 0;
                        
                        % ----- In this example we only get the data of channel 0 of each analog card ----- 
                        [errorCode, Dat_Ch0] = spcm_dwGetData (cardInfos(idx).hDrv, 0, cardInfos(idx).setMemsize, cardInfos(idx).setChannels, dataType);
                                
                        analogDataIdx = analogDataIdx + 1;
                        Dat_Sync_Ch0 (analogDataIdx, 1 : cardInfos(idx).setMemsize) = Dat_Ch0 (1 : cardInfos(idx).setMemsize);
                    end    
                end
            end
        end
    end
end

% ***** plot the data of channel 0 for each analog sync card *****
for idx = 1 : analogDataIdx
    plot (Dat_Sync_Ch0(idx, 1 : length (Dat_Sync_Ch0)));
    hold on;
end
hold off;

% ***** close driver *****
if hSync ~= 0
    spcm_vClose (hSync);
end

for idx=1 : cardCount 
    spcMCloseCard (cardInfos(idx));
end
