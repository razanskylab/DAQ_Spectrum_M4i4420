% File: Setup_External_Trigger_Level.m @ FastDAQ
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup external TTL trigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% extModes:
% 1 = SPC_TM_POS = trigger detection for positive edges
% 2 = SPC_TM_NEG = Trigger detection for negative edges
% 4 = SPC_TM_BOTH = Trigger detection for negative edges

% trigTerm:
% 1 = 50 Ohm termination for external trigger signals
% 0 = sets the high impedance termination (1kOhm on ext0, 10kOhm on ext1)

% extLine
% (0 is big sma, 1 is small MMCX connector)

function Setup_External_Trigger_Level(DAQ,triggerSetup)

  if ~DAQ.beSilent
    fprintf('[M4DAC16] Setting up the external trigger level.\n')
  end
% spcMSetupTrigExternalLevel (cardInfo,
  %   extMode, level0, level1, trigTerm, ACCoupling, pulsewidth, singleSrc, extLine)


  [success, DAQ.cardInfo] = spcMSetupTrigExternalLevel(...
    DAQ.cardInfo, ...
    triggerSetup.extMode, ...  % 40510 = SPC_TRIG_EXT0_MODE
    triggerSetup.extLevel, ...  % 42320 = SPC_TRIG_EXT0_LEVEL0
    triggerSetup.extLevel, ...  % 42330 = SPC_TRIG_EXT0_LEVEL1
    triggerSetup.trigTerm, ... % 40110 = SPC_TRIG_TERM
    triggerSetup.acCoupling, ...  % 40120 = SPC_TRIG_EXT0_ACDC
    triggerSetup.pulseWidth, ... % 44210 = SPC_TRIG_EXT0_PULSEWIDTH
    triggerSetup.singleSrc, ... % sets masks if single source is activated
    triggerSetup.extLine); %  % defines the trigger line (0 is big sma, 1 is small MMCX connector)

  if ~success
    short_warn('[M4DAC16] Could not set up the external trigger correctly.');
  end

end
