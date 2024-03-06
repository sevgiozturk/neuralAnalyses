%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Sevgi Ozturk - Hull Lab 2/20/2024  %%%%%%%%%%%%%%%%%%%%%%%
% =========================================================
% Directly transferred from DemoReadSGLXData.m (SpikeGLX_Datafile_Tools https://billkarsh.github.io/SpikeGLX/#post-processing-tools)
% =========================================================
% Having acquired a block of raw imec data using ReadBin(),
% convert values to gain-corrected voltages. The conversion
% is only applied to the saved-channel indices in chanList.
% Remember saved-channel indices are in range [1:nSavedChans].
% The dimensions of the dataArray remain unchanged. ChanList
% examples:
%
%   [1:AP]      % all AP chans (AP from ChannelCountsIM)
%   [2,6,20]    % just these three channels
%
function dataArray = gainCorrectIM(dataArray, chanList, meta)

    % Look up gain with acquired channel ID
    chans = originalChans(meta);
    [APgain,LFgain] = chanGainsIM(meta);
    nAP = length(APgain);
    nNu = nAP * 2;

    % Common conversion factor
    fI2V = int2Volts(meta);

    for i = 1:length(chanList)
        j = chanList(i);    % index into timepoint %
        k = chans(i);       % acquisition index 
        if k <= nAP
            conv = fI2V / APgain(k);
        elseif k <= nNu
            conv = fI2V / LFgain(k - nAP);
        else
            continue;
        end
        dataArray(i,:) = dataArray(i,:) * conv;
    end
end