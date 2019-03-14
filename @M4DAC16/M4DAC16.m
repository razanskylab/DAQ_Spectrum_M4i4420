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

classdef M4DAC16<handle

  properties (Constant = true)
    NO_CHANNELS = 2;
    cardPort = '\dev\spcm0';
    CONNECT_ON_STARTUP = 1;
  end

  properties (SetAccess = private)
    isConnected = 0;
  end

  % Properties of data acquisition card
  properties

    cardInfo; % stores the informations about the card in a struct
    beSilent = 0; % either 0 or 1

    samplingRate = 250e6; % [Hz]
    % The sampling rate of the digitizer should be 10 times of the applicat
    % ion frequency.

    %delay = 0; % samples

    % channel sensitivty can be 10000 / 5000 /
    sensitivityPd = 10000;
    sensitivityUs = 1000;
    % These variables are actually a dublicate of the channels.inputrange but we
    % want to use them as dummies to set only the sensitivity of the channels w/
    % o modifying the remaining parts

    dataType = 0;
    % 0: data are returned as 16 bit integer
    % 1: data are returned as voltage (single)

    offset = 0;
    % offset start address for data chunk to be read

    channels = repmat( struct( ...
      'inputrange',   [], ...
      'term',         [], ...
      'inputoffset',  [], ...
      'diffinput',    []  ), 1, 2);

    externalTrigger = struct(...
      'extMode', 1, ... % 1 means rising edge
      'trigTerm', 0, ... % flag, whether to terminate the trigger inout
      'pulseWidth', 0, ... % pulsewidth for any external trigger source using a pulse counter
      'singleSrc', 1, ... % necessary if multiple trigger lines are used
      'extLine', 1); % can either be 0 or 1 depending on the used trigger line

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

    timeout = 10e3; % [ms] 0 means disabled

    notifySize = 4096;
    bufferSize = 100 * 3008;

    mRegs;
    mErrors;

  end

  methods

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function dac = M4DAC16(doConnect)


      if nargin == 0
        doConnect = dac.CONNECT_ON_STARTUP;
      end

      if doConnect
        % UH: not needed any more since the files are already in the correct folder. Furthermore
        % the library under the path below was not complete
        % add path to lib files, needs to be on Matlab file path
        % addpath(genpath('C:\Hardware_Libs\M4DAC16\'));

        % Default settings are defined in the properties section (despite channels
        % ). Here we are only going to initialize them. For that we have to write
        % the properties once to the card using the set functions

        dac.mRegs = spcMCreateRegMap();
        dac.mErrors = spcMCreateErrorMap();

        channels = repmat( struct( ...
          'inputrange',   [], ...
          'term',         [], ...
          'inputoffset',      [], ...
          'diffinput',    []  ), 1, 2);

        channels(1).inputrange = 10000; % [mV]
        channels(1).term = 1; % 1: 50 ohm termination, 0: 1MOhm termination
        channels(1).inputoffset = 0; 
        channels(1).diffinput = 0; 

        channels(2).inputrange = 10000; % [mV]
        channels(2).term = 1; % 1: 50 ohm termination, 0: 1MOhm termination
        channels(2).inputoffset = 0;
        channels(2).diffinput = 0;

        Open_Connection(dac);
        dac.Reset(); % recommended by manual

        dac.channels = channels;
        %dac.samplingRate = dac.samplingRate;
        %dac.externalTrigger = dac.externalTrigger;
        %dac.acquisitionMode = dac.acquisitionMode;
        %dac.delay = dac.delay; 
        %dac.timeout = dac.timeout;

      else
        fprintf('[M4DAC16] Initialized but not connected yet.\n');
      end
    end

    % TODO
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Save function
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function saveObj = saveobj(dac)
      saveObj = [];
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function delete(dac)
      if dac.isConnected
        dac.Close_Connection();
      end
    end

    % Function declaration for functions sture in the @FastDAQ folder
    % Make sure to update input/output
    Close_Connection(dac); % close connection to DAC
    Open_Connection(dac); % open connection to DAC
    Print_Info(dac);   % Print info about DAC if connection is open
    acquiredData = Acquire_Data(dac);
    [acquiredAveragedData, acquiredData] = Acquire_Averaged_Data(dac, nAverages)
    acquiredData = Acquire_FIFO_Data(dac);
    Free_FIFO_Buffer(dac);
    acquiredData = Acquire_Multi_Data(dac, errorCode);
    errorCode = Start_Multi_Mode(dac);

    function tl = get.triggerLevel(dac)
      
      mRegs = spcMCreateRegMap ();
      [err, tl.ext0_0] = spcm_dwGetParam_i32(dac.cardInfo.hDrv, mRegs('SPC_TRIG_EXT0_LEVEL0'));
      if err
        error('Could not read trigger level 0 of ext0');
      end
      [err, tl.ext0_1] = spcm_dwGetParam_i32(dac.cardInfo.hDrv, mRegs('SPC_TRIG_EXT0_LEVEL1'));
      if err
        error('Could not read trigger level 1 of ext0');
      end
      [err, tl.ext1_0] = spcm_dwGetParam_i32(dac.cardInfo.hDrv, mRegs('SPC_TRIG_EXT1_LEVEL1'));
      if err
        error('Could not read trigger level 0 of ext1');
      end   
    end

    % Set the timeout of the dac in ms

    function set.timeout(dac, to)

      mRegs = spcMCreateRegMap ();

      % ----- set timeout -----
      errorCode = spcm_dwSetParam_i32 (dac.cardInfo.hDrv, mRegs('SPC_TIMEOUT'), to);
      if (errorCode ~= 0)
          [success, dac.cardInfo] = spcMCheckSetError (errorCode, dac.cardInfo);
          spcMErrorMessageStdOut (dac.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
          return;
      else
        fprintf(['[M4DAC16] Successfully set timeout to ', num2str(to/1000), ' s.\n']);
      end

      dac.timeout = to;

    end

    % trigger level seems to reset itself every line
    function set.triggerLevel(dac, tl)
      
      mRegs = spcMCreateRegMap ();

      % Get boundaries and step size of trigger levels
      [err(1), ext0.min]  = spcm_dwGetParam_i32(dac.cardInfo.hDrv, mRegs('SPC_TRIG_EXT_AVAIL0_MIN'));
      [err(2), ext0.max]  = spcm_dwGetParam_i32(dac.cardInfo.hDrv, mRegs('SPC_TRIG_EXT_AVAIL0_MAX'));
      [err(3), ext0.step] = spcm_dwGetParam_i32(dac.cardInfo.hDrv, mRegs('SPC_TRIG_EXT_AVAIL0_STEP'));
      [err(4), ext1.min]  = spcm_dwGetParam_i32(dac.cardInfo.hDrv, mRegs('SPC_TRIG_EXT_AVAIL1_MIN'));
      [err(5), ext1.max]  = spcm_dwGetParam_i32(dac.cardInfo.hDrv, mRegs('SPC_TRIG_EXT_AVAIL1_MAX'));
      [err(6), ext1.step] = spcm_dwGetParam_i32(dac.cardInfo.hDrv, mRegs('SPC_TRIG_EXT_AVAIL1_STEP'));
      if max(err)
        error('Could not read available trigger levels from card');
      end

      % check if trigger levels are in range
      if (tl.ext0_0 < ext0.min)
        warning('trigger ext0_0 too low, rising to minimum');
        tl.ext0_0 = ext0.min;
      elseif (tl.ext0_0 > ext0.max)
        warning('trigger ext0_0 too high, rising to maximum');
        tl.ext0_0 = ext0.max;
      else
        nSteps = round((tl.ext0_0 - ext0.min)/ext0.step);
        t1.ext0_0 = ext0.min + nSteps * ext0.step;
      end

      % check if trigger levels are in range
      if (tl.ext0_1 < ext0.min)
        warning('trigger ext0_1 too low, rising to minimum');
        tl.ext0_1 = ext0.min;
      elseif (tl.ext0_1 > ext0.max)
        warning('trigger ext0_0 too high, rising to maximum');
        tl.ext0_1 = ext0.max;
      else
        nSteps = round((tl.ext0_1 - ext0.min)/ext0.step);
        t1.ext0_1 = ext0.min + nSteps * ext0.step;
      end

      % check if trigger levels are in range
      if (tl.ext1_0 < ext1.min)
        warning('trigger ext0_0 too low, rising to minimum');
        tl.ext1_0 = ext1.min;
      elseif (tl.ext1_0 > ext1.max)
        warning('trigger ext0_0 too high, rising to maximum');
        tl.ext1_0 = ext1.max;
      else
        nSteps = round((tl.ext1_0 - ext1.min)/ext0.step);
        t1.ext1_0 = ext1.min + nSteps * ext1.step;
      end

      % push all informations to card
      err2 = spcm_dwSetParam_i32(dac.cardInfo.hDrv, mRegs('SPC_TRIG_EXT0_LEVEL0'), int32(t1.ext0_0));
      err2 = err2 + spcm_dwSetParam_i32(dac.cardInfo.hDrv, mRegs('SPC_TRIG_EXT0_LEVEL1'), int32(t1.ext0_1));
      err2 = err2 + spcm_dwSetParam_i32(dac.cardInfo.hDrv, mRegs('SPC_TRIG_EXT1_LEVEL0'), int32(t1.ext1_0));

      if err2
        error('Could not set trigger levels');
      end

    end

    function set.triggerChannel(dac, tc)

      warning('Not tested yet.');

      [success, cardInfo] = spcMSetupTrigChannel(dac.cardInfo, ...
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
        dac.triggerChannel = tc;
      end

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Function which only modifies the channel sensitivity w/o touching any othe
    % r channel settings. With this we do not have to define the whole channel e
    % verytime we want to modify only the sensitivity
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.sensitivityPd(dac, sensitivityPd)

      if ~dac.beSilent
        fprintf('[M4DAC16] Setting channel 0 sensitivity.\n');
      end

      dac.channels(1).inputrange = sensitivityPd;
      dac.sensitivityPd = sensitivityPd;
    end
    
    function set.sensitivityUs(dac, sensitivityUs)

      if ~dac.beSilent
        fprintf('[M4DAC16] Setting channel 1 sensitivity.\n');
      end

      dac.channels(2).inputrange = sensitivityUs;
      dac.sensitivityUs = sensitivityUs;
    end

    % setting delay of data acquisition card
   %{
 function set.delay(dac, delay)
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
        dac.cardInfo.hDrv, ...
        dac.mRegs('SPC_TRIG_DELAY'), ... % defines the delay for the detected trigger events
        delay); % delay in samples

      if (errorCode ~= 0)
        error(['[M4DAC16] Could not set delay: ', errorCode]);
      else
        dac.delay = delay;
      end

    end

%}


    % Function to set sample rate of data acquisition card, takes care that we
    % do not exceed max and min limits and that we have an open connection
    function set.samplingRate(dac, samplingRate)

      dac.samplingRate = samplingRate;

      if (dac.isConnected == 0)
        error('[M4DAC16] No open connection.');
      else
        if (samplingRate < dac.cardInfo.minSamplerate)
          error('[M4DAC16] SamplingRate has to be >= %5.0f', ...
            dac.cardInfo.minSamplerate);
        elseif (samplingRate > dac.cardInfo.maxSamplerate)
          error('[M4DAC16] SamplingRate has to be <= %5.0f', ...
            dac.cardInfo.maxSamplerate);
        else

          if ~dac.beSilent
            fprintf('[M4DAC16] Setting sampling rate: %5.0f \n', samplingRate);
          end

          [success, dac.cardInfo] = spcMSetupClockPLL(dac.cardInfo, ...
            samplingRate, 0);

          if (success == 0)
            error(['[M4DAC16] Could not set the sampling rate: ', ...
              dac.cardInfo.errorText]);
          end
        end

      end

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Setting up the analog input channels, all at once. There will be a second
    % function named set.channel(dac, channel, id_channel) which can be used to
    % set up a single channel
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.channels(dac, channels)
      if ~dac.beSilent
        fprintf('[M4DAC16] Setting up all channels.\n');
      end
      % order of arguments:
      % (cardInfo, channel, path, inputRange, term, ACCoupning, BWLimit,
      % diffInput)

      % check if size of both arrays aggree
      if (size(channels) == size(dac.channels))
        % check if channel input type is correct (i.e. if it contains all requir
        % ed fields)


        dac.channels = channels;

        % Set all channels
        for (i= 0 : (dac.NO_CHANNELS - 1))
          [success, dac.cardInfo] = ...
            spcMSetupAnalogInputChannel(...
              dac.cardInfo, ...
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

%{
    % Set card to multoIO mode
    function set.multiIO(dac, multiIO)

      if ~dac.beSilent
        fprintf('[FastDAQ] Setting up multiIO mode.\n');
      end

      dac.multiIO = multiIO;

      [success, dac.cardInfo] = ...
        spcMSetupMultiIO (    ...
          dac.cardInfo,       ...
          dac.multiIO.modeX0, ...
          dac.multiIO.modeX1);
          % (dac.cardInfo, modeX0, modeX1)

      if (success == 0)
        error('[FastDAQ] Could not setup MultiIO mode.');
      end

    end
%}


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Generation mode setup: defines the generation mode for the next run. The f
    % unctions are only used with the genertor or I/O cards. It is onlz possible
    % to use one generation mode at a time.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.acquisitionMode(dac, acquisitionMode)

      if ~dac.beSilent
        fprintf('[M4DAC16] Setting up data acquisistion mode.\n');
      end

      dac.acquisitionMode = acquisitionMode;

      [success, dac.cardInfo] = spcMSetupModeRecStdSingle(...
        dac.cardInfo,...
        dac.acquisitionMode.chMaskH, ...
        dac.acquisitionMode.chMaskL, ...
        dac.acquisitionMode.nSamples, ...
        dac.acquisitionMode.postSamples);

      if (success == 0)
          error(['[M4DAC16] Error while setting up data acquisisiton mode: ', ...
            dac.cardInfo.errorText]);
      end

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Setting up the external trigger of the data acquisistion card.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.externalTrigger(dac, externalTrigger)

      if ~dac.beSilent
        fprintf('[M4DAC16] Setting up the external trigger.\n')
      end

      [success, dac.cardInfo] = spcMSetupTrigExternal(...
        dac.cardInfo, ...
        externalTrigger.extMode, ... % 40510 = SPC_TRIG_EXT0_MODE
        externalTrigger.trigTerm, ...
        externalTrigger.pulseWidth, ...
        externalTrigger.singleSrc, ...
        externalTrigger.extLine);

      if (success == 0)
        error('[M4DAC16] Could not set up the external trigger correctly.');
      else
        dac.externalTrigger = externalTrigger;
      end

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set datatype (0 --> 16 bit integer, 1 --> float)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.dataType(dac, dataType)

      if (dataType == 0)
        % 16 bit integer
        dac.dataType = 0;
        if ~dac.beSilent
          fprintf('[M4DAC16] Setting the datatype to 16 bit integer.\n');
        end
      elseif (dataType == 1)
        % voltage as single
        dac.dataType = 1;
        if ~dac.beSilent
          fprintf('[M4DAC16] Setting the datatype to voltage.\n');
        end
      else
        % invalid argument
        error('[M4DAC16] You passed an invalid option as dataType.');
      end

    end

  end

end

% ~ end of file
