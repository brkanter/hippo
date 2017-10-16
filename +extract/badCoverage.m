
% Ignore cells recorded during horrible exploration by marking their cluster quality as bad.
%
%   USAGE
%       array = extract.badCoverage(array,labels,badQ,<thresh>)
%       array          cell array of data
%       labels         cell array of strings containing column headers
%       badQ           string representing clusters with bad quality
%       thresh         optional. percentage of arena that must be explored (default = 0.2)
%
%   OUTPUT
%       array          cleaned array
%
% Written by BRK 2017

function array = badCoverage(array,labels,badQ,thresh)

%% check inputs
if ~exist('thresh','var')
    thresh = 0.2;
end

%% extract all rate maps
mapsCellArray = array(:,strcmpi(labels,'rate map'));

%% find nans in each map
logicalCellArray = cellfun(@isnan,mapsCellArray,'uniformoutput',0);

%% check if number of nans exceeds ~80% of the total pixels (approximation b/c of matrix corners for circular arenas)
badCovLogic = cell2mat( cellfun(@(x) (sum(~x(:))/numel(x)) < thresh,logicalCellArray,'uniformoutput',0) );

%% change quality to bad
array(badCovLogic,strcmpi(labels,'quality')) = {badQ};
