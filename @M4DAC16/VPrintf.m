% File: VPrintf.m @ M4DAC16
% Author: Urs Hofmann
% Mail: hofmannu@ethz.ch

% Print output of command only if flagVerbose is enabled

function VPrintf(dac, varargin)

	if dac.flagVerbose
  	fprintf(varargin{:});
  	drawnow;
  end

end