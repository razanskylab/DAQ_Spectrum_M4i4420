DAQ.Connect(); % need to connect and disconnect before/after fifo
DAQ.Reset(); % always good to start with a clean slate...

%% ---------------------------------------------------------------------------
DAQ.FiFo = FiFoSettings();
DAQ.FiFo.nShots = 1000; % number of shots to be acquired in total
DAQ.FiFo.shotSize = 2048; % needs to be 512 + n*16
DAQ.FiFo.shotSizePd = 280; % cropped, so can be any value
DAQ.FiFo.nChannels = 2; % one channel not tested...
DAQ.timeout = 1000; % fairly short timeout...we don't have time for this shite....
DAQ.FiFo.Set_shotsPerNotify(); %

% trigger and channel settings
TriggerSettings.extMode = 1;  % 1 = rising, 2 = falling, 4 = both
TriggerSettings.trigTerm = 1;
  % SPC_TRIG_TERM, 1 = 50 Ohm, 0 = high impedance
TriggerSettings.pulseWidth = 0;
TriggerSettings.singleSrc = 1;
TriggerSettings.extLine = 0;
TriggerSettings.extLevel = 2000; % [mV] set trigger level to 2 V
TriggerSettings.acCoupling = 0; % 0 = DC coupling, 1 = AC coupling

% channel settings ---------------------------------------------------------
% 0 = buffered, 50 ohm or 1 Mohm term;  1 = HF, 50 ohm term;
% inputrange = input ranges
  % HF Path:       ±500 mV, ±1000 mV, ±2500 mV, ±5000 mV
  % Buffered Path: ±200 mV, ±500 mV, ±1000 mV, ±2000 mV, ±5000 mV, ±10000 mV
% term = termination
  % 1 = 50 Ohm
  % 0 = high impedance (only when path = 0)

PdSettings.path = 1; % 0 = buffered, 50 ohm or 1 Mohm term;  1 = HF, 50 ohm term;
PdSettings.inputrange = 5000; % ±500 mV, ±1000 mV, ±2500 mV, ±5000 mV
PdSettings.term = 1;
PdSettings.acCpl = 0;
PdSettings.inputoffset = 0;
PdSettings.bwLim = 0;

UsSettings.path = 1; % 0 = buffered, 50 ohm or 1 Mohm term;  1 = HF, 50 ohm term;
UsSettings.inputrange = 5000; % ±500 mV, ±1000 mV, ±2.5000 mV, ±5000 mV
UsSettings.term = 1; % 1 = 50 Ohm, 0 = high impedance (only when path = )
UsSettings.acCpl = 0;
UsSettings.inputoffset = 0;
UsSettings.bwLim = 0;

DAQ.Setup_External_Trigger_Level(TriggerSettings); % (0 is big sma, 1 is small MMCX connector)
DAQ.Setup_Analog_Input_Channel(0, UsSettings);
DAQ.Setup_Analog_Input_Channel(1, PdSettings);

%% ---------------------------------------------------------------------------
DAQ.delay = 0; % adjust as needed

% DO NOT CHANGE THE ORDER OF THESE THREE COMMANDS!
DAQ.Enable_Time_Stamps(); % needs to be before start
% haven't enabled the trigger yet, this comes last before we start moving

%% ---------------------------------------------------------------------------
fprintf('[FOAM] Allocating memory for raw data...');
ch0Raw = zeros(DAQ.FiFo.shotSize, DAQ.FiFo.nShots, 'int16');
ch1Raw = zeros(DAQ.FiFo.shotSizePd, DAQ.FiFo.nShots, 'int16');


for i=1:10
	DAQ.Setup_FIFO_Multi_Mode();
	DAQ.Start(); % now settings can't be changed anymore, but trigger not activated yet!
	DAQ.Enable_Trigger(); % can be with start (Full_Start) or after but NOT before
	[ch0Raw, ch1Raw, tS] = DAQ.Acquire_Multi_FIFO_Data_Minimal(ch0Raw,ch1Raw);
	DAQ.Stop();
	DAQ.Free_FIFO_Buffer();
end



DAQ.Close_Connection(); % seems required, otherwise triggering is weird...
