
% Read in Excel worksheet generated by addCellNums and add rate maps and count
% maps. Saves result in mat file.
%
%   USAGE
%       kingPenguin
%
%   SEE ALSO
%       addCellNums emperorPenguin
%
% Written by BRK 2015

function kingPenguin

%% get globals
global penguinInput arena mapLimits dSmoothing dBinWidth clusterFormat
if isempty(penguinInput)
    startup
end

%% read excel file to analyze
[filename filepath] = uigetfile({'*.xlsx','*.xls'},'Select Excel workbook');
if ~filename; return; end
excelFile = fullfile(filepath,filename);
sheetName = inputdlg('Worksheet name:','',1,{'masterCellNums'});
if isempty(sheetName); return; end
[~,~,raw] = xlsread(excelFile,sheetName{1});

%% set output location
excelFolder = uigetdir('','Choose folder for the mat file output');
if ~excelFolder; return; end
matName = inputdlg('Mat file name:','',1,{'masterMat'});
if isempty(matName); return; end
matFile = fullfile(excelFolder,matName{1});

%% get column headers and folder names
clear labels
for iLabel = 1:size(raw,2)
    labels{iLabel} = raw{1,iLabel};
end
allFolders = raw(2:end,1)';
uniqueFolders = unique(allFolders);
dataInput = raw(2:end,:);  

%% rate map settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Mininum occupancy'};
name='Map settings';
numlines=1;
defaultanswer={num2str(dSmoothing),num2str(dBinWidth),'0'};
Answers2 = inputdlg(prompt,name,numlines,defaultanswer,'on');
if isempty(Answers2); return; end;
smooth = str2double(Answers2{1});
binWidth = str2double(Answers2{2});
minTime = str2double(Answers2{3});
counter = 1;

