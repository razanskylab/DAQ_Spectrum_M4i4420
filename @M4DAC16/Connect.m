% File: Connect.m @ FastDAQ
% Mail: johannesrebling@gmail.com

% Description: convenience function to have unified syntax
function Connect(DAQ)
  DAQ.Open_Connection();
  DAQ.Reset();

  channels = DAQ.channels();

  channels(1).inputrange = 10000; % [mV]
  channels(1).term = 1; % 1: 50 ohm termination, 0: 1MOhm termination
  channels(1).inputoffset = 0;
  channels(1).diffinput = 0;

  channels(2).inputrange = 10000; % [mV]
  channels(2).term = 1; % 1: 50 ohm termination, 0: 1MOhm termination
  channels(2).inputoffset = 0;
  channels(2).diffinput = 0;

  DAQ.channels = channels;
  %DAQ.externalTrigger = DAQ.externalTrigger;
  %DAQ.acquisitionMode = DAQ.acquisitionMode;
  %DAQ.delay = DAQ.delay;
  DAQ.samplingRate = DAQ.SAMPLING_RATE;
  DAQ.timeout = DAQ.TIME_OUT;
end
