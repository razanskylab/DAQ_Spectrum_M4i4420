# Spectrum DAQ - Put type info here+

## Data Transfer  
nSamples = 100:100:1000;
sampleRate = 250e6;
prf = 1e3;
nBits = 32; % 2*  int16

 transferRate = nSamples * prf * nBits * 1e-6
 = 24 Mbit/s


 hDrv = spcm_hOpen(drvName);
 spcm_hClose(hDrv);

 nSamples = 100:100:3000;
 sampleRate = 250e6;
 prf = 1e3:3e3:100e3;
 nBits = 32; % 2*int16

  transferRate = nBits.*prf.*nSamples*1e-6;


SPC_M2CMD = Command register