%% compute stats for each folder
for iFolder = 1:length(uniqueFolders)
    display(sprintf('Folder %d of %d',iFolder,length(uniqueFolders)))
    %% initialize storage structure
    trode(1:1000)={zeros(1,1000)};
    unit(1:1000)={struct('unit', trode)};
    folder=struct('trode',unit);
    folder(1000).trode(1000).unit(1000) = 0;
    cd(uniqueFolders{1,iFolder});            
    %% find all tetrode and cluster numbers
    % NB: this extracts T and C nums from excel sheet, so cluster format
    % not important until loadSessions
    folderInds = find(strcmpi(dataInput(:,1),uniqueFolders(iFolder)));
    for iCluster = 1:length(folderInds)
        t_num = cell2mat(dataInput(folderInds(iCluster),strcmpi('tetrode',labels)));
        c_num = cell2mat(dataInput(folderInds(iCluster),strcmpi('cluster',labels)));
        folder(iFolder).trode(t_num).unit(c_num) = c_num;  
    end
    tetList{8} = '';
    unitList = [];
    for iTrode = 1:8
        if sum(folder(iFolder).trode(iTrode).unit) > 0;
            tetList{iTrode} = num2str([iTrode,folder(iFolder).trode(iTrode).unit(folder(iFolder).trode(iTrode).unit~=0)]);
            unitList = [unitList, tetList{iTrode}, '; '];
        else
            tetList{iTrode} = '';
        end
    end
    %% create cut list for input file
    clusterList = dir('*.t');
    cutList = [];
    if ~isempty(strfind(clusterList(1).name,'PP')) && isempty(strfind(clusterList(1).name,'SS')) % norway MClust
        for iTrode = 1:4
            if (length(tetList{iTrode}) > 1) && iTrode == 1
                cutList = [cutList,'PP4_TT%u_%u; '];
            elseif (length(tetList{iTrode}) > 1) && iTrode == 2
                cutList = [cutList,'PP6_TT%u_%u; '];
            elseif (length(tetList{iTrode}) > 1) && iTrode == 3
                cutList = [cutList,'PP7_TT%u_%u; '];
            elseif (length(tetList{iTrode}) > 1) && iTrode == 4
                cutList = [cutList,'PP3_TT%u_%u; '];
            else
                continue
            end
        end
    elseif ~isempty(strfind(clusterList(1).name,'PP')) && ~isempty(strfind(clusterList(1).name,'SS')) % norway SS
        for iTrode = 1:4
            if (length(tetList{iTrode}) > 1) && iTrode == 1
                cutList = [cutList,'PP4_TT%u_SS_%02u; '];
            elseif (length(tetList{iTrode}) > 1) && iTrode == 2
                cutList = [cutList,'PP6_TT%u_SS_%02u; '];
            elseif (length(tetList{iTrode}) > 1) && iTrode == 3
                cutList = [cutList,'PP7_TT%u_SS_%02u; '];
            elseif (length(tetList{iTrode}) > 1) && iTrode == 4
                cutList = [cutList,'PP3_TT%u_SS_%02u; '];
            else
                continue
            end
        end
    elseif isempty(strfind(clusterList(1).name,'SS')) && isempty(strfind(clusterList(1).name,'PP')) % oregon MClust
        cutList = 'TT; ';
    elseif ~isempty(strfind(clusterList(1).name,'SS')) && isempty(strfind(clusterList(1).name,'PP')) % oregon SS
        cutList = 'TT%u_SS_%02u; ';
    else
        error('Unknown cluster type.')
    end
    %% write BNT input file
    fileID = fopen(penguinInput,'w');
    fprintf(fileID,'Name: general; Version: 1.0\nSessions %s\nCuts %s\nUnits %s\nShape %s',uniqueFolders{1,iFolder},cutList,unitList,arena);
    data.loadSessions(penguinInput);
    %% get positions, spikes, map, and rates
    pos = data.getPositions('average','off','speedFilter',[2 0]);
    posAve = data.getPositions('speedFilter',[2 0]);
    save(fullfile(uniqueFolders{1,iFolder},'posCleanScaled.mat'),'pos','posAve');
    posT = posAve(:,1);
    posX = posAve(:,2);
    posY = posAve(:,3);
    cellMatrix = data.getCells;
    numClusters = size(cellMatrix,1);
    for iCluster = 1:numClusters     % loop through all cells
        display(sprintf('Cluster %d of %d',iCluster,numClusters))
        %% general calculations
        spikes = data.getSpikeTimes([cell2mat(dataInput(folderInds(iCluster),strcmpi('tetrode',labels))) cell2mat(dataInput(folderInds(iCluster),strcmpi('cluster',labels)))]);
        spikePos = data.getSpikePositions(spikes,posAve);
        map = analyses.map([posT posX posY], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', mapLimits);
        meanRate = analyses.meanRate(spikes, posAve);
        if ~isfield(map,'peakRate')
            meanRate = nan;
            peakRate = nan;
        else
            peakRate = map.peakRate;
        end
        %% store data
        mapArray{folderInds(iCluster),1} = map.z;
        mapCountArray{folderInds(iCluster),1} = map.count;
        counter = counter + 1;
    end    
end

%% add column headers back
rateMapIdx = length(labels)+1;
countMapIdx = rateMapIdx+1;
labels{1,rateMapIdx} = 'Rate map';
labels{1,countMapIdx} = 'Count map';
dataOutput = [dataInput, mapArray, mapCountArray];

%% add mouse IDs using filenames
labels(end+1) = {'Mouse ID'};
for iRow = 1:size(dataOutput,1)
    filename = dataOutput{iRow,strcmpi('folder',labels)};
    %% aldis MEC
%     startIdx = strfind(filename,'DRD');
%     startIdx = startIdx(1);
%     mouseID = filename(startIdx:startIdx+4);
    %% aldis CA1
%     startIdx = strfind(filename,'DRD');
%     startIdx = startIdx(1);
%     mouseID = filename(startIdx:startIdx+4);
%     if strcmpi(mouseID(end),' ')
%         mouseID = mouseID(1:end-1);
%     end
    %% ben
    startIdx = strfind(filename,'BK');
    if ~isempty(startIdx)
        mouseID = filename(startIdx:startIdx+4);
    else
        startIdx = strfind(filename,'CML');
        mouseID = filename(startIdx:startIdx+3);
    end
    dataOutput(iRow,strcmpi('mouse id',labels)) = {mouseID};
end

%% add unique experiment numbers
Answer = questdlg('Do all experiments have the same number of sessions?');
% set flag to be able to break out
flag = 1;
while flag
    if strcmpi(Answer,'Yes')
        labels(end+1) = {'Exp num'};
        folderList = uniqueFolders';
        try     % maybe we already have sessions
            seshNames = unique(dataOutput(:,strcmpi('session',labels)));
            numSesh = numel(seshNames);
        catch   % or maybe we don't
            Answer2 = inputdlg('How many sessions are in each experiment?','',1,{'3'});
            if ~isempty(Answer2)
                numSesh = str2double(Answer2{1});
            else   % abort
                warning('Not adding experiment numbers because you didn''t answer.');
                labels = labels(1:end-1);
                flag = 0;
            end
        end
        % add exp nums here
        numList = [];
        for iExp = 1:length(folderList)/numSesh
            numList = [numList; repmat(iExp,numSesh,1)];
        end
        folderList(:,2) = num2cell(numList);
        temp_data = dataOutput;
        for iRow = 1:size(temp_data,1)
            folderIdx = find(strcmpi(temp_data{iRow,1},folderList(:,1)));
            temp_data(iRow,strcmpi('exp num',labels)) = folderList(folderIdx,2);
        end
        dataOutput = temp_data;
        flag = 0;
    else
        flag = 0;
    end
end

%% convert some numbers into strings to make things easier later 
for iRow = 1:size(dataOutput,1)
    dataOutput{iRow,strcmpi('cell num',labels)} = num2str(dataOutput{iRow,strcmpi('cell num',labels)});
    dataOutput{iRow,strcmpi('quality',labels)} = num2str(dataOutput{iRow,strcmpi('quality',labels)});
end
if sum(strcmpi('exp num',labels))
    for iRow = 1:size(dataOutput,1)
        dataOutput{iRow,strcmpi('exp num',labels)} = num2str(dataOutput{iRow,strcmpi('exp num',labels)});
    end
end
if sum(strcmpi('dose',labels))
    for iRow = 1:size(dataOutput,1)
        dataOutput{iRow,strcmpi('dose',labels)} = num2str(dataOutput{iRow,strcmpi('dose',labels)});
    end
end
if sum(strcmpi('cno num',labels))
    for iRow = 1:size(dataOutput,1)
        if isnan(dataOutput{iRow,strcmpi('cno num',labels)})
            dataOutput{iRow,strcmpi('cno num',labels)} = 0;
        end
    end
end

%% save everything without positions and spike times
save(matFile,'dataOutput','labels');

load handel
sound(y(1:7000),Fs)