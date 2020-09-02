% File: Parse_Error_Code.m @ M4DAC16
% Author: Johannes Rebling, Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 28.05.2020

% Description: Prases Spectrum DAC error codes.

function errorMessage = Parse_Error_Code(~, errCode)
  
  switch errCode
    case 2147483648
      errorMessage = 'SPCM_ERROR_ORIGIN_MASK';
    case 0
      errorMessage = 'ERR_OK';
    case 1
      errorMessage = 'ERR_INIT';
    case 2
      errorMessage = 'ERR_NR';
    case 3
      errorMessage = 'ERR_TYP';
    case 4
      errorMessage = 'ERR_FNCNOTSUPPORTED';
    case 5
      errorMessage = 'ERR_BRDREMAP';
    case 6
      errorMessage = 'ERR_KERNELVERSION';
    case 7
      errorMessage = 'ERR_HWDRVVERSION';
    case 8
      errorMessage = 'ERR_ADRRANGE';
    case 9
      errorMessage = 'ERR_INVALIDHANDLE';
    case 10
      errorMessage = 'ERR_BOARDNOTFOUND';
    case 11
      errorMessage = 'ERR_BOARDINUSE';
    case 12
      errorMessage = 'ERR_EXPHW64BITADR';
    case 13
      errorMessage = 'ERR_FWVERSION';
    case 16
      errorMessage = 'ERR_LASTERR';
    case 32
      errorMessage = 'ERR_ABORT';
    case 48
      errorMessage = 'ERR_BOARDLOCKED';
    case 50
      errorMessage = 'ERR_DEVICE_MAPPING';
    case 64
      errorMessage = 'ERR_NETWORKSETUP';
    case 65
      errorMessage = 'ERR_NETWORKTRANSFER';
    case 66
      errorMessage = 'ERR_FWPOWERCYCLE';
    case 67
      errorMessage = 'ERR_NETWORKTIMEOUT';
    case 68
      errorMessage = 'ERR_BUFFERSIZE';
    case 69
      errorMessage = 'ERR_RESTRICTEDACCESS';
    case 70
      errorMessage = 'ERR_INVALIDPARAM';
    case 256
      errorMessage = 'ERR_REG';
    case 257
      errorMessage = 'ERR_VALUE';
    case 258
      errorMessage = 'ERR_FEATURE';
    case 259
      errorMessage = 'ERR_SEQUENCE';
    case 260
      errorMessage = 'ERR_READABORT';
    case 261
      errorMessage = 'ERR_NOACCESS';
    case 262
      errorMessage = 'ERR_POWERDOWN';
    case 263
      errorMessage = 'A timeout occurred while waiting for an interrupt (trigger).';
    case 264
      errorMessage = 'ERR_CALLTYPE';
    case 265
      errorMessage = 'ERR_EXCEEDSINT32';
    case 266
      errorMessage = 'ERR_NOWRITEALLOWED';
    case 267
      errorMessage = 'ERR_SETUP';
    case 268
      errorMessage = 'ERR_CLOCKNOTLOCKED';
    case 269
      errorMessage = 'ERR_MEMINIT';
    case 270
      errorMessage = 'ERR_POWERSUPPLY';
    case 271
      errorMessage = 'ERR_ADCCOMMUNICATION';
    case 272
      errorMessage = 'ERR_CHANNEL';
    case 273
      errorMessage = 'ERR_NOTIFYSIZE';
    case 288
      errorMessage = 'ERR_RUNNING';
    case 304
      errorMessage = 'ERR_ADJUST';
    case 320
      errorMessage = 'ERR_PRETRIGGERLEN';
    case 321
      errorMessage = 'ERR_DIRMISMATCH';
    case 322
      errorMessage = 'ERR_POSTEXCDSEGMENT';
    case 323
      errorMessage = 'ERR_SEGMENTINMEM';
    case 324
      errorMessage = 'ERR_MULTIPLEPW';
    case 325
      errorMessage = 'ERR_NOCHANNELPWOR';
    case 326
      errorMessage = 'ERR_ANDORMASKOVRLAP';
    case 327
      errorMessage = 'ERR_ANDMASKEDGE';
    case 328
      errorMessage = 'ERR_ORMASKLEVEL';
    case 329
      errorMessage = 'ERR_EDGEPERMOD';
    case 330
      errorMessage = 'ERR_DOLEVELMINDIFF';
    case 331
      errorMessage = 'ERR_STARHUBENABLE';
    case 332
      errorMessage = 'ERR_PATPWSMALLEDGE';
    case 512
      errorMessage = 'ERR_NOPCI';
    case 513
      errorMessage = 'ERR_PCIVERSION';
    case 514
      errorMessage = 'ERR_PCINOBOARDS';
    case 515
      errorMessage = 'ERR_PCICHECKSUM';
    case 516
      errorMessage = 'ERR_DMALOCKED';
    case 517
      errorMessage = 'ERR_MEMALLOC';
    case 518
      errorMessage = 'ERR_EEPROMLOAD';
    case 519
      errorMessage = 'ERR_CARDNOSUPPORT';
    case 520
      errorMessage = 'ERR_CONFIGACCESS';
    case 768
      errorMessage = 'ERR_FIFOBUFOVERRUN';
    case 769
      errorMessage = 'Hardware buffer overrun in FIFO mode!';
    case 770
      errorMessage = 'FIFO transfer has been finished!';
    case 777
      errorMessage = 'ERR_FIFOSETUP';
    case 784
      errorMessage = 'ERR_TIMESTAMP_SYNC';
    case 800
      errorMessage = 'ERR_STARHUB';
    case 65535
      errorMessage = 'ERR_INTERNAL_ERROR';
    otherwise
      errorMessage = 'Unknown error code';
  end
  
end
