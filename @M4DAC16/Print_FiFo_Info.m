% File: Print_FiFo_Info.m @ FastDAQ
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description:

function Print_FiFo_Info(DAQ)
  F = DAQ.FiFo;
  F.Set_shotsPerNotify();

  DAQ.VPrintF('[M4DAC16] Multi-FiFo acqusition settings:\n');

    DAQ.VPrintF('   Samples/Shot: %2.0f (%2.2f kB)\n',...
      F.shotSize,F.shotByteSize*1e-3);
    DAQ.VPrintF('   Buffer Size:  %2.2f MB\n',F.bufferSize*1e-6);
    DAQ.VPrintF('   Notify Size:  %2.2f MB (%2.0f shots)\n',...
      F.notifySize*1e-6,F.shotsPerNotify);

  if (F.nShots > 1e6)
    DAQ.VPrintF('   Total Shots: %2.2f M\n',F.nShots*1e-6);
  elseif (F.nShots > 1e3)
    DAQ.VPrintF('   Total Shots: %2.2f k\n',F.nShots*1e-3);
  else
    DAQ.VPrintF('   Total Shots: %2.0f\n',F.nShots);
  end

  if (F.totalBytes > 2e9)
    DAQ.VPrintF('   Total Data: %2.2f GB\n',F.totalBytes*1e-9);
  else
    DAQ.VPrintF('   Total Data: %2.2f MB\n',F.totalBytes*1e-6);
  end

end
