%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Sevgi Ozturk - Hull Lab 2/20/2024  %%%%%%%%%%%%%%%%%%%%%%%
% =========================================================
% Directly transferred from DemoReadSGLXData.m (SpikeGLX_Datafile_Tools https://billkarsh.github.io/SpikeGLX/#post-processing-tools)
% Updated by SO Hull lab 1/19/2023: to read multi samples at once to speed up the raw data reading
% samples: is array now, holding the start positions for multi-read
% bestCh: reads only best channel
% =========================================================
% Read nSamp timepoints from the binary file, starting
% at timepoint offset samples(i). The returned array has
% dimensions [nChan,nSamp]. Note that nSamp returned
% is the lesser of: {nSamp, timepoints available}.
%
% IMPORTANT: samples must be array of start positions and nSamp must be integer.
%
function dataArray = readBinWRTDataType(samples, nSamp, chOfInterest, fileSizeBytes, binName, path, sizeOfData, sConvertDataType)
    
    NUM_OF_CHANNELS = 385;
    nFileSamp = str2double(fileSizeBytes) / (sizeOfData * NUM_OF_CHANNELS);
    
    sizeA = [NUM_OF_CHANNELS, nSamp];
    dataArray = NaN(length(samples),nSamp);
    fid = fopen(fullfile(path, binName), 'rb');
    for i=1:length(samples)                
        samples(i) = max(samples(i), 0);
        nSamp = min(nSamp, nFileSamp - samples(i));

        fseek(fid, samples(i) * sizeOfData * NUM_OF_CHANNELS, 'bof');
        tempData = fread(fid, sizeA, sConvertDataType);
        dataArray(i,1:size(tempData,2)) = tempData(chOfInterest,:);
    end
    fclose(fid);
end % ReadBin