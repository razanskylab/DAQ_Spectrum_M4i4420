% File: Handle_Error.m @ FastDAQ
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description:

function Handle_Error(DAQ,errCode)
  if (errCode ~= 0)
    [success, DAQ.cardInfo] = spcMCheckSetError(errCode, DAQ.cardInfo);
    if errCode == 263
      short_warn('[M4DAC16] Timeout while waiting for a trigger!');
    elseif errCode == 259
      short_warn('[M4DAC16] Command sequence is not allowed!');
    else
      errorMessage = ['DAQ Error: ' DAQ.Parse_Error_Code(errCode)];
      error(errorMessage);
    end
    drawnow();
  end

end
