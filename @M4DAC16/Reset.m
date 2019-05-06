% File: Reset.m @ M4DAC16
% Author: Urs Hofmann
% Mail: hofmannu@student.ethz.ch
% Date: 23. Nov 2018

% Description: Performs a software reset of the card

function Reset(DAQ)

	errorCode = spcm_dwSetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_M2CMD'), DAQ.mRegs('M2CMD_CARD_RESET'));

	if (errorCode ~= 0)
		[success, DAQ.cardInfo] = spcMCheckSetError (errorCode, DAQ.cardInfo);
    	spcMErrorMessageStdOut (DAQ.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
		error('Could not perform software reset.');
	else
    	fprintf('[M4DAC16] Software reset successfull.\n')
	end

end
