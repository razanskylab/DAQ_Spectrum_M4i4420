[TriggerSettings, PdSettings, UsSettings] = default_daq_settings();

DAQ = M4DAC16(0); % not connected jet, just created DAQ object

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DAQ.Connect(); % connect and reset

% Transfer / Apply Settings to card, setup trigger and analog inputs
[TriggerSettings, PdSettings, UsSettings] = default_daq_settings('default');
DAQ.Setup_External_Trigger_Level(TriggerSettings); % (0 is big sma, 1 is small MMCX connector)
DAQ.Setup_Analog_Input_Channel(0,UsSettings);
DAQ.Setup_Analog_Input_Channel(1,PdSettings);
DAQ.delay = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DAQ.FiFo = FiFoSettings();
DAQ.FiFo.nShots = 1000;
DAQ.FiFo.shotSize = 1024; % size of one shot...
DAQ.FiFo.shotSizePd = 1024; % size of one shot...
DAQ.FiFo.nChannels = 2;
DAQ.FiFo.Set_shotsPerNotify(); % fairly short timeout...we don't have time for this shite....
% DO NOT CHANGE THE ORDER OF THESE THREE COMMANDS!
DAQ.Enable_Time_Stamps(); % needs to be before start
DAQ.Setup_FIFO_Multi_Mode();
DAQ.Start(); % now settings can't be changed anymore, but trigger not activated yet!
% haven't enabled the trigger yet, this comes last before we start moving
DAQ.Enable_Trigger(); % can be with start (Full_Start) or after but NOT before

usRaw = zeros(DAQ.FiFo.shotSize,DAQ.FiFo.nShots,'int16');
pdRaw = zeros(DAQ.FiFo.shotSizePd,DAQ.FiFo.nShots,'int16');

[usRaw,pdRaw] = DAQ.Acquire_Multi_FIFO_Data(usRaw,pdRaw);
