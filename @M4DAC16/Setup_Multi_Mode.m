% File: Setup_Multi_mode.m @ M4DAC16
% Author: Urs Hofmann
% Mail: hofmannu@ethz.ch
% Date: 20.02.2021

% Description: Starts multimode data acquisition

function Setup_Multi_Mode(Obj)

	% Check if card type supports this
	if (Obj.cardInfo.cardFunction ~= Obj.mRegs('SPCM_FEAT_MULTI'))
		error('Data acquisition card does not support multiple recording.');
	end
	tic;

	nShots = Obj.multiMode.memsamples ./ uint64(Obj.multiMode.segmentsize);
	nBytes = Obj.multiMode.memsamples .* 2;
	Obj.VPrintf('[M4DAC16] Setting up multi mode:  \n');
	Obj.VPrintf('[M4DAC16] 	# of shots: %i \n',nShots);
	Obj.VPrintf('[M4DAC16]  # of samples/shot: %i \n',Obj.multiMode.segmentsize);
	Obj.VPrintf('[M4DAC16]  # of bytes/shot: %i \n',Obj.multiMode.segmentsize*2);
	Obj.VPrintf('[M4DAC16]  # of total bytes: %iB\n', nBytes);
	
	[success, Obj.cardInfo] = spcMSetupModeRecStdMulti(...
		Obj.cardInfo, ...
		Obj.multiMode.chMaskH, ...
		Obj.multiMode.chMaskL, ...
		Obj.multiMode.memsamples, ... % SPC_MEMSIZE
		Obj.multiMode.segmentsize, ... % SPC_SEGMENTSIZE
		Obj.multiMode.postsamples); % SPC_POSTTRIGGER

	% SPC_MEMSIZE: Defines the total number of samples to be recorded per channel
	% SPC_SEGMENTSIZE: size of one segment/shot to be recorded per trigger event
	% SPC_POSTTRIGGER: defines the number of samples to be recorded per 
		% channel after trigger event

	if (success ~= 1)
		error('Could not setup multi mode.');
	else
		Obj.VPrintf('[M4DAC16] Multimode successfully set up.\n');
	end

end