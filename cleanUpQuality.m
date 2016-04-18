

function raw = cleanUpQuality(raw,labels,groupNames,numGroups,sessions,numSesh,badQ,offQ)

%% switch erroneous offQ to badQ
temp = {};
for iSession = 1:numSesh
    currentData = getColComp(raw,labels,':','session',sessions{iSession});
    qToChange = getColComp(currentData,labels,'cell num','quality',offQ,'mean rate','>=',0.1);
    if ~iscell(qToChange)
        qToChange = {qToChange};
    end
    for iCluster = 1:length(qToChange)
        currentData(strcmpi(currentData(:,strcmpi('cell num',labels)),qToChange{iCluster}), ...
            strcmpi('quality',labels)) = {badQ};
    end
    temp = [temp; currentData];
end
raw = temp;

%% remove cells that are never good quality
clusterNums = unique(getCol(raw,labels,'cell num'),'stable');
numClusters = length(clusterNums);
for iCluster = 1:numClusters
    quality = getColComp(raw,labels,'quality','cell num',clusterNums{iCluster});
    if (sum(strcmpi(quality,offQ)) + sum(strcmpi(quality,badQ))) == length(quality)
        raw = deleteRowsComp(raw,labels,'cell num',clusterNums{iCluster});
    end
end

%% remove bad quality in first session
toRemove = getColComp(raw,labels,'cell num','session',sessions{1},'quality',badQ);
if ~iscell(toRemove)
    toRemove = {toRemove};
end
for iCluster = 1:length(toRemove)
    raw = deleteRowsComp(raw,labels,'cell num',toRemove{iCluster});
end