% Description: Frees the allocated buffer memory on the card

function Free_FIFO_Buffer(Obj)
  tic;
  Obj.VPrintF_With_ID('Freeing FiFo buffer...');
  %% ---------------------------------------------------------------------------
  % free data buffer
  errCode = spcm_dwSetupFIFOBuffer (Obj.cardInfo.hDrv, 0, 0, 1, 0, 0);
  if (errCode ~= 0)
    [success, Obj.cardInfo] = spcMCheckSetError (errCode, Obj.cardInfo);
    spcMErrorMessageStdOut (Obj.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    error(Obj.cardInfo.errorText);
  end

  %% ---------------------------------------------------------------------------
  % free Timestamp buffer
  errCode = spcm_dwSetupFIFOBuffer (Obj.cardInfo.hDrv, 1, 0, 1, 0, 0);
  if (errCode ~= 0)
    [success, Obj.cardInfo] = spcMCheckSetError (errCode, Obj.cardInfo);
    spcMErrorMessageStdOut (Obj.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    error(Obj.cardInfo.errorText);
  end
  Obj.Done();
end
