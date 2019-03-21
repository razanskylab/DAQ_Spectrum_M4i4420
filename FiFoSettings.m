classdef FiFoSettings

  properties
    shotSize(1,1)       {mustBeInteger,mustBeNonnegative} = 1024*1; % size of on shot...
    shotsPerNotify(1,1) {mustBeInteger,mustBeNonnegative} = 5;
    shotsinBuffer(1,1)  {mustBeInteger,mustBeNonnegative} = 1024; % NOTE play with this for better performance if needed?
    notifySizeTS(1,1)   {mustBeInteger,mustBeNonnegative} = 4096; % 4 kBytes
    dataType(1,1)       {mustBeInteger,mustBeNonnegative} = 0; % 0 = RAW (int16), 1 = float
    nChannels(1,1)      {mustBeInteger,mustBeNonnegative} = 0; % 1/2
  end

  properties (Constant)
    PRE_TRIGGER_SAMPLES = 16; %% min = 16, step size = 16
  end

  properties (Dependent = true)
    postSamples;
  end

  % set / get functions
  methods % get functions for depended properties
    function postSamples = get.postSamples(FS)
      postSamples = FS.shotSize - PRE_TRIGGER_SAMPLES; %% min allowed!
    end

  end

  methods % set/get functions to check valid configuration
    % function postSamples = get.postSamples(FS)
    %   postSamples = FS.shotSize - 16; %% min allowed!
    % end
  end

end
