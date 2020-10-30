% File: Print_FiFo_Info.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

% Description:

function Print_FiFo_Info(Obj)
  FiFo = Obj.FiFo;
  FiFo.Set_shotsPerNotify();

  siStr = num_to_SI_string(FiFo.nShots);
  totalShotsStr = sprintf('%s', siStr);

  shotByteSizeStr = num2bip(FiFo.shotByteSize,3,false,true);
  notifySizeStr = num2bip(FiFo.notifySize,3,false,true);
  bufferSizeStr = num2bip(FiFo.bufferSize,3,false,true);
  totalBytesStr = num2bip(FiFo.totalBytes,3,false,true);

  Obj.VPrintF_With_ID('Multi-FiFo acqusition settings:\n');

  Obj.VPrintF('    Shot Size: %i S / %sB \n', FiFo.shotSize, shotByteSizeStr);
  Obj.VPrintF('  Notify Size: %sB / %i shots\n', notifySizeStr, FiFo.shotsPerNotify);
  Obj.VPrintF('  Buffer Size: %sB / %i shots\n', bufferSizeStr, FiFo.shotsinBuffer);
  Obj.VPrintF('   Total Size: %sS / %sB / %i blocks\n', totalShotsStr, totalBytesStr,FiFo.nBlocks);

end
