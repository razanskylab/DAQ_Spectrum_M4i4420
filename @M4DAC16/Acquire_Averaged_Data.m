% File:     Acquire_Averaged_Data.m @ FastDAQ
% Author:   Urs Hofmann
% Date:     27. Mar 2018
% Mail:     urshofmann@gmx.net
% Version:  1.0

% Description: Function used to actually acquire averaged data based on the
% settings which have been done before. Actually just a wrapper for Acquire_Data

% Changelog: Switched from memorySamples to nSamples

function [acquiredAveragedData, acquiredData] = Acquire_Averaged_Data(dac, nAverages)

  acquiredData = zeros(nAverages, 2, dac.acquisitionMode.nSamples);
  for iAverage = 1:nAverages
    acquiredData(iAverage, :, :) = dac.Acquire_Data();
  end

  acquiredAveragedData = squeeze(mean(acquiredData,1));

end
