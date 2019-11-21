%**************************************************************************
% Spectrum Matlab Library Package             (c) Spectrum GmbH, 11/2014
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMPlotSegmentStatisticData
% plots digital data given by the DigData matrix
%**************************************************************************

function spcMPlotSegmentStatisticData (SegmStatData, numOfSegments)
    
    numOfSegmStatValues = 6;

    segmentIdx = 1;
    segmentDataIdx = 1;
    
    while segmentDataIdx < numOfSegments * numOfSegmStatValues
        fprintf ('Segment %d : Average = %d, Min = %d, Max = %d, MinPos = %d, MaxPos = %d, Timestamp = %d\n', segmentIdx, SegmStatData(segmentDataIdx), SegmStatData(segmentDataIdx + 1), SegmStatData(segmentDataIdx + 2), SegmStatData(segmentDataIdx + 3), SegmStatData(segmentDataIdx + 4), SegmStatData(segmentDataIdx + 5));
        
        segmentIdx = segmentIdx + 1;
        segmentDataIdx = segmentDataIdx + numOfSegmStatValues;
    end