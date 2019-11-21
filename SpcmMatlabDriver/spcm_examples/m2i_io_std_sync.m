%**************************************************************************
%
% io_std_sync.m                               (c) Spectrum GmbH , 10/2015
%
%**************************************************************************
%
% Example for all SpcMDrv based (M2i) acquisition or generator cards. 
% Shows the synchronization of one or more analog acquistion or generator cards.
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

AICardsCount = 0;
AOCardsCount = 0;

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
        if bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_STARHUB5')) | bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_STARHUB16'))
            starhubFound = true;
            fprintf ('Starthub found\n');
        end
        
        switch cardInfo.cardFunction
            
            % ----- store all info structs of analog input cards -----
            case 1
                AICardsInfos (AICardsCount+1) = cardInfo;
                AICardsCount = AICardsCount + 1;
                    
            % ----- store all info structs of analog output cards ----- 
            case 2
                AOCardsInfos (AOCardsCount+1) = cardInfo;
                AOCardsCount = AOCardsCount + 1;
        end
    end 
end        

% ----- printf info of all analog input cards -----
for idx = 1 : AICardsCount 
    cardInfoText = spcMPrintCardInfo (AICardsInfos(idx));
    fprintf ('\nCard%d:\n', idx-1);
    fprintf (cardInfoText);
end

