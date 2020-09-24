function Setup_Multi_Mode(Obj)

	% Check if card type supports this
	if (Obj.cardInfo.cardFunction ~= Obj.mRegs('SPCM_FEAT_MULTI'))
		error('Data acquisition card does not support multiple recording.');
	end
	tic;

	nShots = Obj.multiMode.memsamples ./ Obj.multiMode.segmentsize;
	nBytes = Obj.multiMode.memsamples .* 2;
	byteStr =  num2sip(nBytes);
	Obj.VPrintF_With_ID('Setting up multi mode:  \n');
	Obj.VPrintF_With_ID('          # of shots: %i \n',nShots);
	Obj.VPrintF_With_ID('   # of samples/shot: %i \n',Obj.multiMode.segmentsize);
	Obj.VPrintF_With_ID('     # of bytes/shot: %i \n',Obj.multiMode.segmentsize*2);
	Obj.VPrintF_With_ID('    # of total bytes: %sB\n',byteStr);
	
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
		error('   Could not setup multi mode.');
	else
		Obj.VPrintF_With_ID('Setting up multi mode ');
		Obj.Done();
	end

end