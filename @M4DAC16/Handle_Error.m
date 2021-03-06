% File: Handle_Error.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description:

function Handle_Error(Obj, errCode)
  if (errCode ~= 0)
    if (errCode == 263)
      short_warn('[DAQ] Timeout while waiting for a trigger!');
    elseif errCode == 259
      short_warn('[DAQ] Command sequence is not allowed!');
    elseif errCode == 16
      % there was an old error, read that one, then call this fct again...
      [errCode, ~, ~, ~] = spcm_dwGetErrorInfo_i32(Obj.cardInfo.hDrv);
      Obj.Handle_Error(errCode);
    else
      errorMessage = ['Obj Error: ' Obj.Parse_Error_Code(errCode)];
      error(errorMessage);
    end
    drawnow();
  end

end


