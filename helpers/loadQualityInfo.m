
function [quality,L_ratio,isolationDist] = loadQualityInfo(folder,tetrode,cluster)

%% set PP nums for Norwegian scheme
if tetrode == 1
    PP = 4;
elseif tetrode == 2
    PP = 6;
elseif tetrode == 3
    PP = 7;
elseif tetrode == 4
    PP = 3;
end

%% qualitative cluster quality
try
    load(fullfile(folder,sprintf('TT%d_%d-Quality.mat',tetrode,cluster))) % oregon
catch
    try
        load(fullfile(folder,sprintf('PP%d_TT%d_%d-Quality.mat',PP,tetrode,cluster)))  % norway
    catch
        quality = nan;
    end
end

%% quantitative cluster quality
try    % MClust 4.3
    if cluster < 10
        try
            load(fullfile(folder,sprintf('TT%d_0%d-CluQual.mat',tetrode,cluster)))  % oregon
        catch
            try
                load(fullfile(folder,sprintf('PP%d_TT%d_0%d-CluQual.mat',PP,tetrode,cluster)))  % norway
            end
        end
    else
        try
            load(fullfile(folder,sprintf('TT%d_%d-CluQual.mat',tetrode,cluster)))  % oregon
        catch
            load(fullfile(folder,sprintf('PP%d_TT%d_%d-CluQual.mat',PP,tetrode,cluster)))  % norway
        end
    end
    L_ratio = CluSep.L_Ratio.Lratio;
    isolationDist = CluSep.IsolationDistance;
catch    % MClust 3.5
    try
        load(fullfile(folder,sprintf('TT%d_%d-CluQual_MC35.mat',tetrode,cluster)))
    catch
        L_ratio = nan;
        isolationDist = nan;
    end
end