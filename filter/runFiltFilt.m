%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Sevgi Ozturk - Hull Lab 2/20/2024  %%%%%%%%%%%%%%%%%%%%%%%
%%% Filters raw neuropixel data using zero-phase filtering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
clearvars
clearvars -global
close all
tic
gpuDevice(1); % Activate GPU Device

SIZE_OF_INT16 = 2; % Matlab stores int16 data type 2 bytes

NUM_OF_CHANNELS = 385;
dateOfRecording = '20230126_g0';
pathToRecFolder = ['/mnt/IsilonPerm/Neuropixels/uhd_recordings/' dateOfRecording '/'];
pathToFilteredRec = [pathToRecFolder 'filtered2/']; % Put .bin and .meta file of the recording under this folder
if ~exist(pathToFilteredRec)
    mkdir(pathToFilteredRec);
end
                
imecMetaFiles = dir([pathToFilteredRec '*imec*ap.meta']);
if isempty(imecMetaFiles)
    error('Meta file is not found!')        
end
imecMetaFile = imecMetaFiles(1);    
imecMeta = readMeta(imecMetaFile.name, pathToFilteredRec);
samplingRate = str2double(imecMeta.imSampRate);    
nSamples = floor(str2double(imecMeta.fileSizeBytes)/(SIZE_OF_INT16 * NUM_OF_CHANNELS)); % 2 bytes for int16

imecBinFiles = dir([pathToFilteredRec '*imec*ap.bin']);
if isempty(imecBinFiles)
    error('Raw bin file is not found!')        
end
imecBinFile = imecBinFiles(1);
memoryMapBin = memmapfile([pathToFilteredRec imecBinFile.name], 'Format',{'int16',[NUM_OF_CHANNELS nSamples], 'rawData'});
inds = strfind(imecBinFile.name,'.');
imecFileName = imecBinFile.name(1:inds(end));
filteredBinFileName = [imecFileName 'filtered.bin'];

batchSize = 1 * samplingRate; %1024; % 10 KB per channel
bufferSize = ceil(batchSize/10); % 10% of the mean signal willl be added as buffer
totalBatchSize = batchSize + 2*bufferSize;
numOfBatches = ceil(nSamples/batchSize);

hiPass = 300; % hi pass cutoff
hi = hiPass*2/samplingRate; % normalized for ADC sampling rate
[b1,a1] = butter(3,hi,"high");

randomCh = 6;
cursor = 1;
sizeOfRawData = size(memoryMapBin.Data.rawData,2);
[filteredFileID, errMes] = fopen([pathToFilteredRec filteredBinFileName],'w');

for i=1:numOfBatches        
    endOfBatch = batchSize+bufferSize;
    endOfBufferedBatch = cursor+totalBatchSize-1;
    if cursor>sizeOfRawData
        error('Cursor is at the end of file!');
    elseif endOfBufferedBatch>sizeOfRawData % if it's the last batch and left over data size is not matching our batch size
        endOfBufferedBatch = sizeOfRawData;
    end
    if i==1 % if this is first batch, add preceeding synthetic buffer
        tempBuffer = memoryMapBin.Data.rawData(:,1:bufferSize);
        tempBuffer = mean(tempBuffer,2);
        tempBuffer = repmat(tempBuffer,[1 bufferSize]); % build a synthetic buffer made up of mean signal of the first batch
        rawData = double([tempBuffer memoryMapBin.Data.rawData(:, 1:batchSize+bufferSize)]);
        cursor = batchSize-bufferSize; % next cursor should start from an earlier timepoint matching with buffer
    else
        rawData = double(memoryMapBin.Data.rawData(:, cursor:endOfBufferedBatch));
        cursor = cursor+batchSize; % next cursor should start at the preceeding buffer time point of next batch
    end

    rawDataGCorr = gainCorrectIM(rawData, 1:NUM_OF_CHANNELS, imecMeta);
    filteredBufferedRawData = filtfilt(b1,a1,rawDataGCorr');
    filteredBufferedRawData = filteredBufferedRawData - mean(filteredBufferedRawData,1); % filtered sensor signal
    filteredBufferedRawData = filteredBufferedRawData';
    
    if size(filteredBufferedRawData,2)<endOfBatch
        endOfBatch = size(filteredBufferedRawData,2);
    end
    filteredSignal = filteredBufferedRawData(:,bufferSize+1:endOfBatch); % get rid of the buffers around the edges cos filtering distorts the edges       
    filteredSignalSingle = single(filteredSignal); % convert it to 32-bit-single instead of 64-bit-double for resource management
    fwrite(filteredFileID,filteredSignalSingle,'single');
    disp([num2str(i) '/' num2str(numOfBatches) ' of batches filtered and written in ' num2str(toc,'%.2f') ' sec.!']);        
end
fclose(filteredFileID);
        

