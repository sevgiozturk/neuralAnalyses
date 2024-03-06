%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Sevgi Ozturk - Hull Lab 2/20/2024  %%%%%%%%%%%%%%%%%%%%%%%
%%% Reads raw and filtered neuropixel data and plots them
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
clc
clearvars
clearvars -global
close all

RAW_PRE_SPIKE = 0.005; % 5 ms before spike peak while reading raw data
RAW_POST_SPIKE = 0.005; % 10 ms after spike peak while reading raw data
RAW_RANDOM_N = 200;
SIZE_OF_SINGLE = 4; % Matlab stores single data type 4 bytes
SIZE_OF_INT16 = 2; % Matlab stores int16 data type 2 bytes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% VARIABLES NEEDED TO BE DEFINED %%%%%%%%%%%%%
CHANNEL = 335; % Which channel you want to read
spikeTimesSecs = [0.0053; 0.0142666666666667; 0.0361; 0.0593666666666667]; % Sample spike times of the selected unit
dateOfRecording = '20230126_g0';
pathToRecFolder = ['/mnt/IsilonPerm/Neuropixels/uhd_recordings/' dateOfRecording '/'];
pathToFilteredRec = [pathToRecFolder 'filtered2/']; % Put .bin and .meta file of the recording under this folder
%%%%%%%%%% VARIABLES NEEDED TO BE DEFINED %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imecMetaFiles = dir([pathToFilteredRec '*imec*ap.meta']);
metaFile = imecMetaFiles(1);
imecBinFiles = dir([pathToFilteredRec '*imec*ap.filtered.bin']);
filtFiltedBinFile = imecBinFiles(1);

imecBinFiles = dir([pathToFilteredRec '*imec*ap.bin']);
imecRawBinFile = imecBinFiles(1);

imecMeta = readMeta(metaFile.name, pathToFilteredRec); %(imecBinFile.name, pathNpyxOrgDataFolder);
samplingRate = str2double(imecMeta.imSampRate);
nSamples = int64(floor((RAW_PRE_SPIKE+RAW_POST_SPIKE)*samplingRate));

nElements = min(length(spikeTimesSecs), RAW_RANDOM_N); % whichever less, take that one
nRandSpikeTimes = randperm(length(spikeTimesSecs),nElements);
startSamples = zeros(1,length(nRandSpikeTimes));
for i=1:length(nRandSpikeTimes)
    % Get 3 ms interval of filtered data around the spike
    startSec = spikeTimesSecs(nRandSpikeTimes(i))-RAW_PRE_SPIKE;
    if startSec<0
        startSec = 0;
    end
    startSamples(i) = int64(floor(startSec*samplingRate));
end

waveFormRaw = readBinWRTDataType(startSamples, nSamples, CHANNEL, imecRawBinFile.bytes, imecRawBinFile.name, pathToFilteredRec, SIZE_OF_INT16, 'int16=>double');    
waveForm = readBinWRTDataType(startSamples, nSamples, CHANNEL, filtFiltedBinFile.bytes, filtFiltedBinFile.name, pathToFilteredRec, SIZE_OF_SINGLE, 'single=>double');        

SKIP_TO_PLOT = 4;

x=-RAW_PRE_SPIKE:1/samplingRate:RAW_POST_SPIKE-1/samplingRate;
x=x.*1000; % convert to ms
%xPlot = x(1:SKIP_TO_PLOT:end); % You don't need that high resolution to plot

if ~isempty(waveForm)                
    f = figure;
    f.Position = [1000 150 2100 2100];
                          
    subplot(2,1,1);
    hold on

    minY = 0;
    maxY = 0;
    for iPlt=1:size(waveForm,1)   
        plot(x,waveFormRaw(iPlt,:),'LineWidth',1.5, 'color', [0 0 1 .3]);
        minY = min(minY,min(waveFormRaw(iPlt,:)));
        maxY = max(maxY,max(waveFormRaw(iPlt,:)));
    end
    ylim([minY*1.5 maxY*1.5]);
    %ylabel('uV');
    grid on
    title(['Raw Data']);
    set(gca,'FontName','Times New Roman','FontWeight','bold', 'FontSize',15,'LineWidth',1.5)

    subplot(2,1,2); 
    hold on        
    for iPlt=1:size(waveForm,1)
        waveform_uV = waveForm(iPlt,:)*10^6; % plot in uV
        plot(x, waveform_uV,'LineWidth',1.5, 'color', [0 0 1 .3]);
        minY = min(minY,min(waveform_uV));
        maxY = max(maxY,max(waveform_uV));
    end                   
    ylim([minY*1.5 maxY*1.5]);
    xlabel('Time (ms)'); 
    ylabel('uV');
    grid on
    title(['filtfilt']);
    set(gca,'FontName','Times New Roman','FontWeight','bold', 'FontSize',15,'LineWidth',1.5)        
    print([pathToFilteredRec '/' 'spikeWaveForm_Filtered.tif'], '-dtiff', '-r100');       
    disp(['Filtered waveform plotted!']);
end