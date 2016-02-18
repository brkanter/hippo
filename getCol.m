
% Extract column from array based on text labels.
%
%   USAGE
%       colOut = getCol(array,labels,colToGet)
%       array          cell array of data
%       labels         cell array of strings containing column headers
%       colToGet       string label of column to extract
%
%   OUTPUT
%       colOut         extracted column from array
%
%   SEE ALSO
%       getColComp deleteRowsComp
%
% Written by BRK 2016

function colOut = getCol(array,labels,colToGet)

%% get all rows with specified column
if ischar(colToGet)
    colOut = eval(sprintf('array(:,strcmpi(''%s'',labels));',colToGet));
end  
if length(colOut) == 1
    colOut = colOut{1};
end
    