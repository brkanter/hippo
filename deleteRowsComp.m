
% Delete rows from array that contain certain info.
%
%   USAGE
%       array = deleteRowsComp(array,labels,varagin)
%       array          cell array of data
%       labels         cell array of strings containing column headers
%       varargin       string or double comparisons for removing data
%                       (e.g. 'session',sessions{1},'mean rate','>=',10
%                       will remove the first session where mean rate >= 10)
%
%   OUTPUT
%       array          filtered array
%
%   SEE ALSO
%       getCol getColComp
%
% Written by BRK 2016

function array = deleteRowsComp(array,labels,varargin)

%% double comparisons
dStartInds = find(cellfun(@isnumeric,varargin)) - 2;
dComps = {};
indsToRemove = [];
for iComp = 1:length(dStartInds)
    temp = varargin(dStartInds(iComp):dStartInds(iComp) + 2);
    if iComp == 1
        dComps = temp;
        indsToRemove = dStartInds(iComp):dStartInds(iComp) + 2;
    else
        dComps = [dComps; temp];
        indsToRemove = [indsToRemove, dStartInds(iComp):dStartInds(iComp) + 2];
    end
end
modVarargin = varargin;
modVarargin(indsToRemove) = '';

%% string comparisons
sComps = {};
for iComp = 1:2:length(modVarargin)
    temp = modVarargin(iComp:iComp + 1);
    if iComp == 1
        sComps = temp;
    else
        sComps = [sComps; temp];
    end
end

%% delete rows
for iComp = 1:size(sComps,1)
    eval(sprintf('array(strcmpi(array(:,strcmpi(''%s'',labels)),''%s''),:) = [];',sComps{iComp,1},sComps{iComp,2}));
end
for iComp = 1:size(dComps,1)
    eval(sprintf('array(cell2mat(array(:,strcmpi(''%s'',labels))) %s %d),:) = [];',dComps{iComp,1},dComps{iComp,2},dComps{iComp,3}));
end
