
% Filter for particular functional cell types.
%
%   USAGE
%       array = extract.cellType(array,labels,sessions,thresh,cellType,sessionsToCheck)
%       array               cell array of data
%       labels              cell array of strings containing column headers
%       sessions            cell array of string containing session names
%       thresh              structure containing thresholds (i.e. firing rate, grid score)
%       cellType            string specifying functional type. accepted strings:
%                               'excitatory','inhibitory','place','HD','grid','nongrid','border','spatial'
%       sessionsToCheck     cell array of strings with sessions to check for non-firing rate criteria
%                               (e.g. {'BL','CNO'} (default) will check if *EITHER* of these 2 sessions meet place cell criteria)
%
%   OUTPUT
%       array               functional array
%
% Written by BRK 2017

function array = cellType(array,labels,sessions,thresh,cellType,sessionsToCheck)

if ~exist('sessionsToCheck','var')
    sessionsToCheck = {'BL','CNO'};
end

%% baseline firing rate threshold
if sum(strcmpi(cellType,{'excitatory','place','HD','grid','nongrid','border','spatial'}))
    cellsToKeep = extract.cols(array,labels,'cell num','session',sessions{1},'mean rate','<',thresh.FR);
elseif strcmpi(cellType,'inhibitory')
    cellsToKeep = extract.cols(array,labels,'cell num','session',sessions{1},'mean rate','>=',thresh.FR);
end
array = extract.rows(array,labels,'keep','cell num',cellsToKeep);

%% cell-type specific filtering
cellsToKeep = [];
switch cellType
    
    case 'place'
        for iSession = 1:length(sessionsToCheck)
            temp = extract.cols(array,labels,'cell num','session',sessionsToCheck{iSession},'mean rate','>=',0.1,'number of fields','>',0);
            cellsToKeep = [cellsToKeep; temp];
        end
    case 'HD'
        for iSession = 1:length(sessionsToCheck)
            temp = extract.cols(array,labels,'cell num','session',sessionsToCheck{iSession},'mean vector length','>=',thresh.HD);
            cellsToKeep = [cellsToKeep; temp];
        end
    case 'grid'
        for iSession = 1:length(sessionsToCheck)
            temp = extract.cols(array,labels,'cell num','session',sessionsToCheck{iSession},'grid score','>=',thresh.grid);
            cellsToKeep = [cellsToKeep; temp];
        end
    case 'nongrid'
        for iSession = 1:length(sessionsToCheck)
            temp = extract.cols(array,labels,'cell num','session',sessionsToCheck{iSession},'grid score','<=',thresh.grid);
            cellsToKeep = [cellsToKeep; temp];
        end
    case 'border'
        for iSession = 1:length(sessionsToCheck)
            temp = extract.cols(array,labels,'cell num','session',sessionsToCheck{iSession},'border score','>=',thresh.border);
            cellsToKeep = [cellsToKeep; temp];
        end
    case 'spatial'
        for iSession = 1:length(sessionsToCheck)
            temp = extract.cols(array,labels,'cell num','session',sessionsToCheck{iSession},'spatial info','>=',thresh.spatial, ...
                'grid score','<',thresh.grid,'border score','<',thresh.border);
            cellsToKeep = [cellsToKeep; temp];
        end
        
end
array = extract.rows(array,labels,'keep','cell num',unique(cellsToKeep));
