
% When running emperorPenguin, there may be a cluster missing (or containing 0 spikes).
% This function fills in the data structure for that cluster with appropriate placeholders.
%
%   USAGE
%       clusterData = missingClusterData(clusterData,iCluster,iFolder,iExp,include)
%       clusterData     structure for storing all data
%       iCluster        double indicating the cluster
%       iFolder         double indicating the session
%       iExp            double indicating the experiment
%       include         structure indicating which measures to calculate
%
%   OUTPUT
%       clusterData     structure for storing all data
%
%   SEE ALSO
%       emperorPenguin
%
% Written by BRK 2017

function clusterData = missingClusterData(clusterData,iCluster,iFolder,iExp,include)

clusterData(iCluster,iFolder,iExp).rateMap = nan;
clusterData(iCluster,iFolder,iExp).countMap = nan;
clusterData(iCluster,iFolder,iExp).meanRate = 0;
clusterData(iCluster,iFolder,iExp).peakRate = 0;
clusterData(iCluster,iFolder,iExp).totalSpikes = 0;
clusterData(iCluster,iFolder,iExp).quality = nan;
clusterData(iCluster,iFolder,iExp).L_ratio = nan;
clusterData(iCluster,iFolder,iExp).isoDist = nan;

if include.spikeWidth
    clusterData(iCluster,iFolder,iExp).spikeWidth = nan;
end
if include.sss
    clusterData(iCluster,iFolder,iExp).spatInfo = nan;
    clusterData(iCluster,iFolder,iExp).selectivity = nan;
    clusterData(iCluster,iFolder,iExp).sparsity = nan;
end   
if include.coherence
    clusterData(iCluster,iFolder,iExp).coherence = nan;
end  
if include.fields
    clusterData(iCluster,iFolder,iExp).fieldNum = nan;
    clusterData(iCluster,iFolder,iExp).fieldMean = nan;
    clusterData(iCluster,iFolder,iExp).fieldMax = nan;
    clusterData(iCluster,iFolder,iExp).COMx = nan;
    clusterData(iCluster,iFolder,iExp).COMy = nan;
    clusterData(iCluster,iFolder,iExp).border = nan;
end  
if include.grid
    clusterData(iCluster,iFolder,iExp).gridScore = nan;
    clusterData(iCluster,iFolder,iExp).gridSpacing = nan;
    clusterData(iCluster,iFolder,iExp).gridOrient1 = nan;
    clusterData(iCluster,iFolder,iExp).gridOrient2 = nan;
    clusterData(iCluster,iFolder,iExp).gridOrient3 = nan;
end
if include.HD
    clusterData(iCluster,iFolder,iExp).mvl = nan;
    clusterData(iCluster,iFolder,iExp).angle = nan;
end
if include.speed
    clusterData(iCluster,iFolder,iExp).speed = nan;
end
if include.theta
    clusterData(iCluster,iFolder,iExp).thetaSpikes = nan;
    clusterData(iCluster,iFolder,iExp).thetaLFP = nan;
end
if include.obj
    clusterData(iCluster,iFolder,iExp).rateRatioO1 = nan;
    clusterData(iCluster,iFolder,iExp).rateRatioO2 = nan;
    clusterData(iCluster,iFolder,iExp).ratePvalO1 = nan;
    clusterData(iCluster,iFolder,iExp).ratePvalO2 = nan;
    clusterData(iCluster,iFolder,iExp).ratePvalAll = nan;
    clusterData(iCluster,iFolder,iExp).timeRatioO1 = nan;
    clusterData(iCluster,iFolder,iExp).timeRatioO2 = nan;
    clusterData(iCluster,iFolder,iExp).timePvalO1 = nan;
    clusterData(iCluster,iFolder,iExp).timePvalO2 = nan;
    clusterData(iCluster,iFolder,iExp).timePvalAll = nan;
end
    