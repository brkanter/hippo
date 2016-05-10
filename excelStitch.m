
% Read in all Excel files from specified folder and stitch together sheets of common name.
% Saves result in new Excel file in the same folder the data came from.
%
%   USAGE
%       excelStitch
%
%   SEE ALSO
%       emperorPenguin emperorPenguinSelect kingPenguinSelect addCellNums
%
% Written by BRK 2016

function excelStitch

%% ask where data lives
folder = uigetdir('Select directory with Excel files to stitch');
if ~folder; return; end
sheetName = inputdlg('Worksheet name:','',1,{'Main (2)'});
if isempty(sheetName); return; end

%% set output location
outName = inputdlg('Name for new Excel file:','',1,{'masterExcel'});
if isempty(outName); return; end
outFile = fullfile(folder,[outName{1} '.xlsx']);

%% read data and stitch
cd(folder);
d = dir('*.xlsx');
data = [];
for iFile = 1:length(d)
    [~,~,temp] = xlsread(d(iFile).name,sheetName{1});
    if iFile == 1
        data = [data; temp];
    else
        data = [data; temp(2:end,:)];
    end
end

%% write data
xlswrite(outFile,data,'master');