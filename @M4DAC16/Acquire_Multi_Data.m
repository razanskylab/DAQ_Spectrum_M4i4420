% File: Acquire_Multi_Data.m @ M4Obj16
% Author: Urs Hofmann
% Mail: hofmannu@student.ethz.ch
% Date: 23. Nov 2018

function varargout = Acquire_Multi_Data(Obj)

  Obj.VPrintF_With_ID('Reading back multi-data...');
  errorCode = spcm_dwSetParam_i32(...
      Obj.cardInfo.hDrv, ...
      Obj.mRegs('SPC_M2CMD'), ...
      Obj.mRegs('M2CMD_CARD_WAITREADY'));  % 100 = SPC_M2CMD
  if ((errorCode ~= 0) && (errorCode ~= Obj.mErrors('ERR_TIMEOUT')))
    [~, ~] = spcMCheckSetError (errorCode, Obj.cardInfo);
    spcMErrorMessageStdOut (Obj.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
  end

  if (errorCode == Obj.mErrors('ERR_TIMEOUT'))
     spcMErrorMessageStdOut (Obj.cardInfo, ' ... Timeout occurred !!!', false);
     return;
  else
    %fprintf (' Starting the DMA transfer and waiting until data is in PC memory ...\n');
    [errorCode, Dat_Ch0, Dat_Ch1] = ...
    spcm_dwGetData(... % returns channel data in order
      Obj.cardInfo.hDrv, ... % physical address of card (?)
      0, ... % offet start address
      Obj.cardInfo.setMemsize, ... % length of buffer to read
      Obj.cardInfo.setChannels, ... % number of analog channels
      Obj.dataType); % datatype to read

    if (errorCode ~= 0)
        [~, Obj.cardInfo] = spcMCheckSetError (errorCode, Obj.cardInfo);
        spcMErrorMessageStdOut (Obj.cardInfo, 'Error: spcm_dwGetData:\n\t', true);
        return;
    end
  end

  if nargout == 1
    varargout{1} = [Dat_Ch0; Dat_Ch1];
  elseif nargout == 2
    varargout{1} = Dat_Ch0;
    varargout{2} = Dat_Ch1;
  else
    error('Too many output arguments!');
  end
  Obj.Done();

end
