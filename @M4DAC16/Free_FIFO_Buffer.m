% File:     Free_FIFO_Buffer.m @ FastDAQ
% Author:   Urs Hofmann
% Date:     27. Mar 2018
% Mail:     urshofmann@gmx.net
% Version:  1.0

% Description: Frees the allocated buffer memory on the card

function Free_FIFO_Buffer(dac)

  fprintf('[FastDAQ] Free buffer memory.\n');

  errorCode = spcm_dwSetupFIFOBuffer (...
    dac.cardInfo.hDrv, ...
    0, ... % dwBufType
    0, ... % bAllocate
    1, ... % bRead
    dac.cardInfo.bytesPerSample * dac.fifoMode.nSamples * dac.fifoMode.loopsToRec,... % dwBufferinBytes
    0); % dwNotifyInBytes

  % Get error
  if (errorCode ~= 0)
      [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
      spcMErrorMessageStdOut (...
        dac.cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
      return;
  end
end
