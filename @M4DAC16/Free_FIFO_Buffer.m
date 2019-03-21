% Description: Frees the allocated buffer memory on the card

function Free_FIFO_Buffer(DAQ)

  fprintf('[M4DAC16] Freeing FIFI buffer...'); 
  %% ---------------------------------------------------------------------------
  % free data buffer
  errCode = spcm_dwSetupFIFOBuffer (DAQ.cardInfo.hDrv, 0, 0, 1, 0, 0);
  if (errCode ~= 0)
    [success, DAQ.cardInfo] = spcMCheckSetError (errCode, DAQ.cardInfo);
    spcMErrorMessageStdOut (DAQ.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    error(DAQ.cardInfo.errorText);
  end

  %% ---------------------------------------------------------------------------
  % free Timestamp buffer
  errCode = spcm_dwSetupFIFOBuffer (DAQ.cardInfo.hDrv, 1, 0, 1, 0, 0);
  if (errCode ~= 0)
    [success, DAQ.cardInfo] = spcMCheckSetError (errCode, DAQ.cardInfo);
    spcMErrorMessageStdOut (DAQ.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    error(DAQ.cardInfo.errorText);
  end
  done();
end