% ----- printf info of all analog output cards -----
for idx = 1 : AOCardsCount 
    cardInfoText = spcMPrintCardInfo (AOCardsInfos(idx));
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
            fprintf ('  Card Idx %d is', idx);
            if cable ~= -1
                fprintf (' connected on cable %d\n', cable);
            else
                fprintf (' not connected with the star-hub\n');
            end
        end
        fprintf ('\n');
        
        % ----- all analog input cards got a similar setup -----
        for idx = 1 : AICardsCount
            
            % ----- standard single, one channel, memsize 64k -----    
            [success, AICardsInfos(idx)] = spcMSetupModeRecStdSingle (AICardsInfos(idx), 0, 1, 64 * 1024, 64 * 1024 - 128);
            
            % ----- we try to set the samplerate to 10 MHz on internal PLL, no clock output -----
            [success, AICardsInfos(idx)] = spcMSetupClockPLL (AICardsInfos(idx), 10000000, 0);  % clock output : enable = 1, disable = 0
            
            fprintf ('  Card%d: Sampling rate set to %.1f MHz\n', idx-1, AICardsInfos(idx).setSamplerate / 1000000);
            
            % ----- program all input channels to +/-1 V and 50 ohm termination (if it's available) -----
            for i=0 : AICardsInfos(idx).maxChannels-1  
                [success, AICardsInfos(idx)] = spcMSetupAnalogInputChannel (AICardsInfos(idx), i, 1000, 1, 0, 0);  
                %setup for M3i card series including new features:
                %[success, cardInfo] = spcMSetupAnalogPathInputCh (cardInfo, i, 0, 1000, 1, 0, 0, 0);  
            end
        end
        
        % ----- all analog output cards got a similar setup -----
        for idx = 1 : AOCardsCount
            
            % ----- singleshot replay, one channel, memsize 64k -----
            [success, AOCardsInfos(idx)] = spcMSetupModeRepStdSingle (AOCardsInfos(idx), 0, 1, 64 * 1024);
            
            % ----- we try to set the samplerate to 10 MHz on internal PLL, no clock output -----
            [success, AOCardsInfos(idx)] = spcMSetupClockPLL (AOCardsInfos(idx), 10000000, 0);  % clock output : enable = 1, disable = 0

            fprintf ('  Card%d: Sampling rate set to %.1f MHz\n', idx-1, AOCardsInfos(idx).setSamplerate / 1000000);
            
             % ----- program all output channels to +/- 1 V with no offset and no filter -----
            for i=0 : AOCardsInfos(idx).maxChannels-1  
                [success, AOCardsInfos(idx)] = spcMSetupAnalogOutputChannel (AOCardsInfos(idx), i, 1000, 0, 0, mRegs('SPCM_STOPLVL_ZERO'), 0, 0); % doubleOut = disabled, differential = disabled
            end
        end 
        
        % ----- set trigger master -----
        if AICardsCount > 0
            triggerMasterInfo = AICardsInfos (1);
        else
            triggerMasterInfo = AOCardsInfos (1);
        end
        
        % ----- 1st card is used as trigger master (un-comment the second line to have external trigger on card 0 -----
        [success, triggerMasterInfo] = spcMSetupTrigSoftware (triggerMasterInfo, 0);  % trigger output : enable = 1, disable = 0
        %[success, triggerMasterInfo] = spcMSetupTrigExternal (triggerMasterInfo, mRegs('SPC_TM_POS'), 0, 0, 1, 0);
        
        % ----- set data for all analog output cards -----
        for idx = 1 : AOCardsCount
        
            % ----- ch0 = sine waveform -----
            [success, AOCardsInfos(idx), Dat_Ch0] = spcMCalcSignal (AOCardsInfos(idx), AOCardsInfos(idx).setMemsize, 1, 1, 100);
            
            errorCode = spcm_dwSetData (AOCardsInfos(idx).hDrv, 0, AOCardsInfos(idx).setMemsize, AOCardsInfos(idx).setChannels, 0, Dat_Ch0);
        end
        
        error = 0;
        syncEnableMask = bitshift (1, cardCount) - 1;

        % ----- sync setup, all card activated, last card is clock master -----
        error = error + spcm_dwSetParam_i32 (hSync, mRegs('SPC_SYNC_ENABLEMASK'), syncEnableMask);
        
        % ----- set first card as clock master ----- 
        error = error + spcm_dwSetParam_i32 (hSync, mRegs('SPC_SYNC_CLKMASK'), 1);
        
        % ----- start the card and wait for ready with timeout of 5 seconds (5000 ms) -----
        error = error + spcm_dwSetParam_i32 (hSync, mRegs('SPC_TIMEOUT'), 5000);
        
        if error == 0
            
            % ----- set command flags -----
            commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));
            commandMask = bitor (commandMask, mRegs('M2CMD_CARD_WAITREADY'));
            
            fprintf ('\n  .... Acquisition and replay started for all cards\n');
        
            error = spcm_dwSetParam_i32 (hSync, mRegs('SPC_M2CMD'), commandMask);
            
            if error == mErrors('ERR_TIMEOUT')
                fprintf ('  .............................. Timeout');
            else
                fprintf ('  ................. Sucessfully finished\n');
                
                analogDataIdx = 0;

                for idx = 1 : AICardsCount
                    
                    % ***** get analog input data *****
                    
                    % ----- set dataType: 0 = RAW (int16), 1 = Amplitude calculated (float) -----
                    dataType = 0;
                        
                    % ----- In this example we only get the data of channel 0 of each analog card ----- 
                    [errorCode, Dat_Ch0] = spcm_dwGetData (AICardsInfos(idx).hDrv, 0, AICardsInfos(idx).setMemsize, AICardsInfos(idx).setChannels, dataType);
                                
                    analogDataIdx = analogDataIdx + 1;
                    Dat_Sync_Ch0 (analogDataIdx, 1 : AICardsInfos(idx).setMemsize) = Dat_Ch0 (1 : AICardsInfos(idx).setMemsize);
                end
            end
        end
    end
end

% ***** plot the data of channel 0 for each analog sync card *****
for idx = 1 : AICardsCount
    plot (Dat_Sync_Ch0(idx, 1 : length (Dat_Sync_Ch0)));
    hold on;
end
hold off;

% ***** close driver *****
if hSync ~= 0
    spcm_vClose (hSync);
end

for idx=1 : AICardsCount 
    spcMCloseCard (AICardsInfos(idx));
end

for idx=1 : AOCardsCount 
    spcMCloseCard (AOCardsInfos(idx));
end
 
