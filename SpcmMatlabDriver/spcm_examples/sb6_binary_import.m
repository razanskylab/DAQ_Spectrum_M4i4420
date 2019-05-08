[ChData_mV, ScaleX_us, numChannels] = spcMReadSBench6BinaryExport ('export.bin');

xlabel ('us');
ylabel ('mV');
hold on;

for chIdx = 1 : numChannels
    plot (ScaleX_us, ChData_mV(chIdx,:));
end