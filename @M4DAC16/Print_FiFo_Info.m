% File: Print_FiFo_Info.m @ FastDAQ
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description:

function Print_FiFo_Info(DAQ)
  FiFo = DAQ.FiFo;
  FiFo.Set_shotsPerNotify();

  siStr = num_to_SI_string(FiFo.nShots);
  totalShotsStr = sprintf('%s',siStr);

  siStr = num_to_SI_string(FiFo.totalBytes);
  totalBytesStr = sprintf('%sB',siStr);

  DAQ.VPrintF('[M4DAC16] Multi-FiFo acqusition settings:\n');

  DAQ.VPrintF('   Samples/Shot: %2.0f (%2.2f kB)\n',...
    FiFo.shotSize,FiFo.shotByteSize*1e-3);
  DAQ.VPrintF('   Buffer Size:  %2.2f MB | ',FiFo.bufferSize*1e-6);
  DAQ.VPrintF('Notify Size:  %2.2f MB (%2.0f shots)\n',...
    FiFo.notifySize*1e-6,FiFo.shotsPerNotify);

  DAQ.VPrintF('   Total Shots: %s \n',totalShotsStr);
  DAQ.VPrintF('   Total Data: %s\n',totalBytesStr);

end
