% File: Acquire_Multi_Data.m @ M4DAC16
% Author: Urs Hofmann
% Mail: hofmannu@student.ethz.ch
% Date: 23. Nov 2018

function acquiredData = Acquire_Multi_Data(dac)

  errorCode = spcm_dwSetParam_i32(...
      dac.cardInfo.hDrv, ...
      dac.mRegs('SPC_M2CMD'), ...
      dac.mRegs('M2CMD_CARD_WAITREADY'));  % 100 = SPC_M2CMD
  if ((errorCode ~= 0) & (errorCode ~= dac.mErrors('ERR_TIMEOUT')))
    [success, cardInfo] = spcMCheckSetError (errorCode, dac.cardInfo);
    spcMErrorMessageStdOut (dac.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
  end

  if (errorCode == dac.mErrors('ERR_TIMEOUT'))
     spcMErrorMessageStdOut (dac.cardInfo, ' ... Timeout occurred !!!', false);
     return;
  else
    %fprintf (' Starting the DMA transfer and waiting until data is in PC memory ...\n');
    [errorCode, Dat_Ch0, Dat_Ch1] = ...
    spcm_dwGetData( ...                   % returns channel data in order
      dac.cardInfo.hDrv, ...              % physical address of card (?)
      0, ...                     % offet start address
      dac.cardInfo.setMemsize, ... % length of buffer to read
      dac.cardInfo.setChannels, ...                % number of analog channels
      dac.dataType);                      % datatype to read

    if (errorCode ~= 0)
        [success, dac.cardInfo] = spcMCheckSetError (errorCode, dac.cardInfo);
        spcMErrorMessageStdOut (dac.cardInfo, 'Error: spcm_dwGetData:\n\t', true);
        return;
    end
  end

  acquiredData = [Dat_Ch0; Dat_Ch1];

end