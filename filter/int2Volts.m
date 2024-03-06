%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Sevgi Ozturk - Hull Lab 2/20/2024  %%%%%%%%%%%%%%%%%%%%%%%
% =========================================================
% Directly transferred from DemoReadSGLXData.m (SpikeGLX_Datafile_Tools https://billkarsh.github.io/SpikeGLX/#post-processing-tools)
% =========================================================
% Return a multiplicative factor for converting 16-bit
% file data to voltage. This does not take gain into
% account. The full conversion with gain is:
%
%   dataVolts = dataInt * fI2V / gain.
%
% Note that each channel may have its own gain.
%
function fI2V = int2Volts(meta)
    if strcmp(meta.typeThis, 'imec')
        if isfield(meta,'imMaxInt')
            maxInt = str2num(meta.imMaxInt);
        else
            maxInt = 512;
        end
        fI2V = str2double(meta.imAiRangeMax) / maxInt;
    else
        fI2V = str2double(meta.niAiRangeMax) / 32768;
    end
end % Int2Volts