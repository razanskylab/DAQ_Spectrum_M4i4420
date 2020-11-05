function Prepare_Status_Figure(Obj)

  % allocate raw data to be filled during scan and in  DAQ.Wait_FiFo_Data()
  Obj.StausData = NaN(Obj.FiFo.nBlocks,10); %
  
  % if we have valid figure handle, we have nothing to do here really...
  if ~isempty(Obj.StausFigure) && ishandle(Obj.StausFigure.H)
    figure(Obj.StausFigure.H);
    Obj.StausFigure.H.Position = [0.88 0.58 0.115 0.4];
  else
    % setup figure for use with Wait_FiFo_Data to display DAQ fifo status
    % in real time
    Obj.StausFigure.H = figure('Name','DAQ Status','NumberTitle','off');
    Obj.StausFigure.H.ToolBar = 'none';
    Obj.StausFigure.H.MenuBar = 'none';
    Obj.StausFigure.H.Units = 'normalized';
    Obj.StausFigure.H.Position = [0.88 0.58 0.115 0.4];
  end

  xAxis = single(1:Obj.FiFo.nBlocks);
  xLimits = [0 Obj.FiFo.nBlocks];

  toSlow = Obj.StausData(:, 1);
  shotLag = Obj.StausData(:, 3);
  blocksBehind = Obj.StausData(:, 5);

  subplot(4,1,1);
    p1 = scatter(xAxis,toSlow,'.'); 
      title('too slow?'); 
      ylabel('too slow?'); 
      xlabel('data block index');
    % p1.FaceColor = Colors.DarkRed;
    % p1.LineStyle = 'none';
    % p1.BarWidth = 1; % make bars touch each other
    Obj.StausFigure.p1 = p1;
  xlim(xLimits);

  subplot(4,1,2);
    p2 = scatter(xAxis,shotLag,'.'); 
      title('trigger lag'); 
      ylabel('lag (nShots)'); 
      xlabel('data block index');
    % p2.LineWidth = 2;
    Obj.StausFigure.p2 = p2;
  xlim(xLimits);

  subplot(4,1,3);
    p3 = scatter(xAxis,blocksBehind,'.'); 
      title('data lag'); 
      ylabel('lag (nBlocks)'); 
      xlabel('data block index');
    % p3.LineWidth = 2;
    Obj.StausFigure.p3 = p3;
  xlim(xLimits);

  subplot(4,2,7);
    p41 = plot(xAxis,ones(1,Obj.FiFo.nBlocks)); % median plot
    hold on;
    p42 = plot(xAxis,ones(1,Obj.FiFo.nBlocks),'--','color',Colors.LightGray); % min plot
    p43 = plot(xAxis,ones(1,Obj.FiFo.nBlocks),'--','color',Colors.LightGray); % max plot
    hold off;
      title('Trigger Frequencies'); 
      ylabel('freq (Hz)'); 
      xlabel('data block index');
    Obj.StausFigure.p41 = p41;
    Obj.StausFigure.p42 = p42;
    Obj.StausFigure.p43 = p43;
  xlim(xLimits);

  Obj.StausFigure.S5 = subplot(4,2,8);
    hold off;
    [Hh,Hs] = pretty_hist(nan(1,1),Colors.DarkGreen,13,'probability',false);
      title('Frequency Dist.'); 
      xlabel('freq (Hz)'); 
      ylabel('probabilty(%)');
  Obj.StausFigure.Hh = Hh;
  Obj.StausFigure.Hs = Hs;

end
