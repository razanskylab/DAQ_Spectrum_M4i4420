function Setup_Multi_Mode(Obj)

	% Check if card type supports this
	if (Obj.cardInfo.cardFunction ~= Obj.mRegs('SPCM_FEAT_MULTI'))
		error('Data acquisition card does not support multiple recording.');
	end

	tic;
    Obj.VPrintF_With_ID('Setting up multi mode... ');
	[success, Obj.cardInfo] = spcMSetupModeRecStdMulti(...
		Obj.cardInfo, ...
		Obj.multiMode.chMaskH, ...
		Obj.multiMode.chMaskL, ...
		Obj.multiMode.memsamples, ... % SPC_MEMSIZE
		Obj.multiMode.segmentsize, ... % SPC_SEGMENTSIZE
		Obj.multiMode.postsamples); % SPC_POSTTRIGGER

	% SPC_MEMSIZE: Defines the total number of samples to be recorded per channel
	% SPC_SEGMENTSIZE: size of one segment to be recorded at trigger event
	% SPC_POSTTRIGGER: defines the number of channel to be recorded per channel after trigger event

	if (success ~= 1)
		error('   Could not setup multi mode.');
	else
		Obj.Done();
	end

end