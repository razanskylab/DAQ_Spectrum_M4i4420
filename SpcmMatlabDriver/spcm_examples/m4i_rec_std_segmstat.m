%**************************************************************************
%
% rec_std_segmstat.m                           (c) Spectrum GmbH, 10/2015
%
%**************************************************************************
%
% Example for all (M4i) acquisition cards with the option
% Segment Statistic installed
%
% Shows standard data acquistion using Segment Statistic mode. 
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
if (bitand (cardInfo.extFeatureMap, mRegs('SPCM_FEAT_EXTFW_SEGSTAT')) == 0)
    spcMErrorMessageStdOut (cardInfo, 'Error: Segment Statistic Option not installed. Examples was done especially for this option!\n', false);
    return;
else
    fprintf ('\n Segment Statistic Option ........ installed.');
end 

% ***** do card setup *****
segmentSize   = 8192;
posttrigger   = 2048;
numOfSegments = 16;

memSize = numOfSegments * segmentSize;

% ----- set channel mask for max channels -----
chMaskH = 0;
chMaskL = bitshift (1, cardInfo.maxChannels) - 1;

% ----- standard segment statistic, all channels, memSize, segmentSize, posttrigger -----    
[success, cardInfo] = spcMSetupModeRecStdSegmStat (cardInfo, chMaskH, chMaskL, memSize, segmentSize, posttrigger);
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

% ----- enable channel trigger, channel0, mode = SPC_TM_POS, level = 100 mV -----
[success, cardInfo] = spcMSetupTrigChannel (cardInfo, 0, mRegs('SPC_TM_POS'), 100, 0, 0, 0, 1);
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

[success, cardInfo] = spcMSetupTimestamp (cardInfo, mRegs('SPC_TSMODE_STARTRESET'), 0);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTimestamp:\n\t', true);
    return;
end

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
    
    switch cardInfo.setChannels
        
        case 1
            % ----- get the whole data for one channel with offset = 0 ----- 
            [errorCode, StatisDat_Ch0] = spcm_dwGetSegmentStatisticData (cardInfo.hDrv, numOfSegments, cardInfo.setChannels);
        case 2
            % ----- get the whole data for two channels with offset = 0 ----- 
            [errorCode, StatisDat_Ch0, StatisDat_Ch1] = spcm_dwGetSegmentStatisticData (cardInfo.hDrv, numOfSegments, cardInfo.setChannels);
        case 4
            % ----- get the whole data for four channels with offset = 0 ----- 
            [errorCode, StatisDat_Ch0, StatisDat_Ch1, StatisDat_Ch2, StatisDat_Ch3] = spcm_dwGetSegmentStatisticData (cardInfo.hDrv, numOfSegments, cardInfo.setChannels);
    end
   
    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetData:\n\t', true);
        return;
    end
    
end

% ***** close card *****
spcMCloseCard (cardInfo);

% ***** plot statistic data *****
fprintf ('\n\n----- Segment Statistic Channel 0 -----\n');
spcMPlotSegmentStatisticData (StatisDat_Ch0, numOfSegments);
if cardInfo.setChannels > 1
    fprintf ('\n\n----- Segment Statistic Channel 1 -----\n');
    spcMPlotSegmentStatisticData (StatisDat_Ch1, numOfSegments);
end
if cardInfo.setChannels > 2
    fprintf ('\n\n----- Segment Statistic Channel 2 -----\n');
    spcMPlotSegmentStatisticData (StatisDat_Ch2, numOfSegments);
    fprintf ('\n\n----- Segment Statistic Channel 3 -----\n');
    spcMPlotSegmentStatisticData (StatisDat_Ch3, numOfSegments);
end
