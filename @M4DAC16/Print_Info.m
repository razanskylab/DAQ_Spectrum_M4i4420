%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print informations about the data acquisition card if connection is open
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Print_Info(dac)

  fprintf(' Connection:\t\t');
  if (dac.isConnected == 1)
    fprintf('Opened\n ');
    fprintf(spcMPrintCardInfo(dac.cardInfo));
    fprintf('\n');
  else
    fprintf('Closed\n');
    fprintf('To show more info, open connection first.');
  end

end
