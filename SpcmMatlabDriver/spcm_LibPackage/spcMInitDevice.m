%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH, 04/2015
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMInitDevice
% opens the device with the given string, reads out card information and
% returns a filled cardInfo structure
%**************************************************************************

function [success, cardInfo] = spcMInitDevice (deviceString)
    
    cardInfo.hDrv = spcm_hOpen (deviceString);
    
    if (cardInfo.hDrv == 0)
        [errorCode, errorReg, errorVal, cardInfo.errorText] = spcm_dwGetErrorInfo_i32 (cardInfo.hDrv);
        success = false;
        return;
    end
    
    cardInfo.setChannels     = 1;
    cardInfo.setSamplerate   = 1;
    cardInfo.setMemsize      = 0;
    cardInfo.setChEnableHMap = 0;
    cardInfo.setChEnableLMap = 0;
    cardInfo.oversampling    = 1;
    
    % read out card information and store it in the card info structure
    [errorCode, cardInfo.cardType]       = spcm_dwGetParam_i32 (cardInfo.hDrv, 2000);  % 2000 = SPC_PCITYP
    [errorCode, cardInfo.serialNumber]   = spcm_dwGetParam_i32 (cardInfo.hDrv, 2030);  % 2030 = SPC_SERIALNO
    [errorCode, cardInfo.featureMap]     = spcm_dwGetParam_i32 (cardInfo.hDrv, 2120);  % 2120 = SPC_PCIFEATURES
    [errorCode, cardInfo.extFeatureMap]  = spcm_dwGetParam_i32 (cardInfo.hDrv, 2121);  % 2121 = SPC_PCIEXTFEATURES
    [errorCode, cardInfo.instMemBytes]   = spcm_dwGetParam_i64 (cardInfo.hDrv, 2110);  % 2110 = SPC_PCIMEMSIZE
    [errorCode, cardInfo.minSamplerate]  = spcm_dwGetParam_i32 (cardInfo.hDrv, 1130);  % 1130 = SPC_MIINST_MINADCLOCK
    [errorCode, cardInfo.maxSamplerate]  = spcm_dwGetParam_i64 (cardInfo.hDrv, 1140);  % 1140 = SPC_MIINST_MAXADCLOCK
    [errorCode, cardInfo.modulesCount]   = spcm_dwGetParam_i32 (cardInfo.hDrv, 1100);  % 1100 = SPC_MIINST_MODULES  
    [errorCode, cardInfo.maxChannels]    = spcm_dwGetParam_i32 (cardInfo.hDrv, 1110);  % 1110 = SPC_MIINST_CHPERMODULE      
    [errorCode, cardInfo.bytesPerSample] = spcm_dwGetParam_i32 (cardInfo.hDrv, 1120);  % 1120 = SPC_MIINST_BYTESPERSAMPLE
    [errorCode, cardInfo.libVersion]     = spcm_dwGetParam_i32 (cardInfo.hDrv, 1200);  % 1200 = SPC_GETDRVVERSION
    [errorCode, cardInfo.kernelVersion]  = spcm_dwGetParam_i32 (cardInfo.hDrv, 1210);  % 1210 = SPC_GETKERNELVERSION

    % we need to recalculate the channels value as the driver returns channels per module
    cardInfo.maxChannels = cardInfo.maxChannels * cardInfo.modulesCount;
    
	% set family type
	cardInfo.isM2i = false;
	cardInfo.isM3i = false;
	cardInfo.isM4i = false;
	cardInfo.isM2p = false;
    
	switch bitand (cardInfo.cardType, 16711680) % 16711680 = TYP_SERIESMASK
	
		% TYP_M2ISERIES
		case 196608
			cardInfo.isM2i = true;
		% TYP_M2IEXPSERIES
		case 262144
			cardInfo.isM2i = true;
		% TYP_M3ISERIES
		case 327680
			cardInfo.isM3i = true;
		% TYP_M3IEXPSERIES
		case 393216
			cardInfo.isM3i = true;
		% TYP_M4IEXPSERIES
		case 458752
			cardInfo.isM4i = true;
        % TYP_M4XEXPSERIES    
        case 524288
            cardInfo.isM4i = true;
        % TYP_M2PEXPSERIES
        case 589824
            cardInfo.isM2p = true;
	end	
	
    % examin the type of driver
    [errorCode, cardInfo.cardFunction] = spcm_dwGetParam_i32 (cardInfo.hDrv, 2001);  % 2001 = SPC_FNCTYPE
    
    % loading the function dependant part of the CardInfo structure
    switch cardInfo.cardFunction
        
        % AnalogIn
        case 1
            [errorCode, cardInfo.AI.resolution] = spcm_dwGetParam_i32 (cardInfo.hDrv, 1125);  % 1125 = SPC_MIINST_BITSPERSAMPLE
            [errorCode, cardInfo.AI.pathCount] =  spcm_dwGetParam_i32 (cardInfo.hDrv, 3120);  % 3120 = SPC_READAIPATHCOUNT
            [errorCode, cardInfo.AI.rangeCount] = spcm_dwGetParam_i32 (cardInfo.hDrv, 3000);  % 3000 = SPC_READIRCOUNT
            
            i = 1;
            
            while (i <= cardInfo.AI.rangeCount) & (i <= 8)  % 8 = SPCM_MAX_AIRANGE   
                [errorCode, cardInfo.AI.rangeMin(i)] = spcm_dwGetParam_i32 (cardInfo.hDrv, 4000 + (i - 1));  % 4000 = SPC_READRANGEMIN0
                [errorCode, cardInfo.AI.rangeMax(i)] = spcm_dwGetParam_i32 (cardInfo.hDrv, 4100 + (i - 1));  % 4100 = SPC_READRANGEMAX0
                i = i + 1;
            end
            
            [errorCode, AIFeatures] = spcm_dwGetParam_i32 (cardInfo.hDrv, 3101);  % 3101 = SPC_READAIFEATURES
            
            if bitand (AIFeatures, 1) ~= 0  % 1 = SPCM_AI_TERM           
                cardInfo.AI.inputTermAvailable = 1; 
            else
                cardInfo.AI.inputTermAvailable = 0;
            end
                
            if bitand (AIFeatures, 4) ~= 0  % 4 = SPCM_AI_DIFF
                cardInfo.AI.diffModeAvailable = 1;
            else
                cardInfo.AI.diffModeAvailable = 0;
            end
                
            if  bitand (AIFeatures, 8) ~= 0  % 8 = SPCM_AI_OFFSPERCENT  
                cardInfo.AI.offsPercentMode = 1;
            else
                cardInfo.AI.offsPercentMode = 0;
            end
            
            if  bitand (AIFeatures, 128) ~= 0  % 0x80 = SPCM_AI_ACCOUPLING  
                cardInfo.AI.ACCouplingAvailable = 1;
            else
                cardInfo.AI.ACCouplingAvailable = 0;
            end

            if  bitand (AIFeatures, 256) ~= 0  % 0x100 = SPCM_AI_LOWPASS  
                cardInfo.AI.BWLimitAvailable = 1;
            else
                cardInfo.AI.BWLimitAvailable = 0;
            end
            
        % AnalogOut
        case 2
            
            [errorCode, cardInfo.AO.resolution] = spcm_dwGetParam_i32 (cardInfo.hDrv, 1125);  % 1125 = SPC_MIINST_BITSPERSAMPLE
            [errorCode, AOFeatures] = spcm_dwGetParam_i32 (cardInfo.hDrv,             3102);  % 3102 = SPC_READAOFEATURES
            
            if bitand (AOFeatures, 32) ~= 0 % 32 = SPCM_AO_PROGGAIN
                cardInfo.AO.gainProgrammable = 1;
            else
                cardInfo.AO.gainProgrammable = 0;
            end
            
            if bitand (AOFeatures, 16) ~= 0 % 16 = SPCM_AO_PROGOFFSET
                cardInfo.AO.offsetProgrammable = 1;
            else
                cardInfo.AO.offsetProgrammable = 0;
            end

            if bitand (AOFeatures, 8) ~= 0 % 8 = SPCM_AO_PROGFILTER
                cardInfo.AO.filterAvailable = 1;
            else
                cardInfo.AO.filterAvailable = 0;
            end
            
            if bitand (AOFeatures, 64) ~= 0 % 64 = SPCM_AO_PROGSTOPLEVEL
                cardInfo.AO.stopLevelProgrammable = 1;
            else
                cardInfo.AO.stopLevelProgrammable = 0;
            end
            
            if bitand (AOFeatures, 4) ~= 0 % 4 = SPCM_AO_DIFF
                cardInfo.AO.diffModeAvailable = 1;
            else
                cardInfo.AO.diffModeAvailable = 0;
            end
        
        % DigitalIn, DigitalOut, DigitalIO
        case { 4, 8, 16 }
            
            % Digital in
            if (cardInfo.cardFunction == 4) | (cardInfo.cardFunction == 16)
                [errorCode, DIFeatures] = spcm_dwGetParam_i32 (cardInfo.hDrv, 3103);  % 3103 = SPC_READDIFEATURES     
                
                [errorCode, cardInfo.DIO.groups] = spcm_dwGetParam_i32 (cardInfo.hDrv, 3110);  % 3110 = SPC_READCHGROUPING
                cardInfo.DIO.groups = cardInfo.maxChannels / cardInfo.DIO.groups;
                
                if bitand (DIFeatures, 1) ~= 0 % 1 = SPCM_DI_TERM
                    cardInfo.DIO.inputTermAvailable = 1;
                else
                    cardInfo.DIO.inputTermAvailable = 0;
                end
                
                if bitand (DIFeatures, 4) ~= 0 % 4 = SPCM_DI_DIFF
                    cardInfo.DIO.diffModeAvailable = 1;
                else
                    cardInfo.DIO.diffModeAvailable = 0;
                end
            end
            
            % Digital out
            if (cardInfo.cardFunction == 8) | (cardInfo.cardFunction == 16)
                [errorCode, DOFeatures] = spcm_dwGetParam_i32 (cardInfo.hDrv, 3103);  % 3103 = SPC_READDIFEATURES     
                
                if bitand (DOFeatures, 4) ~= 0 % 4 = SPCM_DO_DIFF
                    cardInfo.DIO.diffModeAvailable = 1;
                else
                    cardInfo.DIO.diffModeAvailable = 0;
                end
                
                if bitand (DOFeatures, 8) ~= 0 % 8 = SPCM_DO_PROGSTOPLEVEL
                    cardInfo.DIO.stopLevelProgrammable = 1;
                else
                    cardInfo.DIO.stopLevelProgrammable = 0;
                end
                
                if bitand (DOFeatures, 16) ~= 0 % 16 = SPCM_DO_PROGOUTLEVELS
                    cardInfo.DIO.outputLevelProgrammable = 1;
                else
                    cardInfo.DIO.outputLevelProgrammable = 0;
                end
            end
    end
    
    cardInfo.errorText = 'No Error';
    
    success = true;
           