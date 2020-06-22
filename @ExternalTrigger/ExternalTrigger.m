% File: ExternalTrigger.m @ ExternalTrigger
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 26.05.2020

% Description: defines the structure of an external trigger

% TODO: check all sets for correct values before passing them on to class

classdef ExternalTrigger < handle

	properties
		extMode(1, 1) = 1;
		% trigger type
		% 1 means trigger detection for rising edges
  	% 2 means trigger detection for falling edges
  	% 4 means trigger detection for rising and falling edges

		trigTerm(1, 1) logical = 1;
		% should we terminate trigger channel?
		% 1: 50 ohm termination
		% 0: 1 MOhm termination

		pulseWidth(1, 1) = 0;

		singleSrc(1, 1) = 1;
		
		extLine(1, 1) = 0;
	 	% defines the trigger line
	 	% 0: sma
	 	% 1: MMCX

	 	extLevel(1, 1) = 2500;
	 	% trigger level [mV]

	 	acCoupling(1, 1) = 0;
	end

end