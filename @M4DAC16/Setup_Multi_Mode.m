function Setup_Multi_Mode(dac)

	% Check if card type supports this
	if (dac.cardInfo.cardFunction ~= dac.mRegs('SPCM_FEAT_MULTI'))
		error('Data acquisition card does not support multiple recording.');
	end

	fprintf('[M4DAC16] Setting up multi mode... ');
	[success, dac.cardInfo] = spcMSetupModeRecStdMulti(...
		dac.cardInfo, ...
		dac.multiMode.chMaskH, ...
		dac.multiMode.chMaskL, ...
		dac.multiMode.memsamples, ... % SPC_MEMSIZE
		dac.multiMode.segmentsize, ... % SPC_SEGMENTSIZE
		dac.multiMode.postsamples); % SPC_POSTTRIGGER

	% SPC_MEMSIZE: Defines the total number of samples to be recorded per channel
	% SPC_SEGMENTSIZE: size of one segment to be recorded at trigger event
	% SPC_POSTTRIGGER: defines the number of channel to be recorded per channel after trigger event

	if (success ~= 1)
		error('[M4DAC16] Could not setup multi mode.');
	else
		fprintf(' success!\n')
	end

end