% File: Open_Connection.m @ FastDAQ
% Author: Urs Hofmann
% Mail: hofmannu@student.ethz.ch

% Description: Opens the connection to the data acquisition card.

function Open_Connection(dac)

  if dac.isConnected == 0

    [success, dac.cardInfo] = spcMInitDevice(dac.cardPort);

    % Check if opening was successfully
    if(success == 1)
      dac.isConnected = 1;
      if ~dac.beSilent
        fprintf('[M4DAC16] Connection to DAQ established!\n');
      end
    else
      dac.isConnected = 0;
      spcMErrorMessageStdOut(dac.cardInfo, 'Error: Could not open card\n', true);
    end

  else
    fprintf('[M4DAC16] Connection was already established.\n');
  end

end
