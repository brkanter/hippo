

function raw = cleanUpQuality(raw,labels,sessions,numSesh,badQ,offQ)

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
toRemove = cell(numClusters,1);
for iCluster = 1:numClusters
    quality = getColComp(raw,labels,'quality','cell num',clusterNums{iCluster});
    flag = sum(strcmpi(quality,offQ)) == length(quality);
    if flag
        toRemove{iCluster} = clusterNums{iCluster};
    end
end
toRemove = toRemove(~isempty(toRemove));
raw = selectRows(raw,labels,'remove','cell num',toRemove);
    
%% remove bad quality in first session
toRemove = getColComp(raw,labels,'cell num','session',sessions{1},'quality',badQ);
if ~iscell(toRemove)
    toRemove = {toRemove};
end
% if ~isempty(toRemove{1})
    raw = selectRows(raw,labels,'remove','cell num',toRemove);
% end
