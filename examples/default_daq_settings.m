function [TriggerSettings, PdSettings, UsSettings] = default_daq_settings(mode)
  if nargin == 0
    mode = 'default';
  end

  switch mode
  case 'default'
    % trigger settings
    TriggerSettings.extMode = 1;  % 1 = rising, 2 = falling, 4 = both
    TriggerSettings.trigTerm = 1;
      % SPC_TRIG_TERM, 1 = 50 Ohm, 0 = high impedance
    TriggerSettings.pulseWidth = 0;
    TriggerSettings.singleSrc = 1;
    TriggerSettings.extLine = 0;
    TriggerSettings.extLevel = 2000; % [mV] set trigger level to 2.5 V
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
    PdSettings.acCpl = 1;
    PdSettings.inputoffset = 0;
    PdSettings.bwLim = 0;

    UsSettings.path = 0; % 0 = buffered, 50 ohm or 1 Mohm term;  1 = HF, 50 ohm term;
    UsSettings.inputrange = 5000; % ±500 mV, ±1000 mV, ±2.5000 mV, ±5000 mV
    UsSettings.term = 1; % 1 = 50 Ohm, 0 = high impedance (only when path = )
    UsSettings.acCpl = 1;
    UsSettings.inputoffset = 0;
    UsSettings.bwLim = 0;
  end

end
