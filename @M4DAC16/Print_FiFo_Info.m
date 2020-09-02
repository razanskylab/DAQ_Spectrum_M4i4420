% File: Print_FiFo_Info.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description:

function Print_FiFo_Info(Obj)
  FiFo = Obj.FiFo;
  FiFo.Set_shotsPerNotify();

  siStr = num_to_SI_string(FiFo.nShots);
  totalShotsStr = sprintf('%s',siStr);

  siStr = num_to_SI_string(FiFo.totalBytes);
  totalBytesStr = sprintf('%sB',siStr);

  Obj.VPrintF_With_ID('Multi-FiFo acqusition settings:\n');

  Obj.VPrintF('   Samples/Shot: %2.0f (%2.2f kB)\n',...
    FiFo.shotSize,FiFo.shotByteSize*1e-3);
  Obj.VPrintF('   Buffer Size:  %2.2f MB | ',FiFo.bufferSize*1e-6);
  Obj.VPrintF('   Notify Size:  %2.2f MB (%2.0f shots)\n',...
    FiFo.notifySize*1e-6,FiFo.shotsPerNotify);

  Obj.VPrintF('   Total Shots: %s \n',totalShotsStr);
  Obj.VPrintF('   Total Data: %s\n',totalBytesStr);

end
