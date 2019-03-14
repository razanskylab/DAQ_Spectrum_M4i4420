% File: Close_Connection.m @ FastDAQ
% AUthor: Urs Hofmann
% Date: 21.08.2018
% Mail: hofmannu@student.ethz.ch

% Description: Closes the connection to the data acquisition card.

function Close_Connection(dac)

  % Check if card was opened before (requirement to close card)
  if(dac.isConnected == 1)
    spcMCloseCard(dac.cardInfo);

    if ~dac.beSilent
      fprintf('[M4DAC16] Connection to DAQ closed.\n');
    end

    dac.isConnected = 0;
  else
    short_warn('[M4DAC16] Cannot close connection to card, it was not opened.');
  end

end
