
% Correct cluster quality judgments and remove data that is not informative.
%
%   USAGE
%       cleaned = cleanUpQuality(raw,labels,sessions,numSesh,badQ,offQ)
%       raw            cell array of data
%       labels         cell array of strings containing column headers
%       sessions       cell array of string containing session names
%       numSesh        number of sessions
%       badQ           string representing clusters with bad quality
%       offQ           string representing clusters that are 'off'
%
%   OUTPUT
%       cleaned        filtered array
%
% Written by BRK 2016

function cleaned = cleanUpQuality(raw,labels,sessions,numSesh,badQ,offQ)

%% switch erroneous offQ to badQ
temp = {};
for iSession = 1:numSesh
    currentData = selectCols(raw,labels,':','session',sessions{iSession});
    qToChange = selectCols(currentData,labels,'cell num','quality',offQ,'mean rate','>=',0.1);
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
clusterNums = unique(selectCols(raw,labels,'cell num'),'stable');
numClusters = length(clusterNums);
toRemove = cell(numClusters,1);
for iCluster = 1:numClusters
    quality = selectCols(raw,labels,'quality','cell num',clusterNums{iCluster});
    flag = sum(strcmpi(quality,offQ)) == length(quality);
    if flag
        toRemove{iCluster} = clusterNums{iCluster};
    end
end
toRemove = toRemove(~isempty(toRemove));
raw = selectRows(raw,labels,'remove','cell num',toRemove);
    
%% remove bad quality in first session
toRemove = selectCols(raw,labels,'cell num','session',sessions{1},'quality',badQ);
if ~iscell(toRemove)
    toRemove = {toRemove};
end
cleaned = selectRows(raw,labels,'remove','cell num',toRemove);
