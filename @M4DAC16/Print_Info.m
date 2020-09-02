function Print_Info(Obj)
  fprintf(' Connection:\t\t');
  if (Obj.isConnected == 1)
    fprintf('Opened\n ');
    fprintf(spcMPrintCardInfo(Obj.cardInfo));
    fprintf('\n');
  else
    fprintf('Closed\n');
    fprintf('To show more info, open connection first.');
  end

end
