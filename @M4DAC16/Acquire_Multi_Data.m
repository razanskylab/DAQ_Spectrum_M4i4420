% File: Acquire_Multi_Data.m @ M4Obj16
% Author: Urs Hofmann
% Mail: hofmannu@student.ethz.ch
% Date: 23. Nov 2018

function varargout = Acquire_Multi_Data(Obj)
  tic;
  Obj.VPrintf('[M4DAC16] Reading back multi-data... ');

  % wait for new data to be ready...
  waitReadyError = spcm_dwSetParam_i32(...
      Obj.cardInfo.hDrv, ...
      Obj.mRegs('SPC_M2CMD'), ...
      Obj.mRegs('M2CMD_CARD_WAITREADY'));  % 100 = SPC_M2CMD

  switch waitReadyError
  case 0 % all good, get our data
    [getDataError, Dat_Ch0, Dat_Ch1] = spcm_dwGetData(... % returns channel data in order
      Obj.cardInfo.hDrv, ... % physical address of card
      0, ... % offet start address
      Obj.cardInfo.setMemsize, ... % length of buffer to read
      Obj.cardInfo.setChannels, ... % number of analog channels
      Obj.dataType); % datatype to read
      % check for errors again...
      if (getDataError ~= 0)
        Obj.Handle_Error(getDataError);
        Dat_Ch0 = NaN;
        Dat_Ch1 = NaN;
      end
  otherwise % handle all other errors, but those are rare
    Obj.Handle_Error(waitReadyError);
    Dat_Ch0 = NaN;
    Dat_Ch1 = NaN;
  end


  if nargout == 1
    varargout{1} = [Dat_Ch0; Dat_Ch1];
  elseif nargout == 2
    varargout{1} = Dat_Ch0;
    varargout{2} = Dat_Ch1;
  else
    error('Too many output arguments!');
  end
  Obj.VPrintf('done!\n');

end
