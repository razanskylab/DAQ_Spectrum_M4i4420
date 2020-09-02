% File: Handle_Error.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description:

function Handle_Error(Obj, errCode)
  if (errCode ~= 0)

    [success, Obj.cardInfo] = spcMCheckSetError(errCode, Obj.cardInfo);

    if (errCode == 263)
      short_warn('[M4DAC16] Timeout while waiting for a trigger!');
    elseif errCode == 259
      short_warn('[M4DAC16] Command sequence is not allowed!');
    else
      errorMessage = ['Obj Error: ' Obj.Parse_Error_Code(errCode)];
      error(errorMessage);
    end
    
    drawnow();
  end

end
