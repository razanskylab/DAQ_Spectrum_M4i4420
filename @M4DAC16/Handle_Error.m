% File: Handle_Error.m @ FastDAQ
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description:

function Handle_Error(DAQ,errCode)
  if (errCode ~= 0)
    fprintf('\n');
    errorMessage = sprintf('[DAQ] Error code %i!',errCode);
    short_warn(errorMessage);
    if (errCode == 263)
      short_warn('[DAQ] Timout while waiting for trigger event!');
      [success, DAQ.cardInfo] = spcMCheckSetError(errCode, DAQ.cardInfo);
    elseif (errCode == 259)
      short_warn('[DAQ] Command sequence is not allowed!');
      [success, DAQ.cardInfo] = spcMCheckSetError(errCode, DAQ.cardInfo);
    else
      [success, DAQ.cardInfo] = spcMCheckSetError(errCode, DAQ.cardInfo);
      % spcMErrorMessageStdOut (DAQ.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
      % short_warn(DAQ.cardInfo.errorText);
    end
  end

end
