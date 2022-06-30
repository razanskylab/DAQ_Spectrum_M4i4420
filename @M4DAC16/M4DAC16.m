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

classdef M4DAC16 < handle


  % Properties of data acquisition card
  properties
    classId = '[DAQ]'; % used for VPrintF_With_ID_W   
    cardInfo = []; % stores the informations about the card in a struct

    FiFo(1, 1) FiFoSettings; % subclass for storing fifo settings
    comSuccess(1,1) {mustBeNumericOrLogical} = 1; % either 0 or 1

    samplingRate(1,1) {mustBeInteger,mustBeNonnegative}; % [Hz]
    timeout(1,1) {mustBeInteger,mustBeNonnegative}; % [ms] 0 means disabled
    delay(1,1) {mustBeInteger, mustBeNonnegative}; % Obj trigger delay in samples
    dataType(1, 1) {mustBeNumeric} = 0;
      % 0: data are returned as 16 bit integer
      % 1: data are returned as voltage (single)

    % offset start address for data chunk to be read
    % NOTE ignored in FIFO mode
    offset(1, 1) {mustBeNumeric} = 0;
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

    StausData = []; % used during fifo acquisition to store info on DAQ 
      % status during fifo, see Wait_FiFo_Data() for how it's filled
    StausFigure = [];
    flagVerbose(1, 1) logical = 1; % turn verbose output on / off
    flagDisplay(1, 1) logical; % turn graphicla output on / off
  end

  properties (Dependent = true)
    triggerCount; % read only, read from card
    tsBytesAvailable; % available time stamp bytes
    bytesAvailable; % available time stamp bytes
    currentError;
    sensitivity; % sensitivty of DAQ channel(s) read back from DAQ
    isConnected(1,1) {mustBeNumericOrLogical};
    Status;
    isBlockReady; % included in Status, but only checks for this...
  end

  properties (Constant = true)
    NO_CHANNELS = 2;
    cardPort = '\dev\spcm0';

    CONNECT_ON_STARTUP = 1;
    BYTES_PER_SAMPLE = 2; % [Byte] 16 bit = 2 bytes...
    RESOLUTION = 16; % 16 bit ADC resolution

    % FLAGS for convenience
    SAMPLE_DATA = 0;
    TIMESTAMP_DATA = 1;
    TIME_OUT = 5000; % in ms
    SAMPLING_RATE = 250e6; % in Hz
    DELAY = 0;
    TIME_STAMP_SIZE = 8; % [Byte] time stamp is 64 bit -> 8 byte
    PRE_TRIGGER = 16; % in samples, used for multi and fifo mode...
  end

  methods
    % Constructor
    function Obj = M4DAC16(doConnect)
      if nargin == 0
        doConnect = Obj.CONNECT_ON_STARTUP;
      end

      if doConnect
        Obj.Open_Connection();
        Obj.Reset(); % recommended by manual
        Obj.samplingRate = Obj.SAMPLING_RATE;
        Obj.timeout = Obj.TIME_OUT;
      else
        Obj.VPrintf('[M4DAC16] Initialized but not connected yet.\n');
      end
    end

    % Save function
    function saveObj = saveobj(~)
      saveObj = [];
    end

    % Destructor
    function delete(Obj)
      if Obj.isConnected
        Obj.Close_Connection();
      end
    end
 
    % Set/Get the timeout of the Obj in ms
    function set.timeout(Obj, timeOut)
      if Obj.isConnected
        errorCode = spcm_dwSetParam_i32 (Obj.cardInfo.hDrv, ...
          Obj.mRegs('SPC_TIMEOUT'), timeOut); %#ok<*MCSUP>
        if (errorCode ~= 0) 
            [~, Obj.cardInfo] = spcMCheckSetError (errorCode, Obj.cardInfo);
            spcMErrorMessageStdOut (Obj.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
            return;
        else
          Obj.VPrintf('[M4DAC16] Timeout set timeOut %f s.\n',single(timeOut / 1000));
        end
      else
        short_warn('Need to connect to DAQ before trying to set values!');
      end
    end

    % return defined timeout
    function timeout = get.timeout(Obj)
      timeout = [];
      if Obj.isConnected
        [errCode, timeout] = spcm_dwGetParam_i32(Obj.cardInfo.hDrv, ...
          Obj.mRegs('SPC_TIMEOUT'));
        if errCode
          timeOut = NaN; 
          Obj.Verbose_Warn('Could not read timeout!');
          Obj.Handle_Error();
        end
      end
    end
    
    function isConnected = get.isConnected(Obj)
      isConnected = ~isempty(Obj.cardInfo) && ~(Obj.cardInfo.hDrv == 0);
    end

    function sensitivity = get.sensitivity(Obj)
      if Obj.isConnected
        sensitivity = zeros(1,Obj.NO_CHANNELS);
        for iCh = 1:Obj.NO_CHANNELS
          chStr = sprintf('SPC_AMP%i',iCh-1);
          [errCode, tempSens] = spcm_dwGetParam_i64(Obj.cardInfo.hDrv, Obj.mRegs(chStr));
          if errCode 
            sensitivity(iCh) = NaN;
            short_warn(sprintf('Failed to read sensitivity of channel %i!',iCh-1));
          else
            sensitivity(iCh) = tempSens;
          end
        end
      else
        short_warn('Need to connect to DAQ before trying to set values!');
      end
    end

    % setting delay of data acquisition card
    function set.delay(Obj, delay)
      if Obj.isConnected
        Obj.VPrintf(['[M4DAC16] Setting the delay to ', num2str(delay), ' samples.\n']);

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
      else
        short_warn('Need to connect to DAQ before trying to set values!');
      end
    end

    %---------------------------------------------------------------------------
    % Function to set sample rate of data acquisition card, takes care that we
    % do not exceed max and min limits and that we have an open connection
    function set.samplingRate(Obj, samplingRate)
      if Obj.isConnected
        maxRate = Obj.cardInfo.maxSamplerate;

        if ~Obj.isConnected
          warning('[M4DAC16] No open connection.');
        else
          if (samplingRate < Obj.cardInfo.minSamplerate)
           warning('[M4DAC16] SamplingRate has to be >= %5.0f', ...
              Obj.cardInfo.minSamplerate);
            samplingRate = Obj.cardInfo.minSamplerate;
          elseif (samplingRate > maxRate)
            warning('[M4DAC16] SamplingRate has to be <= %5.0f', ...
              maxRate);
            samplingRate = maxRate;
          end

          if rem(maxRate,samplingRate)
            samplingRate = maxRate ./ floor(maxRate / samplingRate);
              % sets to next higher allowed sampling rate
            warnText = sprintf('Using next higher allowed sampling rate (%2.1fMHz)',samplingRate*1e-6);
            warning(warnText);
          end

          Obj.VPrintf('[M4DAC16] Setting sampling rate: %2.1fMHz \n', samplingRate*1e-6);

          [success, Obj.cardInfo] = spcMSetupClockPLL(Obj.cardInfo, samplingRate, 0);

          if ~success
            Obj.samplingRate = NaN;
            error(['[M4DAC16] Could not set the sampling rate:\n', ...
              Obj.cardInfo.errorText]);
          else
            Obj.samplingRate = samplingRate;
          end
        end
      else
        short_warn('Need to connect to DAQ before trying to set values!');
      end
    end

    %---------------------------------------------------------------------------
    function set.acquisitionMode(Obj, acquisitionMode)
      Obj.VPrintf('[M4DAC16] Setting up data acquisistion mode.\n');

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

    %---------------------------------------------------------------------------
    function set.externalTrigger(Obj, externalTrigger)
      Obj.Setup_External_Trigger_Level(externalTrigger);
      Obj.externalTrigger = externalTrigger;
    end

    %---------------------------------------------------------------------------
    % Set datatype (0 --> 16 bit integer, 1 --> float)
    function set.dataType(Obj, dataType)
      if (dataType == 0)
        % 16 bit integer
        Obj.dataType = 0;
        Obj.VPrintf('[M4DAC16] Setting the datatype to 16 bit integer.\n');
      elseif (dataType == 1)
        % voltage as single
        Obj.dataType = 1;
        Obj.VPrintf('[M4DAC16] Setting the datatype to voltage.\n');
      else
        % invalid argument
        error('[M4DAC16] You passed an invalid option as dataType.');
      end
    end

    %---------------------------------------------------------------------------
    function triggerCount = get.triggerCount(Obj)
      triggerCount = [];
      if Obj.isConnected
        [errCode, triggerCount] = spcm_dwGetParam_i64(Obj.cardInfo.hDrv, ...
          Obj.mRegs('SPC_TRIGGERCOUNTER'));
        if errCode
          Obj.Verbose_Warn('Could not read triggerCount!');
          Obj.Handle_Error(errCode);
          triggerCount = NaN; 
        end
      end
    end

    %---------------------------------------------------------------------------
    function bytesAvailable = get.bytesAvailable(Obj)
      bytesAvailable = [];
      if Obj.isConnected
        [errCode, bytesAvailable] = spcm_dwGetParam_i64(Obj.cardInfo.hDrv, ...
          Obj.mRegs('SPC_DATA_AVAIL_USER_LEN'));
        if errCode
          Obj.Verbose_Warn('Could not read bytesAvailable (SPC_DATA_AVAIL_USER_LEN)!');
          Obj.Handle_Error();
          bytesAvailable = NaN; 
        end
      end
    end

    %---------------------------------------------------------------------------
    function tsBytesAvailable = get.tsBytesAvailable(Obj)
      tsBytesAvailable = [];
      if Obj.isConnected
        [errCode, tsBytesAvailable] = spcm_dwGetParam_i64(Obj.cardInfo.hDrv, ...
          Obj.mRegs('SPC_TS_AVAIL_USER_LEN'));
        if errCode
          Obj.Verbose_Warn('Could not read tsBytesAvailable (SPC_TS_AVAIL_USER_LEN)!');
          Obj.Handle_Error();
          tsBytesAvailable = NaN; 
        end
      end
    end
    
    %---------------------------------------------------------------------------
    function currentError = get.currentError(Obj)
      [currentError, ~, ~, Obj.cardInfo.errorText] = ...
        spcm_dwGetErrorInfo_i32(Obj.cardInfo.hDrv);
    end
    %---------------------------------------------------------------------------
    function [isBlockReady] = get.isBlockReady(Obj)
      [~, regValue] = spcm_dwGetParam_i64(Obj.cardInfo.hDrv, ...
        Obj.mRegs('SPC_M2STATUS'));
      regValue = int32(regValue);
      isBlockReady = logical(bitand(regValue, ...
        Obj.mRegs('M2STAT_DATA_BLOCKREADY')));
    end
    %---------------------------------------------------------------------------
    function [Status] = get.Status(Obj)
      if Obj.isConnected
        [errorVal, regValue] = spcm_dwGetParam_i64(Obj.cardInfo.hDrv, ...
                                              Obj.mRegs('SPC_M2STATUS'));
        if errorVal
          Obj.Handle_Error(errorVal);
          Status = NaN;
        else
          regValue = int32(regValue);
          Status.regValue = regValue; % return raw value
          Status.isConnected = true; % if we are here, we are connected
          % now we analyze the individual bits, as per definition in the 
          % manual we get them via hex values (but really it's just the
          % individual bits...
          % general status and trigger related ---------------------------------
          Status.PRETRIGGER = logical(bitand(regValue, ...
                                        Obj.mRegs('M2STAT_CARD_PRETRIGGER')));
            % Acquisition modes only: the pretrigger area has been filled.
          Status.TRIGGER = logical(bitand(regValue, ...
                                        Obj.mRegs('M2STAT_CARD_TRIGGER')));
            % The first trigger has been detected.
          Status.READY = logical(bitand(regValue, ...
                                        Obj.mRegs('M2STAT_CARD_READY')));
            % The card has finished its run and is ready.
          Status.SEGMENT_PRETRG = logical(bitand(regValue, ...
                                        Obj.mRegs('M2STAT_CARD_SEGMENT_PRETRG')));
            % the pretrigger area of one segment has been filled.

          % data transfer related ----------------------------------------------
          Status.BLOCKREADY = logical(bitand(regValue, ...
                                        Obj.mRegs('M2STAT_DATA_BLOCKREADY')));
            % The next data block is available
          Status.END = logical(bitand(regValue, ...
                                        Obj.mRegs('M2STAT_DATA_END')));
            % The data transfer has completed.
          Status.OVERRUN = logical(bitand(regValue, ...
                                        Obj.mRegs('M2STAT_DATA_OVERRUN')));
            % The data transfer had on overrun while doing FIFO transfer
          Status.DATA_ERROR = logical(bitand(regValue, ...
                                        Obj.mRegs('M2STAT_DATA_ERROR')));
            % An internal error occurred 

          % fifo transfer related? ---------------------------------------------
          Status.EXTRA_BLOCKREADY = logical(bitand(regValue, ...
                                        Obj.mRegs('M2STAT_EXTRA_BLOCKREADY')));
            % next data block as defined in the notify size is available
          Status.EXTRA_END = logical(bitand(regValue, ...
                                        Obj.mRegs('M2STAT_EXTRA_END')));
            % The data transfer has completed
          Status.EXTRA_OVERRUN = logical(bitand(regValue, ...
                                        Obj.mRegs('M2STAT_EXTRA_OVERRUN')));
            % The data transfer had on overrun while doing FIFO transfer
          Status.EXTRA_ERROR = logical(bitand(regValue, ...
                                        Obj.mRegs('M2STAT_EXTRA_ERROR')));
            % An internal error occurred 
        end
      else
        Status = [];
      end
    end

    %---------------------------------------------------------------------------
    % auto-setup multimode when setting multi-mode settings...
    function set.multiMode(Obj, newMultimodeSettings)
      Obj.multiMode = newMultimodeSettings;
      Obj.Setup_Multi_Mode();
    end
  end
end
