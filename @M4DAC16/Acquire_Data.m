% File:     Acquire_Data.m @ FastDAQ
% Author:   Urs Hofmann
% Date:     27. Mar 2018
% Mail:     urshofmann@gmx.net
% Version:  1.0

% Descirption: Function used to actually acquire data based on the settings
% which have been done before.

function acquiredData = Acquire_Data(Obj)

  % acquiredData = zeros(Obj.NO_CHANNELS, Obj.acquisitionMode.nSamples);

  % ----- set command flags -----
  commandMask = bitor (4, 8);                %   M2CMD_CARD_START | M2CMD_CARD_ENABLETRIGGER
  commandMask = bitor (commandMask, 16384);  % | M2CMD_CARD_WAITREADY

  errorCode = spcm_dwSetParam_i32(...
      Obj.cardInfo.hDrv, ...
      100, ...
      commandMask);  % 100 = SPC_M2CMD

  if (errorCode == 263)  % 263 = ERR_TIMEOU
    error('[FastDAQ] Timeout.');
    error_code = spcm_dwSetParam_i32(...
      cardInfo.hDrv,...
      100,...
      64); % stop card...

     return;
  elseif (errorCode ~= 0)
    error(['[FastDAQ] An error occured while setting parameters: ', ...
      Obj.cardInfo.errorText]);
  else
    [errorCode, acquiredData(1,:), acquiredData(2,:)] = ...
    spcm_dwGetData( ...                   % returns channel data in order
      Obj.cardInfo.hDrv, ...              % physical address of card (?)
      Obj.offset, ...                     % offet start address
      Obj.acquisitionMode.nSamples, ... % length of buffer to read
      Obj.NO_CHANNELS, ...                % number of analog channels
      Obj.dataType);                      % datatype to read

    if (errorCode ~= 0)
        [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwGetData:\n\t', true);
        return;
    end
  end

end
