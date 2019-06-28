% File: Open_Connection.m @ FastDAQ
% Author: Urs Hofmann
% Mail: hofmannu@student.ethz.ch

% Description: Opens the connection to the data acquisition card.

function Open_Connection(DAQ)

  if DAQ.isConnected == 0

    [success, DAQ.cardInfo] = spcMInitDevice(DAQ.cardPort);

    % Check if opening was successfully
    if(success == 1)
      DAQ.isConnected = 1;
      if ~DAQ.beSilent
        DAQ.VPrintF('[M4DAC16] Connection to DAQ established!\n');
      end
    else
      DAQ.isConnected = 0;
      spcMErrorMessageStdOut(DAQ.cardInfo, 'Error: Could not open card\n', true);
    end

  else
    DAQ.VPrintF('[M4DAC16] Connection was already established.\n');
  end

end
