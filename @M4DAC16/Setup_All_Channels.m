% File: Setup_All_Channels.m @ FastDAQ
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% NOTE adapted from Urs
% FIXME Does not set the input path, should be replaced with spcMSetupAnalogPathInputCh

function Setup_All_Channels(DAQ,channels)
  if ~DAQ.beSilent
    DAQ.VPrintF('[M4DAC16] Setting up all channels.\n');
  end

  % check if size of both arrays aggree
  if (size(channels) == size(DAQ.channels))

    % Set all channels
    for (i= 0 : (DAQ.NO_CHANNELS - 1))
      [success, DAQ.cardInfo] = ...
        spcMSetupAnalogInputChannel(...
          DAQ.cardInfo, ...
          i, ... % channel
          channels(i+1).inputrange, ... % input range in mV
          channels(i+1).term, ... % term
          channels(i+1).inputoffset, ... % inputOffset
          channels(i+1).diffinput); % diffInput

      if (success == 0)
        error(['[M4DAC16] Could not set channel ', num2str(i), '.']);
      end
    end
  else
    error('[M4DAC16] Number of channels have to aggree.');
  end

end
