classdef FiFoSettings

  properties
    nShots(1,1)         {mustBeInteger,mustBeNonnegative} = 1000;
      % total number of shots
    shotSize(1,1)       {mustBeInteger,mustBeNonnegative} = 1024*1;
      % size of on shot in samples
    shotsPerNotify(1,1) {mustBeInteger,mustBeNonnegative} = 10;
      % we get notified about new shots every nShots = shotsPerNotify
      % NOTE adapt to get more frequent updates if needed
      % best to keep this 2^n, i.e. 4, 8, 16
    shotsinBuffer(1,1)  {mustBeInteger,mustBeNonnegative} = 1024;
      % size of the FIFO buffer in shots
      % NOTE play with this for better performance if needed?
    dataType(1,1)       {mustBeInteger,mustBeNonnegative} = 0;
      % 0 = RAW (int16), 1 = float
    nChannels(1,1)      {mustBeInteger,mustBeNonnegative} = 0;
      % 1/2 -> must match setup prior to FIFO acquisition
    currentBlock(1,1)   {mustBeInteger,mustBeNonnegative} = 0;
      % 1/2 -> must match setup prior to FIFO acquisition
  end

  properties (Constant)
    PRE_TRIGGER_SAMPLES = 16; %% min = 16, step size = 16
    BYTES_PER_SAMPLE = 2; % 16 bit = 2 bytes...
    TIME_STAMP_SIZE = 8; % [Byte] time stamp is 64 bit -> 8 byte
    MIN_NOTIFY_SIZE = 2048; % empiric finding...
  end

  properties (Dependent = true)
    postSamples(1,1)    {mustBeInteger,mustBeNonnegative};
    bufferSize(1,1)     {mustBeInteger,mustBeNonnegative}; % [byte]
    notifySize(1,1)     {mustBeInteger,mustBeNonnegative}; % [byte]
    nBlocks(1,1)        {mustBeInteger,mustBeNonnegative};
    notifySizeTS(1,1)   {mustBeInteger,mustBeNonnegative}; % [byte]
    bufferSizeTS(1,1)   {mustBeInteger,mustBeNonnegative}; % [byte]
    currentShots(1,:)   {mustBeInteger,mustBeNonnegative}; % [byte]
  end

  % set / get functions
  methods % get functions for depended properties
    function postSamples = get.postSamples(FS)
      % see manual for description of pre/post trigger samples
      postSamples = FS.shotSize - FS.PRE_TRIGGER_SAMPLES; %% min allowed!
    end

    function bufferSize = get.bufferSize(FS)
      % buffer size in samples, might have effect on performance but should
      % otherwise not be overly relevant
      bufferSize = FS.shotsinBuffer*FS.shotSize*FS.BYTES_PER_SAMPLE;  % in samples
    end

    function notifySize = get.notifySize(FS)
      % notifySize in samples, we get this many samples at once
      % when we run in FIFO mode and query data
      % The Notify size sticks to the page size which is defined by the PC
      % hardware and the operating system. Therefore the notify size must be a
      % multiple of 4 kByte. For data transfer it may also be a fraction of 4k
      % in the range of 16, 32, 64, 128, 256, 512, 1k or 2k

      notifySize = FS.shotsPerNotify*FS.shotSize*FS.nChannels*FS.BYTES_PER_SAMPLE; % in samples
      if notifySize > FS.bufferSize
        error('Fifo.notifySize > Fifo.bufferSize!');
        notifySize = [];
      end
      if notifySize < FS.MIN_NOTIFY_SIZE
        notifySize = FS.MIN_NOTIFY_SIZE;
      end
    end

    function nBlocks = get.nBlocks(FS)
      nBlocks = FS.nShots./FS.shotsPerNotify;
    end

    function notifySizeTS = get.notifySizeTS(FS)
      % notifySize in samples, we get this many samples at once
      % when we run in FIFO mode and query data
      % The Notify size sticks to the page size which is defined by the PC
      % hardware and the operating system. Therefore the notify size must be a
      % multiple of 4 kByte. For data transfer it may also be a fraction of 4k
      % in the range of 16, 32, 64, 128, 256, 512, 1k or 2k
      notifySizeTS = FS.shotsPerNotify*FS.TIME_STAMP_SIZE*2;
      if notifySizeTS < FS.MIN_NOTIFY_SIZE
        notifySizeTS = FS.MIN_NOTIFY_SIZE;
      end
    end

    function bufferSizeTS = get.bufferSizeTS(FS)
      bufferSizeTS = FS.shotsinBuffer*FS.TIME_STAMP_SIZE;
      % when we get notified, we get the same number of time samples as we get shots
    end

    function currentShots = get.currentShots(FS)
      shotStart = (FS.currentBlock-1)*FS.shotsPerNotify+1;
      shotEnd = FS.currentBlock*FS.shotsPerNotify;
      currentShots = shotStart:shotEnd;
    end

  end

  methods % set/get functions to check valid configuration
    % function postSamples = get.postSamples(FS)
    %   postSamples = FS.shotSize - 16; %% min allowed!
    % end
  end

end
