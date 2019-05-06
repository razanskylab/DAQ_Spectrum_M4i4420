% (johannesrebling@gmail.com), 2018

clearvars -except 'DAQ';
if exist('DAQ') == 1 % check variable exists
  short_warn('Using existing DAQ!');
else
  DAQ = M4DAC16();
end
DAQ.Reset();

% fifo settings
DAQ.FiFo = FiFoSettings();
DAQ.FiFo.nShots = 5000;
DAQ.FiFo.shotSize = 1024*2; % size of on shot...
DAQ.FiFo.nChannels = 2;

% trigger settings
externalTrigger.extMode = 1;
externalTrigger.trigTerm = 1;
externalTrigger.pulseWidth = 0;
externalTrigger.singleSrc = 1;
externalTrigger.extLine = 0;

% channel settings
pdSettings.path = 0;
pdSettings.inputrange = 10000;
pdSettings.term = 1;
pdSettings.acCpl = 0;
pdSettings.inputoffset = 0;
pdSettings.bwLim = 0;

usSettings.path = 1;
usSettings.inputrange = 1000;
usSettings.term = 0;
usSettings.acCpl = 1;
usSettings.inputoffset = 0;
usSettings.bwLim = 0;

% Transfer / Apply Settings to card, setup trigger and analog inputs
DAQ.Setup_External_Trigger(externalTrigger); % (0 is big sma, 1 is small MMCX connector)
DAQ.Setup_Analog_Input_Channel(0,usSettings)
DAQ.Setup_Analog_Input_Channel(1,pdSettings)

%% ---------------------------------------------------------------------------
% ACQUISITION SPECIFIC CODE STARTS HERE
%% ---------------------------------------------------------------------------

% DO NOT CHANGE THE ORDER OF THESE THREE COMMANDS!
DAQ.Enable_Time_Stamps(); % needs to be before start
DAQ.Setup_FIFO_Multi_Mode();

DAQ.Start(); % now settings can't be changed anymore, but trigger not activated yet!

DAQ.VPrintF('[M4DAC16] Allocating Matlab memory...'); tic;
ch0 = zeros(DAQ.FiFo.shotSize,DAQ.FiFo.nShots,'int16');
ch1 = zeros(DAQ.FiFo.shotSize,DAQ.FiFo.nShots,'int16');
tsData = [];
  % we append when new data comes in, allocation does not matter for this one...
DAQ.Done();

DAQ.Enable_Trigger(); % can be with start (Full_Start) or after but NOT before

%% ---------------------------------------------------------------------------
DAQ.VPrintF('[M4DAC16] Starting data acquisition!\n'); tic;

cpb = prep_console_progress_bar(DAQ.FiFo.nBlocks);
cpb.start();
tic
for iBlock = 1:DAQ.FiFo.nBlocks
  if ~mod(iBlock,25)
    text = sprintf('Block %d/%d', iBlock, DAQ.FiFo.nBlocks);
    cpb.setValue(iBlock);  cpb.setText(text);
  end

  DAQ.FiFo.currentBlock = iBlock; % required to update depended properties!
  switch DAQ.FiFo.nChannels
  case 1
    [tsShots,ch0Shots] = DAQ.Get_Next_Fifo_Block();
    ch0(:,DAQ.FiFo.currentShots) = ch0Shots;
  case 2
    [tsShots,ch0Shots,ch1Shots] = DAQ.Get_Next_Fifo_Block();
    ch0(:,DAQ.FiFo.currentShots) = ch0Shots;
    ch1(:,DAQ.FiFo.currentShots) = ch1Shots;
  end
  if ~isempty(tsShots) % we got time stamps (does not happen every block)
    tsData = [tsData tsShots];
  end
    % numel(tsShots)
  % tsData(DAQ.FiFo.currentShots) = tsShots;
end
cpb.stop();
fprintf('\n');

% poll last TS data here
tsLastShots = DAQ.Poll_Time_Stamp_Data();
tsData = [tsData tsLastShots];
%% ---------------------------------------------------------------------------

if (DAQ.triggerCount ~= DAQ.FiFo.nShots)
  warnText = sprintf('Trigger count: %i Expected shots: %i!\n',...
  DAQ.triggerCount,DAQ.FiFo.nShots)
  DAQ.Verbose_Warn(warnText);
end
DAQ.Free_FIFO_Buffer()
DAQ.Stop();

%% ---------------------------------------------------------------------------
% ACQUISITION SPECIFIC CODE ENDS HERE
%% ---------------------------------------------------------------------------
DAQ.VPrintF('[M4DAC16] Data acquisition completed in %2.2f s!\n',toc);
if DAQ.FiFo.nChannels == 2
  subplot(2,1,1)
  imagesc(ch0);
  subplot(2,1,2)
  imagesc(ch1);
else
  imagesc(ch0);
end
