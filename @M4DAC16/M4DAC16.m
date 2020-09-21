% File: FastObj.m
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

classdef M4DAC16 < BaseHardwareClass

  properties (Constant = true)
    NO_CHANNELS = 2;
    cardPort = '\dev\spcm0';

    CONNECT_ON_STARTUP = 1;
    BYTES_PER_SAMPLE = 2; % [Byte] 16 bit = 2 bytes...
    RESOLUTION = 16; % 16 bit ADC resolution

    % FLAGS for convenience
    SAMPLE_DATA = 0;
    TIMESTAMP_DATA = 1;

    % DEFAULT Settings
    TIME_OUT = 5000;
    SAMPLING_RATE = 250e6;
    DELAY = 0;
    TIME_STAMP_SIZE = 8; % [Byte] time stamp is 64 bit -> 8 byte
  end

  properties (SetAccess = private)
    isConnected(1,1) {mustBeNumericOrLogical} = 0;
  end

  % Properties of data acquisition card
  properties
    classId = '[DAQ]'; % used for VPrintF_With_ID_W   
    cardInfo; % stores the informations about the card in a struct
    FiFo(1, 1) FiFoSettings; % subclass for storing fifo settings

    comSuccess(1,1) {mustBeNumericOrLogical} = 1; % either 0 or 1
    beSilent(1,1) {mustBeNumericOrLogical} = 0; % either 0 or 1

    % channel sensitivty can be 10000 / 5000 /
    sensitivityPd(1, 1) {mustBeNumeric} = 10000;
    sensitivityUs(1, 1) {mustBeNumeric} = 1000;
    % These variables are actually a dublicate of the channels.inputrange but we
    % want to use them as dummies to set only the sensitivity of the channels w/
    % o modifying the remaining parts

    dataType(1, 1) {mustBeNumeric} = 0;
    % 0: data are returned as 16 bit integer
    % 1: data are returned as voltage (single)

    % offset start address for data chunk to be read
    % NOTE ignored in FIFO mode
    offset(1, 1) {mustBeNumeric} = 0;

    channels(1, 2) Channel; % data acquisition channels
    externalTrigger(1, 1) ExternalTrigger; % external trigger definition

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
    delay(1,1) {mustBeInteger,mustBeNonnegative}; % Obj trigger delay in samples
  end

  properties (Dependent = true)
    triggerCount; % read only, read from card
    tsBytesAvailable; % available time stamp bytes
    bytesAvailable; % available time stamp bytes
    currentError;
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor
    function Obj = M4DAC16(doConnect)
      if nargin == 0
        doConnect = Obj.CONNECT_ON_STARTUP;
      end

      if doConnect
        % UH: not needed any more since the files are already in the correct folder. Furthermore
        % the library under the path below was not complete
        % add path to lib files, needs to be on Matlab file path
        % addpath(genpath('C:\Hardware_Libs\M4DAC16\'));

        % Default settings are defined in the properties section (despite channels
        % ). Here we are only going to initialize them. For that we have to write
        % the properties once to the card using the set functions

        % Obj.mRegs = spcMCreateRegMap();
        % Obj.mErrors = spcMCreateErrorMap();
        Obj.VPrintF_With_ID('Connecting and setting up...');
        Obj.verboseOutput = false;
        Obj.Open_Connection();
        Obj.Reset(); % recommended by manual

        channels = Obj.channels();

        channels(1).inputrange = 10000; % [mV]
        channels(1).term = 1; % 1: 50 ohm termination, 0: 1MOhm termination
        channels(1).inputoffset = 0;
        channels(1).diffinput = 0;

        channels(2).inputrange = 10000; % [mV]
        channels(2).term = 1; % 1: 50 ohm termination, 0: 1MOhm termination
        channels(2).inputoffset = 0;
        channels(2).diffinput = 0;

        Obj.channels = channels;
        %Obj.externalTrigger = Obj.externalTrigger;
        %Obj.acquisitionMode = Obj.acquisitionMode;
        %Obj.delay = Obj.delay;
        Obj.samplingRate = Obj.SAMPLING_RATE;
        Obj.timeout = Obj.TIME_OUT;
        Obj.verboseOutput = true;
        Obj.VPrintF('...done!\n');

      else
        Obj.VPrintF_With_ID('Initialized but not connected yet.\n');
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Save function
    function saveObj = saveobj(~)
      saveObj = [];
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Destructor
    function delete(Obj)
      if Obj.isConnected
        Obj.Close_Connection();
      end
    end
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % SET / GET functions
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods
    %---------------------------------------------------------------------------
    % Set/Get the timeout of the Obj in ms
    function set.timeout(Obj, to)
      % ----- set timeout -----
      errorCode = spcm_dwSetParam_i32 (Obj.cardInfo.hDrv, Obj.mRegs('SPC_TIMEOUT'), to); %#ok<*MCSUP>
      if (errorCode ~= 0) 
          [~, Obj.cardInfo] = spcMCheckSetError (errorCode, Obj.cardInfo);
          spcMErrorMessageStdOut (Obj.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
          return;
      else
        Obj.VPrintF_With_ID('Timeout set to %2.0f s.\n',to/1000);
      end
    end

    function timeOut = get.timeout(Obj)
      [err, timeOut] = spcm_dwGetParam_i32(Obj.cardInfo.hDrv, Obj.mRegs('SPC_TIMEOUT'));
      if err
        Obj.Verbose_Warn('Could not read timeOut!');
        timeOut = [];
      end
    end

    %---------------------------------------------------------------------------
    function set.triggerChannel(Obj, tc)
      warning('Not tested yet.');

      [success, Obj.cardInfo] = spcMSetupTrigChannel(Obj.cardInfo, ...
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
        Obj.triggerChannel = tc;
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Function which only modifies the channel sensitivity w/o touching any othe
    % r channel settings. With this we do not have to define the whole channel e
    % verytime we want to modify only the sensitivity
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %---------------------------------------------------------------------------
    function set.sensitivityPd(Obj, sensitivityPd)
      if ~Obj.beSilent
        Obj.VPrintF_With_ID('Setting channel 0 sensitivity.\n');
      end
      Obj.channels(1).inputrange = sensitivityPd;
      Obj.sensitivityPd = sensitivityPd;
    end

    %---------------------------------------------------------------------------
    function set.sensitivityUs(Obj, sensitivityUs)
      if ~Obj.beSilent
        Obj.VPrintF_With_ID('Setting channel 1 sensitivity.\n');
      end
      Obj.channels(2).inputrange = sensitivityUs;
      Obj.sensitivityUs = sensitivityUs;
    end

    %---------------------------------------------------------------------------
    % setting delay of data acquisition card
    function set.delay(Obj, delay)
      Obj.VPrintF_With_ID(['Setting the delay to ', num2str(delay), ' samples.\n']);

      % Check validity of delay
      if (delay < 0)
        warning('[M4DAC16] Delay cannot be below 0, setting it to 0 (disbaled).');
        delay = 0;
      elseif (delay > 8589934576)
        warning('[M4DAC16] Delay is above maximum, reducing to 8589934576 samples');
        delay = 8589934576;
      else
        % we have a valid trigger value, just make sure it's multiple
        % integer of 16, as required by the Obj
        delay = round(delay/16) * 16;
      end

      % set delay
      errorCode = spcm_dwSetParam_i32(...
        Obj.cardInfo.hDrv, ...
        Obj.mRegs('SPC_TRIG_DELAY'), ... % defines the delay for the detected trigger events
        delay); % delay in samples

      if (errorCode ~= 0)
        error(['[M4DAC16] Could not set delay: ', errorCode]);
      else
        Obj.delay = delay;
      end
    end

    % FIXME add get delay!

    %---------------------------------------------------------------------------
    % Function to set sample rate of data acquisition card, takes care that we
    % do not exceed max and min limits and that we have an open connection
    function set.samplingRate(Obj, samplingRate)
      maxRate = Obj.cardInfo.maxSamplerate;

      if (Obj.isConnected == 0)
        Obj.Verbose_Warn('[M4DAC16] No open connection.');
      else
        if (samplingRate < Obj.cardInfo.minSamplerate)
          Obj.Verbose_Warn('[M4DAC16] SamplingRate has to be >= %5.0f', ...
            Obj.cardInfo.minSamplerate);
          samplingRate = Obj.cardInfo.minSamplerate;
        elseif (samplingRate > maxRate)
          Obj.Verbose_Warn('[M4DAC16] SamplingRate has to be <= %5.0f', ...
            maxRate);
          samplingRate = maxRate;
        end

        if rem(maxRate,samplingRate)
          samplingRate = maxRate ./ floor(maxRate / samplingRate);
            % sets to next higher allowed sampling rate
          warnText = sprintf('Using next higher allowed sampling rate (%2.1fMHz)',samplingRate*1e-6);
          Obj.Verbose_Warn(warnText);
        end

        if ~Obj.beSilent
          Obj.VPrintF_With_ID('Setting sampling rate: %2.1fMHz \n', samplingRate*1e-6);
        end

        [success, Obj.cardInfo] = spcMSetupClockPLL(Obj.cardInfo, samplingRate, 0);

        if ~success
          error(['[M4DAC16] Could not set the sampling rate:\n', ...
            Obj.cardInfo.errorText]);
          Obj.samplingRate = [];
        else
          Obj.samplingRate = samplingRate;
        end
      end
    end

    % FIXME add get samplingRate!


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Setting up the analog input channels, all at once. There will be a second
    % function named set.channel(Obj, channel, id_channel) which can be used to
    % set up a single channel
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.channels(Obj, channels)
      Obj.Setup_All_Channels(channels);
      Obj.channels = channels;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Generation mode setup: defines the generation mode for the next run. The f
    % unctions are only used with the genertor or I/O cards. It is onlz possible
    % to use one generation mode at a time.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.acquisitionMode(Obj, acquisitionMode)
      if ~Obj.beSilent
        Obj.VPrintF_With_ID('Setting up data acquisistion mode.\n');
      end

      Obj.acquisitionMode = acquisitionMode;

      [success, Obj.cardInfo] = spcMSetupModeRecStdSingle(...
        Obj.cardInfo,...
        Obj.acquisitionMode.chMaskH, ...
        Obj.acquisitionMode.chMaskL, ...
        Obj.acquisitionMode.nSamples, ...
        Obj.acquisitionMode.postSamples);

      if (success == 0)
          error(['[M4DAC16] Error while setting up data acquisisiton mode: ', ...
            Obj.cardInfo.errorText]);
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Setup external TTL trigger
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.externalTrigger(Obj, externalTrigger)
      Obj.Setup_External_Trigger_Level(externalTrigger);
      Obj.externalTrigger = externalTrigger;
    end

    function set.beSilent(Obj, beSilent)
      Obj.verboseOutput = beSilent;
      Obj.beSilent = beSilent;
    end

    % Set datatype (0 --> 16 bit integer, 1 --> float)
    function set.dataType(Obj, dataType)
      if (dataType == 0)
        % 16 bit integer
        Obj.dataType = 0;
        if ~Obj.beSilent
          Obj.VPrintF_With_ID('Setting the datatype to 16 bit integer.\n');
        end
      elseif (dataType == 1)
        % voltage as single
        Obj.dataType = 1;
        if ~Obj.beSilent
          Obj.VPrintF_With_ID('Setting the datatype to voltage.\n');
        end
      else
        % invalid argument
        error('[M4DAC16] You passed an invalid option as dataType.');
      end
    end

    function triggerCount = get.triggerCount(Obj)
      [errCode, triggerCount] = spcm_dwGetParam_i64(Obj.cardInfo.hDrv, 200905);
        % 200905 = SPC_TRIGGERCOUNTER
      if errCode
        Obj.Verbose_Warn('Could not read triggerCount!');
        [success, Obj.cardInfo] = spcMCheckSetError (errCode, Obj.cardInfo);
        spcMErrorMessageStdOut(Obj.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
        Obj.Verbose_Warn(Obj.cardInfo.errorText);
        triggerCount = [];
      end
    end

    function bytesAvailable = get.bytesAvailable(Obj)
      [errCode, bytesAvailable] = spcm_dwGetParam_i64(Obj.cardInfo.hDrv, Obj.mRegs('SPC_DATA_AVAIL_USER_LEN'));
        % 200905 = SPC_TRIGGERCOUNTER
      if errCode
        Obj.Verbose_Warn('Could not read bytesAvailable!');
        [success, Obj.cardInfo] = spcMCheckSetError (errCode, Obj.cardInfo);
        spcMErrorMessageStdOut(Obj.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
        Obj.Verbose_Warn(Obj.cardInfo.errorText);
        bytesAvailable = [];
      end
    end

    function tsBytesAvailable = get.tsBytesAvailable(Obj)
      [errCode, tsBytesAvailable] = spcm_dwGetParam_i32(Obj.cardInfo.hDrv, Obj.mRegs('SPC_TS_AVAIL_USER_LEN'));
        % 200905 = SPC_TRIGGERCOUNTER
      if errCode
        Obj.Verbose_Warn('Could not read tsBytesAvailable!');
        [success, Obj.cardInfo] = spcMCheckSetError (errCode, Obj.cardInfo);
        spcMErrorMessageStdOut(Obj.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
        Obj.Verbose_Warn(Obj.cardInfo.errorText);
        tsBytesAvailable = [];
      end
    end

    function currentError = get.currentError(Obj)
      [currentError, errorReg, errorVal, Obj.cardInfo.errorText] = ...
        spcm_dwGetErrorInfo_i32(Obj.cardInfo.hDrv);
    end

    % auto-setup multimode when setting multi-mode settings...
    function set.multiMode(Obj, newMultimodeSettings)
      Obj.multiMode = newMultimodeSettings;
      Obj.Setup_Multi_Mode();
    end
  end
end
