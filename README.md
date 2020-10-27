# @M4DAC16 Class

## Requirements

- needs https://github.com/razanskylab/BaseHardwareClass to work

## Card used for programming and in example

- Installed memory:  4096 MByte
- Max sampling rate: 250.0 MS/s
- Channels:          2
- Kernel Version:    5.1 build 15353
- Library Version:   5.6 build 15415

## FiFo Notes

- speed depends on the selected notification size as a small notify size generates very many interrupts and status reads that disturbs the continuous data transfer
- For performance reasons __buffer size = 4 * Notifysize__

### Real Life FiFo testing (using Spectrum Control Software)

- PCI Express interface: Gen2 with 4 lanes. Max Payload: 128 Byte
  - Notifysize: 16 kiB   Read 431.8 MiB/s (452.8 MB/s)
  - Notifysize: 32 kiB   Read 1061.0 MiB/s (1112.5 MB/s)
  - Notifysize: 64 kiB   Read 1242.0 MiB/s (1302.3 MB/s)
  - Notifysize: 128 kiB   Read 1575.1 MiB/s (1651.7 MB/s)
  - Notifysize: 256 kiB   Read 1578.1 MiB/s (1654.8 MB/s)
  - Notifysize: 512 kiB   Read 1581.3 MiB/s (1658.1 MB/s)
  - Notifysize: 1024 kiB   Read 1573.1 MiB/s (1649.5 MB/s)
- above Notifysize 128 kiB no real speed increase...
- notifysize might become important again as soon as Matlab gets involved...

### OA + PD data transfer examples

- we record 2048 - 8,192 Bytes per trigger event)
  - 16 bit samples, i.e. 2 Bytes per sample
  - 512 - 2048 samples per channel
  - 2 channesl (we crop later, does not matter here)
- we record at an absolute max. prf of 20 kHz
- total max. required transfer rate is 163.84 MB/s (8,192 Bytes * 20 kHz), i.e. factor 10 safety margin!

## Notes
