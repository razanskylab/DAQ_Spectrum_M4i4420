%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 03/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMPrintCardInfo:
% prints the card information to a string for display.
%**************************************************************************

function [cardInfoText] = spcMPrintCardInfo (cardInfo)

    family = bitshift (cardInfo.cardType, -16);
    type = bitand (cardInfo.cardType, 65535); 
    
    cardInfoText = sprintf ('unknown %x sn %05d\n', cardInfo.cardType, cardInfo.serialNumber);
    switch (family)
        case 3 % M2i family
             cardInfoText = sprintf ('M2i.%04x sn %05d\n', type, cardInfo.serialNumber);
        case 4 % M2i-Express family
             cardInfoText = sprintf ('M2i.%04x-Exp sn %05d\n', type, cardInfo.serialNumber);
        case 5 % M3i family
             cardInfoText = sprintf ('M3i.%04x sn %05d\n', type, cardInfo.serialNumber);
        case 6 % M3i-Express family
             cardInfoText = sprintf ('M3i.%04x-Exp sn %05d\n', type, cardInfo.serialNumber);
        case 7 % M4i family
            cardInfoText = sprintf ('M4i.%04x- sn %05d\n', type, cardInfo.serialNumber);
        case 8 % M4x family
            cardInfoText = sprintf ('M4x.%04x-x4 sn %05d\n', type, cardInfo.serialNumber);
        case 9 % M2p family
            cardInfoText = sprintf ('M2p.%04x-x4 sn %05d\n', type, cardInfo.serialNumber);
    end
    
    textTmp = sprintf (' Installed memory:  %d MByte\n', cardInfo.instMemBytes / 1024 / 1024);
    cardInfoText = [cardInfoText, textTmp];
    
    textTmp = sprintf (' Max sampling rate: %.1f MS/s\n', cardInfo.maxSamplerate / 1000000);
    cardInfoText = [cardInfoText, textTmp];
    
    textTmp = sprintf (' Channels:          %d\n', cardInfo.maxChannels);
    cardInfoText = [cardInfoText, textTmp];
    
    major = bitshift (cardInfo.kernelVersion, -24);
    minor = bitand (bitshift (cardInfo.kernelVersion, -16), 255);   
    build = bitand (cardInfo.kernelVersion, 65535);
    textTmp = sprintf (' Kernel Version:    %d.%d build %d\n', major, minor, build);
    cardInfoText = [cardInfoText, textTmp];
    
    major = bitshift (cardInfo.libVersion, -24);
    minor = bitand (bitshift (cardInfo.libVersion, -16), 255);   
    build = bitand (cardInfo.libVersion, 65535);
    textTmp = sprintf (' Library Version:   %d.%d build %d\n', major, minor, build);
    cardInfoText = [cardInfoText, textTmp];
    
    
    
    
    
    
        
    
    

    
    
    
    
    
    
    
    
    
    
    
    
    
    
