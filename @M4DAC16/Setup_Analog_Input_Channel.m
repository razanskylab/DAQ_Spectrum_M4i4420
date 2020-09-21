% File: Setup_Channel.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

function Setup_Analog_Input_Channel(Obj, channel, settings)
  tic;
  Obj.VPrintF_With_ID('Setting up channel %i...',channel);

  % input ranges of path 0 (Buffered):
    % 200 =   ± 200 mV calibrated input range
    % 500 =   ± 500 mV calibrated input range
    % 1000 =  ± 1 V calibrated input range
    % 2000 =  ± 2 V calibrated input range
    % 5000 =  ± 5 V calibrated input range
    % 10000 = ± 10 V calibrated input range

  % input ranges of path 1 (HF, 50 ohm terminated):
    % 500   = ± 500 mV calibrated input range
    % 1000  = ± 1 V calibrated input range
    % 2500  = ± 2.5 V calibrated input range
    % 5000  = ± 5 V calibrated input range

  % if settings.path && settings.term
  %   settings.term = 0;
  %   short_warn('[M4DAC16] Must set term=0 for path=1 (fixed 50ohm term)!')
  % end

  % make sure we try to set channel that actually exist...
  if channel <= Obj.cardInfo.maxChannels-1
    [success, Obj.cardInfo] = spcMSetupAnalogPathInputCh(...
                                  Obj.cardInfo, ...
                                  channel,                      ... % channel
                                  settings.path,   ... % input range in mV
                                  settings.inputrange,   ... % input range in mV
                                  settings.term,         ... % term
                                  settings.acCpl,  ... % inputOffset
                                  settings.bwLim,  ... %
                                  0);       % diffInput

    if ~success
      spcMErrorMessageStdOut(Obj.cardInfo, 'Error: spcMSetupInputChannel:\n\t', true);
      error(['[M4DAC16] Could not set channel ', num2str(channel), '.']);
    else
      Obj.Done();
    end
  else
    error('[M4DAC16] Number of channels have to aggree.');
  end
end
