%% CHANGE THE NAME OF THIS FUNCTION TO STARTUP.M AND MAKE SURE IT IS VISIBLE ON YOUR PATH %%
% also change the 2 lines containing directory locations so they make sense for your computer

%% update path and start BNT
addpath(genpath('\\home.ansatt.ntnu.no\benjamka\My Documents\MATLAB'));

set(groot,'defaultfigurecolor','w','defaultfigurecolormap',jet);
close

InitBNT();

%% update globals
global penguinInput ...
    arena mapLimits ...
    dSmoothing dBinWidth dMinBins...
    clusterFormat

penguinInput = '\\home.ansatt.ntnu.no\benjamka\My Documents\MATLAB\Ben\penguinInput.txt';

clusterFormat = 'MClust';
% clusterFormat = 'SS_t';
% clusterFormat = 'Tint';

dSmoothing = 2;

% environment-specific settings
 
arena = 'cylinder 60 60';
mapLimits = [-30,30,-30,30];
dBinWidth = 2;
dMinBins = 20;

% arena = 'box 60 60';
% mapLimits = [-30,30,-30,30];
% dBinWidth = 2;
% dMinBins = 20;
 
% arena = 'box 120 90';
% mapLimits = [-60,60,-45,45];
% dBinWidth = 4;
% dMinBins = 5;

% arena = 'box 100 100';
% mapLimits = [-50,50,-50,50];
% dBinWidth = 4;
% dMinBins = 5;

% arena = 'box 46 24';
% mapLimits = [-23,23,-12,12];
% dBinWidth = 2;
% dMinBins = 20;


