classdef FiFoSettings

  properties
    nShots(1,1)         {mustBeInteger,mustBeNonnegative};
      % total number of shots
    shotSize(1,1)       {mustBeInteger,mustBeNonnegative} = 1024*1;
      % size of on shot in samples
    shotsinBuffer(1,1)  {mustBeInteger,mustBeNonnegative} = 2048*5;
      % size of the FIFO buffer in shots
      % NOTE play with this for better performance if needed! (already made it larger...)
    dataType(1,1)       {mustBeInteger,mustBeNonnegative} = 0;
      % 0 = RAW (int16), 1 = float
    nChannels(1,1)      {mustBeInteger,mustBeNonnegative} = 0;
      % 1/2 -> must match setup prior to FIFO acquisition
    currentBlock(1,1)   {mustBeInteger,mustBeNonnegative} = 0;
      % 1/2 -> must match setup prior to FIFO acquisition
  end

  properties (SetAccess = private)
    shotsPerNotify(1,1) {mustBeInteger,mustBeNonnegative} = 2;
  end

  properties (Constant)
    PRE_TRIGGER_SAMPLES = 16; %% min = 16, step size = 16
    BYTES_PER_SAMPLE = 2; % 16 bit = 2 bytes...
    TIME_STAMP_SIZE = 8; % [Byte] time stamp is 64 bit -> 8 byte
    MIN_NOTIFY_SIZE = 2048; % empiric finding...
    TS_NOTIFY_SIZE = 2048;
  end

  properties (Dependent = true)
    postSamples(1,1)      {mustBeInteger,mustBeNonnegative};
    bufferSize(1,1)       {mustBeInteger,mustBeNonnegative}; % [byte]
    notifySize(1,1)       {mustBeInteger,mustBeNonnegative}; % [byte]
    nBlocks(1,1)          {mustBeInteger,mustBeNonnegative};
    notifySizeTS(1,1)     {mustBeInteger,mustBeNonnegative}; % [byte]
    shotsPerNotifyTs(1,1) {mustBeInteger,mustBeNonnegative}; % [byte]
    bufferSizeTS(1,1)     {mustBeInteger,mustBeNonnegative}; % [byte]
    currentShots(1,:)     {mustBeInteger,mustBeNonnegative}; % [byte]
    totalBytes(1,1)     {mustBeInteger,mustBeNonnegative}; % [byte]
    shotByteSize(1,1)     {mustBeInteger,mustBeNonnegative};
  end

  methods % normal methods
    % number of bytes to be acquired with the current settings
    function Set_shotsPerNotify(FiFo)
      maxShotsPerNotify = round(FiFo.shotsinBuffer./5);
      possibleValues = [];
      for iShots = 1:maxShotsPerNotify
        notifySize = iShots*FiFo.shotByteSize; % in samples
        nBlocks = FiFo.totalBytes./notifySize;
        if ~mod(nBlocks,1)
          possibleValues = [possibleValues iShots];
        end
      end
      FiFo.shotsPerNotify = max(possibleValues);
    end

  end

  % set / get functions
  methods % get functions for depended properties
    function postSamples = get.postSamples(FiFo)
      % see manual for description of pre/post trigger samples
      postSamples = FiFo.shotSize - FiFo.PRE_TRIGGER_SAMPLES; %% min allowed!
    end

    function bufferSize = get.bufferSize(FiFo)
      % buffer size in samples, might have effect on performance but should
      % otherwise not be overly relevant
      bufferSize = FiFo.shotsinBuffer*FiFo.shotSize*FiFo.BYTES_PER_SAMPLE;  % in samples
    end

    function notifySize = get.notifySize(FiFo)
      % notifySize in samples, we get this many samples at once
      % when we run in FIFO mode and query data
      % The Notify size sticks to the page size which is defined by the PC
      % hardware and the operating system. Therefore the notify size must be a
      % multiple of 4 kByte. For data transfer it may also be a fraction of 4k
      % in the range of 16, 32, 64, 128, 256, 512, 1k or 2k

      notifySize = FiFo.shotsPerNotify*FiFo.shotByteSize; % in samples
      if notifySize > FiFo.bufferSize
        error('Fifo.notifySize > Fifo.bufferSize!');
        notifySize = [];
      end
      if notifySize < FiFo.MIN_NOTIFY_SIZE
        notifySize = FiFo.MIN_NOTIFY_SIZE;
      end
    end

    function nBlocks = get.nBlocks(FiFo)
      nBlocks = FiFo.totalBytes./FiFo.notifySize;
      if mod(nBlocks,1)
        % short_warn('[DAQ.FiFo] nBlocks not an interger!');
      end
      % fprintf('nBlocks = %2.1f | %2.1f\n',nBlocks,nBlocksNew);
      % totalBytes = FiFo.shotSize*FiFo.BYTES_PER_SAMPLE*FiFo.nShots
      % FiFo.shotsinBuffer*FiFo.shotSize*FiFo.BYTES_PER_SAMPLE
        % by ceiling we might get too many blocks
        % but we will make sure to gather the incomplete data from the last
        % unfisished block "manually"
    end

    % number of bytes to be acquired with the current settings
    function totalBytes = get.totalBytes(FiFo)
      totalBytes = FiFo.nShots*FiFo.shotByteSize;
    end

    % number of bytes to be acquired with the current settings
    function shotByteSize = get.shotByteSize(FiFo)
      shotByteSize = FiFo.shotSize*FiFo.nChannels*FiFo.BYTES_PER_SAMPLE;
    end


    function notifySizeTS = get.notifySizeTS(FiFo)
      % notifySize in samples, we get this many samples at once
      % when we run in FIFO mode and query data
      % The Notify size sticks to the page size which is defined by the PC
      % hardware and the operating system. Therefore the notify size must be a
      % multiple of 4 kByte. For data transfer it may also be a fraction of 4k
      % in the range of 16, 32, 64, 128, 256, 512, 1k or 2k
      notifySizeTS = FiFo.TS_NOTIFY_SIZE; % only 2 and 4k seem to work...
      % so we really just make this a constant
    end

    function shotsPerNotifyTs = get.shotsPerNotifyTs(FiFo)
      shotsPerNotifyTs = FiFo.notifySizeTS./FiFo.TIME_STAMP_SIZE;
        % 256 shots is minimum...
    end

    function bufferSizeTS = get.bufferSizeTS(FiFo)
      bufferSizeTS = FiFo.shotsinBuffer*FiFo.TIME_STAMP_SIZE;
      % when we get notified, we get the same number of time samples as we get shots
    end

    function currentShots = get.currentShots(FiFo)
      shotStart = (FiFo.currentBlock-1)*FiFo.shotsPerNotify+1;
      shotEnd = FiFo.currentBlock*FiFo.shotsPerNotify;
      currentShots = shotStart:shotEnd;
    end

  end

  methods % set/get functions to check valid configuration
    % function postSamples = get.postSamples(FiFo)
    %   postSamples = FiFo.shotSize - 16; %% min allowed!
    % end
  end

end
