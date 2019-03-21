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
DAQ.FiFo.nShots = 1000;
DAQ.FiFo.shotSize = 1024*2; % size of on shot...
DAQ.FiFo.nChannels = 2;
DAQ.Setup_FIFO_Multi_Mode();

% SETUP TRIGGER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% trigger settings
externalTrigger.extMode = 1;
externalTrigger.trigTerm = 1;
externalTrigger.pulseWidth = 0;
externalTrigger.singleSrc = 1;
externalTrigger.extLine = 0;
DAQ.Setup_External_Trigger(externalTrigger); % (0 is big sma, 1 is small MMCX connector)

% SETUP ANALONG INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% channel settings
pdSettings.path = 0;
pdSettings.inputrange = 10000;
pdSettings.term = 1;
pdSettings.acCpl = 0;
pdSettings.inputoffset = 0;
pdSettings.bwLim = 0;

oaSettings.path = 1;
oaSettings.inputrange = 1000;
oaSettings.term = 0;
oaSettings.acCpl = 1;
oaSettings.inputoffset = 0;
oaSettings.bwLim = 0;

DAQ.Setup_Analog_Input_Channel(1,pdSettings)
DAQ.Setup_Analog_Input_Channel(0,oaSettings)

fprintf('Pre trigger count: %i\n',DAQ.triggerCount);

ch0 = zeros(DAQ.FiFo.shotSize,DAQ.FiFo.nShots,'int16');
ch1 = zeros(DAQ.FiFo.shotSize,DAQ.FiFo.nShots,'int16');
tsData = [];
tic

% DO NOT CHANGE THE ORDER OF THESE THREE COMMANDS!
DAQ.Enable_Time_Stamps(); % needs to be before start
DAQ.Start();
DAQ.Enable_Trigger(); % can be with start (Full_Start) or after but NOT before

%% ---------------------------------------------------------------------------
for iBlock = 1:DAQ.FiFo.nBlocks
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
  tsData = [tsData tsShots];
end

% FIXME make sure to poll last data here
tsData = [tsData DAQ.Poll_Time_Stamp_Data()];
toc
%% ---------------------------------------------------------------------------

DAQ.Free_FIFO_Buffer()

fprintf('Final trigger count: %i\n',DAQ.triggerCount);

DAQ.Stop();

if DAQ.FiFo.nChannels == 2
  subplot(2,1,1)
  imagesc(ch0);
  subplot(2,1,2)
  imagesc(ch1);
else
  imagesc(ch0);
end
