function Prepare_Status_Figure(Obj)

  % setup figure for use with Wait_FiFo_Data to display DAQ fifo status
  % in real time
  Obj.StausFigure.H = figure('Name','DAQ Status','NumberTitle','off');
  Obj.StausFigure.H.ToolBar = 'none';
  Obj.StausFigure.H.MenuBar = 'none';
  Obj.StausFigure.H.Units = 'normalized';
  Obj.StausFigure.H.Position = [0.8 0.78 0.2 0.2];
  xAxis = 1:Obj.FiFo.nBlocks;

  toSlow = Obj.StausData(:, 1);
  shotLag = Obj.StausData(:, 3);
  blocksBehind = Obj.StausData(:, 5);

  subplot(1,3,1);
    p1 = bar(xAxis,toSlow); 
      title('too slow?'); 
      ylabel('too slow?'); 
      xlabel('data block');
    p1.FaceColor = Colors.DarkRed;
    p1.LineStyle = 'none';
    p1.BarWidth = 1; % make bars touch each other
    Obj.StausFigure.p1 = p1;
  xlim(minmax(xAxis));

  subplot(1,3,2);
    p2 = plot(xAxis,shotLag); 
      title('trigger lag'); 
      ylabel('lag (nShots)'); 
      xlabel('data block');
    p2.LineWidth = 2;
    Obj.StausFigure.p2 = p2;
  xlim(minmax(xAxis));

  subplot(1,3,3);
    p3 = plot(xAxis,blocksBehind); 
      title('data lag'); 
      ylabel('lag (nBlocks)'); 
      xlabel('data block');
    p3.LineWidth = 2;
    Obj.StausFigure.p3 = p3;
  xlim(minmax(xAxis));

end
