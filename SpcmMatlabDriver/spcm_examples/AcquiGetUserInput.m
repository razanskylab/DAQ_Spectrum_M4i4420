function [MBytesToTransfer, setChannels, samplerate, bufferSize, notifySize, dataType] = AcquiGetUserInput (cardInfo)

    fprintf ('\n ***** settings *****\n');    
    
    % ----- get MBytes to transfer -----
    MBytesToTransfer = input (' MBytes to transfer (Default: 500 MBytes): ');
    if isempty (MBytesToTransfer)
        MBytesToTransfer = 500;
    end
    
    % ----- get channels to use from user input -----
    setChannels = input (' Channels to use (1-4) (Default: 1): ');
    if isempty (setChannels)
        setChannels = 1;
    end

    % ----- get samplerate from user input -----
    samplerate = input (' Samplerate in MHz (Default: 50 MHz): ');
    if isempty (samplerate)
        samplerate = 50000000;
    else
        samplerate = samplerate * 1000000;
    end
    
    % ----- get data type from user input -----
    fprintf (' (1) Data RAW   (unsorted)\n');
    fprintf (' (2) Data int16 (sorted)\n');
    fprintf (' (3) Data float (sorted)\n');
    fprintf (' (Default = Data RAW)\n');
    dataType = input (' Select (1-3): ');
    
    if (isempty(dataType))
        dataType = 1;
   end
    
   if (dataType < 1 | dataType > 3 | isempty(dataType))
        dataType = 1;
   end
   
   % ----- get buffer size from user input -----
   bufferSize = input (' BufferSize in MSample (Default: 16 MSample): ');
   if isempty(bufferSize)
       bufferSize = 16 * 1024 * 1024;
   else
       bufferSize = bufferSize * 1024 * 1024;
   end
   
   % ----- get notify size from user input -----
   notifySize = input (' NotifySize in kSample (Default: 4096 kSample): ');
   if isempty (notifySize)
       notifySize = 4 * 1024 * 1024;
   else
       notifySize = notifySize * 1024;
   end
   
   
   
   