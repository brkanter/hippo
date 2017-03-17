
%% CHANGE THE NAME OF THIS FUNCTION TO STARTUP.M AND MAKE SURE IT IS VISIBLE ON YOUR PATH %%
% also change the 2 lines containing directory locations so they make sense for your computer

%% update path and start BNT
addpath(genpath('\\home.ansatt.ntnu.no\benjamka\My Documents\MATLAB'));

set(groot,'defaultfigurecolor','w','defaultfigurecolormap',jet);
close

InitBNT();

%% update globals
global hippoGlobe

hippoGlobe.penguinInput = '\\home.ansatt.ntnu.no\benjamka\My Documents\MATLAB\Ben\hippo\penguinInput.txt';
hippoGlobe.posSpeedFilter = [2 0];  % ignore times when animal moves < 2 cm/sec

hippoGlobe.clusterFormat = 'MClust';
% hippoGlobe.clusterFormat = 'SS_t';
% hippoGlobe.clusterFormat = 'Tint';

hippoGlobe.smoothing = 2;

% -- environment-specific settings --
 
hippoGlobe.arena = 'cylinder 60 60';
hippoGlobe.mapLimits = [-30,30,-30,30];
hippoGlobe.binWidth = 2;
hippoGlobe.minBins = 20;

% hippoGlobe.arena = 'box 60 60';
% hippoGlobe.mapLimits = [-30,30,-30,30];
% hippoGlobe.binWidth = 2;
% hippoGlobe.minBins = 20;
 
% hippoGlobe.arena = 'box 120 90';
% hippoGlobe.mapLimits = [-60,60,-45,45];
% hippoGlobe.binWidth = 4;
% hippoGlobe.minBins = 5;

% hippoGlobe.arena = 'box 100 100';
% hippoGlobe.mapLimits = [-50,50,-50,50];
% hippoGlobe.binWidth = 4;
% hippoGlobe.minBins = 5;

% hippoGlobe.arena = 'box 46 24';
% hippoGlobe.mapLimits = [-23,23,-12,12];
% hippoGlobe.binWidth = 2;
% hippoGlobe.minBins = 20;


