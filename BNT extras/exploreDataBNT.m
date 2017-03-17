
% Load data from a recording session with BNT so that all BNT functions are ready to use.
%
%   USAGE
%       exploreData
%
%   NOTES
%       This function is bare bones by design so that the user can add whatever information is relevant to them.
%
% Written by BRK 2017

function exploreDataBNT

%% get globals
global hippoGlobe
if isempty(hippoGlobe.inputFile)
    startup
end

%% choose recording session and load the data
folder = uigetdir();
writeInputBNT(hippoGlobe.inputFile,folder,hippoGlobe.arena,hippoGlobe.clusterFormat)
data.loadSessions(hippoGlobe.inputFile)

%% plot animal's trajectory
figure;
hold on
pathTrialBRK('color',[.5 .5 .5])
axis off

%% display cluster list
clusterList = data.getCells;
display(clusterList)