% File: Get_Next_Fifo_Block.m @ FastDAQ
% Author: Johannes Reblimg
% Mail: johannesrebling@gmail.com

function [errCode,varargout] = Get_Next_Fifo_Block(DAQ,samplesPerChannel)
  % ***** wait for the next block -> one block = n shots... *****
  errCode = spcm_dwSetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_M2CMD'), DAQ.mRegs('M2CMD_DATA_WAITDMA'));
  DAQ.Handle_Error(errCode);

  % NOTE spcm_dwGetData expects dwLen in samples and not in Bytes
  % [..., Dat_Ch0, Dat_Ch1] = spcm_dwGetData (hDrv, dwOffs, dwLen, dwChannels, dwDataType);

  switch DAQ.FiFo.nChannels
  case 1
    [errCode, ch0Block] = spcm_dwGetData(DAQ.cardInfo.hDrv, 0, ...
      samplesPerChannel, DAQ.FiFo.nChannels, DAQ.FiFo.dataType);
    varargout{1} = reshape(ch0Block,DAQ.FiFo.shotSize,DAQ.FiFo.shotsPerNotify);
  case 2
    [errCode, ch0Block, ch1Block] = spcm_dwGetData(DAQ.cardInfo.hDrv, 0, ...
      samplesPerChannel, DAQ.FiFo.nChannels, DAQ.FiFo.dataType);
    varargout{1} = reshape(ch0Block,DAQ.FiFo.shotSize,DAQ.FiFo.shotsPerNotify);
    varargout{2} = reshape(ch1Block,DAQ.FiFo.shotSize,DAQ.FiFo.shotsPerNotify);
    % varargout{3} = ch1Shots;
  end

  DAQ.Handle_Error(errCode);

end
