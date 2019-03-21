# @M4DAC16 Class

## Requirements
- needs https://github.com/razanskylab/BaseHardwareClass

## Card used for programming and in example
- Installed memory:  4096 MByte
- Max sampling rate: 250.0 MS/s
- Channels:          2
- Kernel Version:    5.1 build 15353
- Library Version:   5.6 build 15415

## Notes
- we use HF path only
  - HF path, AC coupled, fixed 50 Ohm
  - better bandwidth
  - better noise characteristics (buffered offers +-200mV range but with ~67uV
  noise compared to ~53uV noise for +/-500mV range in HF path)

- default card settings for us:
  - HF path
  - AC coupled
  - +-5V range

## trigger
- use ext1
  - 10k Ohm termination
  - trigger detection on rising and falling
