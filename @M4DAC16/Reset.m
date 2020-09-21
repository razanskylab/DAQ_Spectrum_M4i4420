% File: Reset.m @ M4DAC16
% Author: Urs Hofmann
% Mail: hofmannu@student.ethz.ch
% Date: 23. Nov 2018

% Description: Performs a software reset of the card

function Reset(Obj)
	tic;
	Obj.VPrintF_With_ID('Software reset...')
	errorCode = spcm_dwSetParam_i32(Obj.cardInfo.hDrv, Obj.mRegs('SPC_M2CMD'), Obj.mRegs('M2CMD_CARD_RESET'));
	if (errorCode ~= 0)
		[~, Obj.cardInfo] = spcMCheckSetError (errorCode, Obj.cardInfo);
    	spcMErrorMessageStdOut (Obj.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
		error('Could not perform software reset.');
	else
		Obj.Done();
	end
end
