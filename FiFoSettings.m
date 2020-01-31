classdef FiFoSettings < handle

  properties
    nShots(1, 1) uint64 {mustBeInteger,mustBeNonnegative};
      % total number of shots acquired on both channels
    shotSize(1, 1) uint64 {mustBeInteger,mustBeNonnegative} = 1024*1;
      % size of a shot in samples
      % pratical lower limit is 512 for complicated fifo reasons related to
      % block size etc...can prob. be fixed if this ever becomes a limitation
      % but might require math which Joe does not like...
    shotSizePd(1, 1) uint64 {mustBeInteger,mustBeNonnegative} = 0;
      % optional, can be used to record shorter shots
      % see Acquire_Multi_FIFO_Data() and Allocate_Raw_Data()
    shotsinBuffer(1, 1) uint64 {mustBeInteger,mustBeNonnegative} = 2048 * 10;
      % size of the FIFO buffer in shots
      % NOTE play with this for better performance if needed! (already made it larger...)
    dataType(1, 1) uint64 {mustBeInteger,mustBeNonnegative} = 0;
      % 0 = RAW (int16), 1 = float
    nChannels(1, 1) uint64 {mustBeInteger,mustBeNonnegative} = 0;
      % 1/2 -> must match setup prior to FIFO acquisition
    currentBlock(1, 1) uint64 {mustBeInteger,mustBeNonnegative} = 0;
      % 1/2 -> must match setup prior to FIFO acquisition
  end

  properties (SetAccess = private)
    shotsPerNotify(1,1) uint64 {mustBeInteger, mustBeNonnegative} = 2;
  end

  properties (Constant)
    PRE_TRIGGER_SAMPLES uint64 = 16; %% min = 16, step size = 16
    BYTES_PER_SAMPLE uint64 = 2; % [Byte] 16 bit = 2 bytes...
    TIME_STAMP_SIZE uint64 = 8; % [Byte] time stamp is 64 bit -> 8 byte
    MIN_NOTIFY_SIZE uint64 = 2048; % empiric finding...
    % UH: not consistent with hardcoded values below!
    TS_NOTIFY_SIZE uint64 = 2048;
  end

  properties (Dependent = true)
    postSamples(1,1) uint64 {mustBeInteger,mustBeNonnegative};
    bufferSize(1,1) uint64 {mustBeInteger,mustBeNonnegative}; % [byte]
    
    % size which will be transfered after each notify event
    notifySize(1,1) uint64 {mustBeInteger,mustBeNonnegative}; % [byte]

    % number of notify events to reach full nShots
    nBlocks(1,1) uint64 {mustBeInteger,mustBeNonnegative};

    notifySizeTS(1,1) uint64 {mustBeInteger,mustBeNonnegative}; % [byte]

    shotsPerNotifyTs(1,1) uint64 {mustBeInteger,mustBeNonnegative}; % [byte]
    
    bufferSizeTS(1,1) uint64 {mustBeInteger,mustBeNonnegative}; % [byte]

    % returns the shotIds of the shots in the current buffer id
    currentShots(1, :)uint64 {mustBeInteger,mustBeNonnegative}; % [shots]
    
    totalBytes(1,1) uint64 {mustBeInteger,mustBeNonnegative}; % [byte]

    % size of a single shot including both channels in bytes
    shotByteSize(1,1) uint64 {mustBeInteger,mustBeNonnegative};
  end

  methods % normal methods

    % number of bytes to be acquired with the current settings
    

    function Set_shotsPerNotify(FiFo)
      
      maxShotsPerNotify = round(FiFo.shotsinBuffer ./ 10);
      
      % max shots per notify: maximum number of shots which should be used as *basis* for
      % notify size
      % maxShotsPerNotify = floor(FiFo.nShots ./ 20);
      
      % possible values for shots per notify
%       possibleValues = []; 

      iShot = 1:maxShotsPerNotify; % define range of number of shots in one notify
      notifySize = iShot * FiFo.shotByteSize; % convert into byte
      goodNotifySize = ~mod(notifySize, 4096); %#ok<*PROP> % check if multifold of 4096 byte
      integerBlocks = ~mod(FiFo.totalBytes, notifySize);
      possibleValues = (goodNotifySize & integerBlocks);

      if ~any(possibleValues)
        short_warn('No suitable shotsPerNotify found, trying longer shots');
        FiFo.shotSize = FiFo.shotSize + 16;
        FiFo.Set_shotsPerNotify();
      else
        FiFo.shotsPerNotify = max(iShot(possibleValues));
      end

    end

  end

  % set / get functions
  methods % get functions for depended properties
    function postSamples = get.postSamples(FiFo)
      % see manual for description of pre/post trigger samples
      postSamples = FiFo.shotSize - FiFo.PRE_TRIGGER_SAMPLES; %% min allowed!
    end

    function shotSizePd = get.shotSizePd(FiFo)
      if (FiFo.shotSizePd == 0)
        % no special pd size defined, use normal shot size
        shotSizePd = FiFo.shotSize;
      else
        shotSizePd = FiFo.shotSizePd;
      end
    end

    % buffer size in samples, might have effect on performance but should
    % otherwise not be overly relevant
    function bufferSize = get.bufferSize(FiFo)
      bufferSize = FiFo.shotsinBuffer * FiFo.shotSize * FiFo.BYTES_PER_SAMPLE;  % in samples
    end

    % notifySize in bytes, we get this many samples at once
    % when we run in FIFO mode and query data
    % The Notify size sticks to the page size which is defined by the PC
    % hardware and the operating system. Therefore the notify size must be a
    % multiple of 4 kByte. For data transfer it may also be a fraction of 4k
    % in the range of 16, 32, 64, 128, 256, 512, 1k or 2k
    function notifySize = get.notifySize(FiFo)

      notifySize = FiFo.shotsPerNotify * FiFo.shotByteSize; % in bytes
      if notifySize > FiFo.bufferSize
        error('Fifo.notifySize > Fifo.bufferSize!');
      end
      if notifySize < FiFo.MIN_NOTIFY_SIZE
        notifySize = FiFo.MIN_NOTIFY_SIZE;
      end
    end

    function nBlocks = get.nBlocks(FiFo)
      nBlocks = FiFo.totalBytes ./ FiFo.notifySize;
      if mod(nBlocks,1)
        short_warn('[DAQ.FiFo] nBlocks not an interger!');
        nBlocks = floor(nBlocks); % we don't get the last shots...
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
      totalBytes = FiFo.nShots * FiFo.shotByteSize;
    end

    % size of a single shot including both channels in bytes
    function shotByteSize = get.shotByteSize(FiFo)
      shotByteSize = FiFo.shotSize * FiFo.nChannels * FiFo.BYTES_PER_SAMPLE;
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
      bufferSizeTS = FiFo.shotsinBuffer * FiFo.TIME_STAMP_SIZE;
      % when we get notified, we get the same number of time samples as we get shots
    end

    % returns the shotIds of the shots in the current buffer id
    function currentShots = get.currentShots(FiFo)
      shotStart = (FiFo.currentBlock - 1) * FiFo.shotsPerNotify + 1;
      shotEnd = FiFo.currentBlock * FiFo.shotsPerNotify;
      currentShots = shotStart:shotEnd;
    end

  end

  methods % set/get functions to check valid configuration
    % function postSamples = get.postSamples(FiFo)
    %   postSamples = FiFo.shotSize - 16; %% min allowed!
    % end
  end

end
