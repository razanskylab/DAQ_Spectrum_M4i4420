function Update_Status_Figure(Obj,freqData)
  % figure(Obj.StausFigure.H); % do not bring figure to front, this is slow...
  Obj.StausFigure.p1.YData = Obj.StausData(:, 1);
  Obj.StausFigure.p2.YData = Obj.StausData(:, 3);
  Obj.StausFigure.p3.YData = Obj.StausData(:, 5);
  Obj.StausFigure.p41.YData = Obj.StausData(:, 8);
  Obj.StausFigure.p42.YData = Obj.StausData(:, 9);
  Obj.StausFigure.p43.YData = Obj.StausData(:, 10);
  pretty_hist_update(freqData, Obj.StausFigure.Hh, Obj.StausFigure.Hs,...
    [],'probability');

end
