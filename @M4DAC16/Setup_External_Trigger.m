% File: Setup_External_Trigger.m @ FastObj

% Info From Matlab Manual 
% [success, cardInfo] = spcMSetupTrigExternal(cardInfo, extMode, trigTerm, ...
%     pulsewidth, singleSrc, extLine);
% Programs the external trigger mode. 
% - „extMode“ value must contain a valid external mode as described in the 
% hardware manual.
% = „trigTerm“ flag defines whether to terminate the trigger 
% „pulsewidth“ value programs the pulsewidth for any external trigger
% mode that uses a pulsewidth counter. 
% - if „singleSrc“ flag is set the external trigger is the only trigger source 
% and all other trigger sources are disabled.
% When not programming the „singleSrc“ flag it is necessary to program the
%  OR and AND mask manually allowing to combine several trigger sources. 
% - „extLine“ parameter allows to select different possible TTL sources, 
% if available on the particular card.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup external TTL trigger
% extModes:
% 1 = SPC_TM_POS = trigger detection for positive edges
% 2 = SPC_TM_NEG = Trigger detection for negative edges
% 4 = SPC_TM_BOTH = Trigger detection for negative edges

% trigTerm:
% 1 = 50 Ohm termination for external trigger signals
% 0 = sets the high impedance termination (1kOhm on ext0, 10kOhm on ext1)

% extLine
% (0 is big sma, 1 is small MMCX connector)

function Setup_External_Trigger(Obj, triggerSetup)

  Obj.VPrintF_With_ID('Setting up the external trigger.\n')

  [setupFailed, Obj.cardInfo] = spcMSetupTrigExternal(...
    Obj.cardInfo, ...
    triggerSetup.extMode, ...  % 40510 = SPC_TRIG_EXT0_MODE
    triggerSetup.trigTerm, ... % 40110 = SPC_TRIG_TERM
    triggerSetup.pulseWidth, ... % 44210 = SPC_TRIG_EXT0_PULSEWIDTH
    triggerSetup.singleSrc, ... % sets masks if single source is activated
    triggerSetup.extLine); %  % defines the trigger line (0 is big sma, 1 is small MMCX connector)

  if setupFailed
    short_warn('   Could not set up the external trigger correctly.');
  end

end
