% File: Setup_All_Channels.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% NOTE adapted from Urs
% FIXME Does not set the input path, should be replaced with spcMSetupAnalogPathInputCh

function Setup_All_Channels(Obj,channels)
  if ~Obj.beSilent
    Obj.VPrintF_With_ID('Setting up all channels.\n');
  end

  % check if size of both arrays aggree
  if (size(channels) == size(Obj.channels))

    % Set all channels
    for (i= 0 : (Obj.NO_CHANNELS - 1))
      [success, Obj.cardInfo] = ...
        spcMSetupAnalogInputChannel(...
          Obj.cardInfo, ...
          i, ... % channel
          channels(i+1).inputrange, ... % input range in mV
          channels(i+1).term, ... % term
          channels(i+1).inputoffset, ... % inputOffset
          channels(i+1).diffinput); % diffInput

      if (success == 0)
        error(['[DAC] Could not set channel ', num2str(i), '.']);
      end
    end
  else
    error('[DAC] Number of channels have to aggree.');
  end

end
