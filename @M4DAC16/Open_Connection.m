% File: Open_Connection.m @ FastObj
% Author: Urs Hofmann
% Mail: hofmannu@student.ethz.ch

% Description: Opens the connection to the data acquisition card.

function Open_Connection(Obj)

  if ~Obj.isConnected

    [success, Obj.cardInfo] = spcMInitDevice(Obj.cardPort);

    % Check if opening was successfully
    if (success)
      Obj.VPrintF_With_ID('Connection established!\n');
    else
      spcMErrorMessageStdOut(Obj.cardInfo, 'Error: Could not open card\n', true);
    end

  else
    Obj.VPrintF_With_ID('Connection was already established.\n');
  end

end
