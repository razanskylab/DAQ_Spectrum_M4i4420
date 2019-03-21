% File: FastDAQ.m
% Author: Urs Hofmann
% Date: 03. Jan 2018
% Mail: hofmannu@student.ethz.ch

% Note: If you want to use a card with more input channels, please adapt
%     - property NO_CHANNELS
%     - size of the channels array (line 40)
%     - Acquire_Data function (line 172)

% Missing:
%   - Add a function which checks the integrity of all passed arguments
% - lots of other thigns ;-)

classdef M4DAC16<handle

  properties (Constant = true)
    NO_CHANNELS = 2;
    cardPort = '\dev\spcm0';
    CONNECT_ON_STARTUP = 1;
    BYTES_PER_SAMPLE = 2; % 16 bit = 2 bytes...
    RESOLUTION = 16; % 16 bit ADC resolution
    % FLAGS for convenience
    SAMPLE_DATA = 0;
    TIMESTAMP_DATA = 1;

    % DEFAULT Settings
    TIME_OUT = 5000;
    SAMPLING_RATE = 250e6;
    DELAY = 0;
  end

  properties (SetAccess = private)
    isConnected(1,1) {mustBeNumericOrLogical} = 0;
  end

  % Properties of data acquisition card
  properties
    cardInfo; % stores the informations about the card in a struct
    comSuccess(1,1) {mustBeNumericOrLogical} = 1; % either 0 or 1
    beSilent(1,1) {mustBeNumericOrLogical} = 0; % either 0 or 1


    % channel sensitivty can be 10000 / 5000 /
    sensitivityPd(1,1) {mustBeNumeric} = 10000;
    sensitivityUs(1,1) {mustBeNumeric} = 1000;
    % These variables are actually a dublicate of the channels.inputrange but we
    % want to use them as dummies to set only the sensitivity of the channels w/
    % o modifying the remaining parts

    dataType(1,1) {mustBeNumeric} = 0;
    % 0: data are returned as 16 bit integer
    % 1: data are returned as voltage (single)

    % offset start address for data chunk to be read
    % NOTE ignored in FIFO mode
    offset(1,1) {mustBeNumeric} = 0;


    channels = repmat( struct( ...
      'path',         0, ... % 0=Buffered 1=HF input with fixed 50 ohm termination
      'inputrange',   10000, ... %
      'term',         1, ... % 1: 50 ohm termination, 0: 1MOhm termination
      'acCpl',        0, ... % [1] AC coupling
      'inputoffset',  0, ... % [0]
      'bwLim',        0, ... % 0/1 [0] Anti aliasing filter (Bandwidth limit)
      'diffinput',    0  ), 1, 2); % [0] diff input?

    externalTrigger = struct(...
      'extMode', 1, ... % 1 means rising edge
      'trigTerm', 0, ... % flag, whether to terminate the trigger inout
      'pulseWidth', 0, ... % pulsewidth for any external trigger source using a pulse counter
      'singleSrc', 1, ... % necessary if multiple trigger lines are used
      'extLine', 1); % defines the trigger line (0 is big sma, 1 is small MMCX connector)

    % spcMSetupTrigChannel (cardInfo, channel, trigMode, trigLevel0, trigLevel1, pulsewidth, trigOut, singleSrc)
    triggerChannel = struct(...
      'channel', 0, ... % which channel should be used for triggering
      'trigMode', 1, ... % means trigger on rising edge
      'trigLevel0', 500, ... % trigger level in mV
      'trigLevel1', 500, ... % trigger level in mV
      'pulsewidth', 0,...
      'trigOut', 0, ...
      'singleSrc', 1);

    acquisitionMode = struct(...
      'chMaskH', 0,  ...
      'chMaskL', 3,  ...
      'nSamples', 3008,  ... % must be dividable 16
      'postSamples', 2992);

    fifoMode = struct(...
      'chMaskH', 0,  ...
      'chMaskL', 3,  ...
      'nSamples', 3008,  ... % must be dividable 16
      'postSamples', 2992, ...
      'loopsToRec', 100); % [bytes]

    multiMode = struct(...
      'chMaskH', 0,  ...
      'chMaskL', 3,  ...
      'memsamples', 501*3008,  ... % must be dividable 16
      'segmentsize', 3008, ...
      'postsamples', 3008-16);

    triggerLevel = struct(...
      'ext0_0', 1800, ... % [mV]
      'ext0_1', 2000, ... % [mV]
      'ext1_0', 2000 ... % [mV]
      );

    mRegs = spcMCreateRegMap();
    mErrors = spcMCreateErrorMap();
  end

  % SET/GET properties, they are assigned their default values during class
  % creation and get their values directly from the connected card
  properties
    samplingRate(1,1) {mustBeInteger,mustBeNonnegative}; % [Hz]
    timeout(1,1) {mustBeInteger,mustBeNonnegative}; % [ms] 0 means disabled
    delay(1,1) {mustBeInteger,mustBeNonnegative}; % DAQ trigger delay in samples
  end

  properties (Dependent = true)
    triggerCount; % read only, read from card
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor
    function DAQ = M4DAC16(doConnect)
      if nargin == 0
        doConnect = DAQ.CONNECT_ON_STARTUP;
      end

      if doConnect
        % UH: not needed any more since the files are already in the correct folder. Furthermore
        % the library under the path below was not complete
        % add path to lib files, needs to be on Matlab file path
        % addpath(genpath('C:\Hardware_Libs\M4DAC16\'));

        % Default settings are defined in the properties section (despite channels
        % ). Here we are only going to initialize them. For that we have to write
        % the properties once to the card using the set functions

        % DAQ.mRegs = spcMCreateRegMap();
        % DAQ.mErrors = spcMCreateErrorMap();

        Open_Connection(DAQ);
        DAQ.Reset(); % recommended by manual

        channels = DAQ.channels();

        channels(1).inputrange = 10000; % [mV]
        channels(1).term = 1; % 1: 50 ohm termination, 0: 1MOhm termination
        channels(1).inputoffset = 0;
        channels(1).diffinput = 0;

        channels(2).inputrange = 10000; % [mV]
        channels(2).term = 1; % 1: 50 ohm termination, 0: 1MOhm termination
        channels(2).inputoffset = 0;
        channels(2).diffinput = 0;

        DAQ.channels = channels;
        %DAQ.externalTrigger = DAQ.externalTrigger;
        %DAQ.acquisitionMode = DAQ.acquisitionMode;
        %DAQ.delay = DAQ.delay;
        DAQ.samplingRate = DAQ.SAMPLING_RATE;
        DAQ.timeout = DAQ.TIME_OUT;

      else
        fprintf('[M4DAC16] Initialized but not connected yet.\n');
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Save function
    function saveObj = saveobj(DAQ)
      saveObj = [];
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Destructor
    function delete(DAQ)
      if DAQ.isConnected
        DAQ.Close_Connection();
      end
    end
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % SET / GET functions
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods
    %---------------------------------------------------------------------------
    % Set/Get the timeout of the DAQ in ms
    function set.timeout(DAQ, to)
      % ----- set timeout -----
      errorCode = spcm_dwSetParam_i32 (DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_TIMEOUT'), to);
      if (errorCode ~= 0)
          [success, DAQ.cardInfo] = spcMCheckSetError (errorCode, DAQ.cardInfo);
          spcMErrorMessageStdOut (DAQ.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
          return;
      else
        fprintf('[M4DAC16] Timeout set to %2.0f s.\n',to/1000);
      end
    end

    function timeOut = get.timeout(DAQ)
      [err, timeOut] = spcm_dwGetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_TIMEOUT'));
      if err
        short_warn('Could not read timeOut!');
        timeOut = [];
      end
    end

    %---------------------------------------------------------------------------
    function set.triggerChannel(DAQ, tc)
      warning('Not tested yet.');

      [success, DAQ.cardInfo] = spcMSetupTrigChannel(DAQ.cardInfo, ...
        tc.channel, ... % channel used
        tc.trigMode, ... % trigger mode
        tc.trigLevel0, ...
        tc.trigLevel1, ...
        tc.pulsewidth, ...
        tc.trigOut, ...
        tc.singleSrc);

      if ~success
        error('Somthing went wrong while setting up the channel based trigger.');
      else
        DAQ.triggerChannel = tc;
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Function which only modifies the channel sensitivity w/o touching any othe
    % r channel settings. With this we do not have to define the whole channel e
    % verytime we want to modify only the sensitivity
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %---------------------------------------------------------------------------
    function set.sensitivityPd(DAQ, sensitivityPd)
      if ~DAQ.beSilent
        fprintf('[M4DAC16] Setting channel 0 sensitivity.\n');
      end
      DAQ.channels(1).inputrange = sensitivityPd;
      DAQ.sensitivityPd = sensitivityPd;
    end

    %---------------------------------------------------------------------------
    function set.sensitivityUs(DAQ, sensitivityUs)
      if ~DAQ.beSilent
        fprintf('[M4DAC16] Setting channel 1 sensitivity.\n');
      end
      DAQ.channels(2).inputrange = sensitivityUs;
      DAQ.sensitivityUs = sensitivityUs;
    end

    %---------------------------------------------------------------------------
    % setting delay of data acquisition card
    function set.delay(DAQ, delay)
      fprintf(['[M4DAC16] Setting the delay to ', num2str(delay), ' samples.\n']);

      % Check validity of delay
      if (delay < 0)
        warning('[M4DAC16] Delay cannot be below 0, setting it to 0 (disbaled).');
        delay = 0;
      elseif (delay > 8589934576)
        warning('[M4DAC16] Delay is above maximum, reducing to 8589934576 samples');
        delay = 8589934576;
      else
        delay = round(delay/16) * 16;
      end

      % set delay
      errorCode = spcm_dwSetParam_i32(...
        DAQ.cardInfo.hDrv, ...
        DAQ.mRegs('SPC_TRIG_DELAY'), ... % defines the delay for the detected trigger events
        delay); % delay in samples

      if (errorCode ~= 0)
        error(['[M4DAC16] Could not set delay: ', errorCode]);
      else
        DAQ.delay = delay;
      end
    end

    % FIXME add get delay!

    %---------------------------------------------------------------------------
    % Function to set sample rate of data acquisition card, takes care that we
    % do not exceed max and min limits and that we have an open connection
    function set.samplingRate(DAQ, samplingRate)
      maxRate = DAQ.cardInfo.maxSamplerate;

      if (DAQ.isConnected == 0)
        short_warn('[M4DAC16] No open connection.');
      else
        if (samplingRate < DAQ.cardInfo.minSamplerate)
          short_warn('[M4DAC16] SamplingRate has to be >= %5.0f', ...
            DAQ.cardInfo.minSamplerate);
          samplingRate = DAQ.cardInfo.minSamplerate;
        elseif (samplingRate > maxRate)
          short_warn('[M4DAC16] SamplingRate has to be <= %5.0f', ...
            maxRate);
          samplingRate = maxRate;
        end

        if rem(maxRate,samplingRate)
          samplingRate = maxRate./floor(maxRate/samplingRate);
            % sets to next higher allowed sampling rate
          warnText = sprintf('Using next higher allowed sampling rate (%2.1fMHz)',samplingRate*1e-6);
          short_warn(warnText);
        end

        if ~DAQ.beSilent
          fprintf('[M4DAC16] Setting sampling rate: %2.1fMHz \n', samplingRate*1e-6);
        end

        [success, DAQ.cardInfo] = spcMSetupClockPLL(DAQ.cardInfo, samplingRate, 0);

        if ~success
          error(['[M4DAC16] Could not set the sampling rate:\n', ...
            DAQ.cardInfo.errorText]);
          DAQ.samplingRate = [];
        else
          DAQ.samplingRate = DAQ.cardInfo.setSamplerate;
        end
      end
    end

    % FIXME add get samplingRate!


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Setting up the analog input channels, all at once. There will be a second
    % function named set.channel(DAQ, channel, id_channel) which can be used to
    % set up a single channel
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.channels(DAQ, channels)
      DAQ.Setup_All_Channels(channels);
      DAQ.channels = channels;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Generation mode setup: defines the generation mode for the next run. The f
    % unctions are only used with the genertor or I/O cards. It is onlz possible
    % to use one generation mode at a time.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.acquisitionMode(DAQ, acquisitionMode)
      if ~DAQ.beSilent
        fprintf('[M4DAC16] Setting up data acquisistion mode.\n');
      end

      DAQ.acquisitionMode = acquisitionMode;

      [success, DAQ.cardInfo] = spcMSetupModeRecStdSingle(...
        DAQ.cardInfo,...
        DAQ.acquisitionMode.chMaskH, ...
        DAQ.acquisitionMode.chMaskL, ...
        DAQ.acquisitionMode.nSamples, ...
        DAQ.acquisitionMode.postSamples);

      if (success == 0)
          error(['[M4DAC16] Error while setting up data acquisisiton mode: ', ...
            DAQ.cardInfo.errorText]);
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Setup external TTL trigger
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.externalTrigger(DAQ, externalTrigger)
      DAQ.Setup_External_Trigger(externalTrigger);
      DAQ.externalTrigger = externalTrigger;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set datatype (0 --> 16 bit integer, 1 --> float)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.dataType(DAQ, dataType)
      if (dataType == 0)
        % 16 bit integer
        DAQ.dataType = 0;
        if ~DAQ.beSilent
          fprintf('[M4DAC16] Setting the datatype to 16 bit integer.\n');
        end
      elseif (dataType == 1)
        % voltage as single
        DAQ.dataType = 1;
        if ~DAQ.beSilent
          fprintf('[M4DAC16] Setting the datatype to voltage.\n');
        end
      else
        % invalid argument
        error('[M4DAC16] You passed an invalid option as dataType.');
      end
    end

    function triggerCount = get.triggerCount(DAQ)
      [errCode, triggerCount] = spcm_dwGetParam_i64(DAQ.cardInfo.hDrv, 200905);
        % 200905 = SPC_TRIGGERCOUNTER
      if errCode
        short_warn('Could not read triggerCount!');
        [success, DAQ.cardInfo] = spcMCheckSetError (errCode, DAQ.cardInfo);
        spcMErrorMessageStdOut(DAQ.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
        short_warn(DAQ.cardInfo.errorText);
        triggerCount = [];
      end
    end

  end
end
