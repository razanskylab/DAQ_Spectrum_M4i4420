% File: Get_Next_Fifo_Block.m @ FastObj
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

function [errCode,varargout] = Get_Next_Fifo_Block(Obj,samplesPerChannel)
  % ***** wait for the next block -> one block = n shots... *****
  errCode = spcm_dwSetParam_i32(Obj.cardInfo.hDrv, Obj.mRegs('SPC_M2CMD'), Obj.mRegs('M2CMD_DATA_WAITDMA'));
  Obj.Handle_Error(errCode);

  % NOTE spcm_dwGetData expects dwLen in samples and not in Bytes
  % [..., Dat_Ch0, Dat_Ch1] = spcm_dwGetData (hDrv, dwOffs, dwLen, dwChannels, dwDataType);

  switch Obj.FiFo.nChannels
  case 1
    [errCode, ch0Block] = spcm_dwGetData(Obj.cardInfo.hDrv, 0, ...
      samplesPerChannel, Obj.FiFo.nChannels, Obj.FiFo.dataType);
    varargout{1} = reshape(ch0Block,Obj.FiFo.shotSize,Obj.FiFo.shotsPerNotify);
  case 2
    [errCode, ch0Block, ch1Block] = spcm_dwGetData(Obj.cardInfo.hDrv, 0, ...
      samplesPerChannel, Obj.FiFo.nChannels, Obj.FiFo.dataType);
    varargout{1} = reshape(ch0Block,Obj.FiFo.shotSize,Obj.FiFo.shotsPerNotify);
    varargout{2} = reshape(ch1Block,Obj.FiFo.shotSize,Obj.FiFo.shotsPerNotify);
    % varargout{3} = ch1Shots;
  end

  Obj.Handle_Error(errCode);

end
