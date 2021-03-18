% File: unit_test_dac.m
% Author: Urs Hofmamm
% Mail: hofmannu@ethz.ch
% Date: 09.02.2021

% Description: checks the basic functionality of the dac


M = M4DAC16();

% check different device set and get functions
M.timeout
M.timeout = 10e3;

M.dataType = 1;
M.dataType = 0;
M.dataType

M.isConnected

M.sensitivity

M.triggerLevel

clear M;