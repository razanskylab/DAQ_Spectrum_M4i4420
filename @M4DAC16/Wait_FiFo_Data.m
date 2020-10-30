function Wait_FiFo_Data(Obj)
  % check if the next block is ready to be read or if we need to wait
  needToWait = ~Obj.isBlockReady;

  if (needToWait)
    % wait for the next block -> one block = n shots...
    % here we can get a timeout if settings are bad or trigger is not working...
    errCode = spcm_dwSetParam_i64(Obj.cardInfo.hDrv, ...
      Obj.mRegs('SPC_M2CMD'), Obj.mRegs('M2CMD_DATA_WAITDMA'));
    if (errCode)
      Obj.Handle_Error(errCode);
    end
  end

  % NOTE temp for debugging
  % get bytes available, do it without any error checking etc to be as fast as possible
  [errCode, currentBytes] = spcm_dwGetParam_i64(Obj.cardInfo.hDrv, ...
      Obj.mRegs('SPC_DATA_AVAIL_USER_LEN'));
  if (errCode)
    Obj.Handle_Error(errCode);
  end

  [errCode, fillSize] = spcm_dwGetParam_i32(Obj.cardInfo.hDrv, ...
      Obj.mRegs('SPC_FILLSIZEPROMILLE'));
  if (errCode)
    Obj.Handle_Error(errCode);
  end

  blocksBehind = (currentBytes ./ Obj.FiFo.notifySize) - 1;
  trigCount = Obj.triggerCount;
  currentShot = Obj.FiFo.currentShots(end);
  shotLag = trigCount - currentShot;
  perDone = single(Obj.FiFo.currentBlock)./single(Obj.FiFo.nBlocks).*100;

  fprintf('%i | nTrig: %i | done %2.1f%% | Lag: %i shots | block lag %i | fillsize %1.1f \n', ...
    needToWait, trigCount, perDone, shotLag, blocksBehind, fillSize);

  % fill daq fifo data
  iBlock = Obj.FiFo.currentBlock;
  Obj.StausData(iBlock, 1) = ~needToWait; % invert to convert to indicate if we were to slow
  Obj.StausData(iBlock, 2) = trigCount;
  Obj.StausData(iBlock, 3) = shotLag;
  Obj.StausData(iBlock, 4) = fillSize;
  Obj.StausData(iBlock, 5) = blocksBehind;
  Obj.StausData(iBlock, 6) = perDone;

  if ~isempty(Obj.StausFigure.H)
    figure(Obj.StausFigure.H);
    Obj.StausFigure.p1.YData = Obj.StausData(:, 1);
    Obj.StausFigure.p2.YData = Obj.StausData(:, 3);
    Obj.StausFigure.p3.YData = Obj.StausData(:, 5);
    drawnow();
  end
end
