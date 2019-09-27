%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 11/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMCalcDigitalSignal:
% Calculates a digital signal (counter)
%**************************************************************************

function [success, signal] = spcMCalcDigitalSignal (len, channels)
    
    switch channels
        
        case { 1, 2, 4, 8, 16 }
            % 0 ... 15
            signal (1:1:len) = 1:len;
        
        case 32
            % 0 ... 15
            signal (1:2:2*len) = 1:len;
            
            % 16 ... 31
            signal (2:2:2*len) = 1:len;
            
        case 64 
            % 0 ... 15
            signal (1:4:4*len) = 1:len;
            
            % 16 ... 31
            signal (3:4:4*len) = 1:len;
            
            % 32 ... 47
            signal (2:4:4*len) = 1:len;
            
            % 48 ... 63
            signal (4:4:4*len) = 1:len;
    end
    
    success = true;
    