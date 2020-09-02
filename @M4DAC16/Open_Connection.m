% File: Open_Connection.m @ FastObj
% Author: Urs Hofmann
% Mail: hofmannu@student.ethz.ch

% Description: Opens the connection to the data acquisition card.

function Open_Connection(Obj)

  if Obj.isConnected == 0

    [success, Obj.cardInfo] = spcMInitDevice(Obj.cardPort);

    % Check if opening was successfully
    if(success == 1)
      Obj.isConnected = 1;
      if ~Obj.beSilent
        Obj.VPrintF_With_ID('Connection to Obj established!\n');
      end
    else
      Obj.isConnected = 0;
      spcMErrorMessageStdOut(Obj.cardInfo, 'Error: Could not open card\n', true);
    end

  else
    Obj.VPrintF_With_ID('Connection was already established.\n');
  end

end
