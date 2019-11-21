%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 11/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMPlotDigitalData
% plots digital data given by the DigData matrix
%**************************************************************************

function spcMPlotDigitalData (DigData, channels, samplesToPlot)
    
    for chIdx=1 : channels
        
        % ----- create buffers for x and y values -----
        plotData = zeros (1, samplesToPlot);
        timeData = zeros (1, samplesToPlot);
    
        % ----- set y axe offset -----
        high = 7.5 + (chIdx-1) * 7;
        low  = 2.5 + (chIdx-1) * 7;
    
        
        % ----- calculate x and y values of plotting data -----
        plotIdx = 2;
        timeVal = 1;
    
        sample = DigData (chIdx, 1);
    
        if sample == 1
            plotData (1, 1) = high;
        else
            plotData (1, 1) = low;
        end
    
        timeData (1, 1) = 0;
      
        for dataIdx=2 : samplesToPlot
            sample = DigData (chIdx, dataIdx);
            if sample == 1
                sample = high;
            else
                sample = low;
            end
        
            if sample ~= plotData (1, plotIdx-1)
                plotData (1, plotIdx) = plotData (1, plotIdx-1);
                timeData (1, plotIdx) = timeVal;
                plotIdx = plotIdx + 1;
            
                plotData (1, plotIdx) = sample;
                timeData (1, plotIdx) = timeVal;
                plotIdx = plotIdx + 1;
                timeVal = timeVal + 1;
            else
                plotData (1, plotIdx) = sample;
                timeData (1, plotIdx) = timeVal;
                plotIdx = plotIdx + 1;
                timeVal = timeVal + 1;
            end
        end
        
        % ----- plot calculated data -----
        plot (timeData, plotData);
        if chIdx == 1
            hold on;
        end
        
        % ----- clear memory -----
        clear timeData;
        clear plotData;
    end
    
    hold off;

    
        
           