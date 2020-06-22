% File: Channel.m @ Channel
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 26.05.2020

% Description: Defines the setup of a data acquisition channel

% TODO: include set functions for everything

classdef Channel < handle

	properties
		path(1, 1) = 0;
		% 0: buffered
		% 1: HF input with fixed 50 Ohm termiantion
		
		inputrange(1, 1)= 10e3;
		% sensitivity of channel [mV]

		term(1, 1) = 1;
		% 0: 50 Ohm termination
		% 1: 50 Ohm termiantion
		
		acCpl(1, 1) = 0;
		
		inputoffset(1, 1) = 0;
		
		bwLim(1, 1) = 0;
		
		diffinput(1, 1) = 0;
	end

end