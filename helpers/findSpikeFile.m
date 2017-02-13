
% Extract spike times from previously saved file created by BNT to avoid recalculating.
%
%   USAGE
%       findSpikeFile(raw,labels,clusterNum,session)
%       raw            cell array of data
%       labels         cell array of strings containing column headers
%       clusterNum     string specifying cluster number
%       session        string specifying session name
%
%   SEE ALSO
%       data.getSpikeTimes
%
% Written by BRK 2017

function spikes = findSpikeFile(raw,labels,clusterNum,session)

%% search in correct directory
folder = selectCols(raw,labels,'folder','cell num',clusterNum,'session',session);
splits = regexp(folder,'\','split');
tetrode = selectCols(raw,labels,'tetrode','cell num',clusterNum,'session',session);
cluster = selectCols(raw,labels,'cluster','cell num',clusterNum,'session',session);
searchStr = [splits{1}{end} '_T' num2str(tetrode) 'C' num2str(cluster)];
d = dir(folder{1,1});
names = extractfield(d,'name');
numFiles = sum(~cellfun(@isempty,cellfun(@strfind,names',cellstr(repmat(searchStr,length(d),1)),'uniformoutput',0)));
if ~numFiles
    error('Could not find spike times')
end
spikeFile = names(~cellfun(@isempty,cellfun(@strfind,names',cellstr(repmat(searchStr,length(d),1)),'uniformoutput',0)));

%% if there are multiple versions, use most recent one
if numFiles > 1
    dates = extractfield(d,'date');
    [~,sortInds] = sort(dates(~cellfun(@isempty,cellfun(@strfind,names',cellstr(repmat(searchStr,length(d),1)),'uniformoutput',0))));
    spikeFile = spikeFile(sortInds == 1);
end

%% load it
spikeFile = fullfile(folder{1,1},spikeFile{1,1});
load(spikeFile)
spikes = cellTS;