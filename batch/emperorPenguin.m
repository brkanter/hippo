
% Create Excel worksheet containing all selected measures for a given experiment.
%
%   USAGE
%       emperorPenguin(update)
%       update      (optional) 'update' will call emperorPenguinUpdate to update spreadsheet
%                   with new values, while any other input (or lack thereof) will start from scratch
%
%   NOTES
%       Common error is 'Subscripted assignment dimension mismatch' when
%       computing spatial correlations. This is because there is not the
%       same number of clusters in all recording sessions for this
%       experiment. For clusters of only a few spikes, they are sometimes
%       discarded and you will need to add more spikes.
%
%   SEE ALSO
%       emperorPenguinUpdate addCellNums kingPenguin
%
% Written by BRK 2014

function emperorPenguin(update)

tic

%% check input
if nargin
    if strcmpi(update,'update')
        emperorPenguinUpdate
    else
        error('Optional input argument not recognized')
    end
    return
end

%% get globals
global penguinInput arena mapLimits dSmoothing dBinWidth dMinBins clusterFormat
if isempty(penguinInput)
    startup
end

%% select folders to analyze
allFolders = uipickfilesBRK();
if ~iscell(allFolders); return; end;
    
%% initialize options
include_3Ss = 0;
include_coherence = 0;
include_fields = 0;
include_grid = 0;
include_HD = 0;
include_speed = 0;
include_theta = 0;
include_CC = 0;
include_DS = 0;
include_obj = 0;

%% choose what to calculate
[selections, OK] = listdlg('PromptString','Select what to calculate', ...
    'ListString',{'Spat. info. content, selectivity, and sparsity (SLOW)', ...
    'Coherence','Field info and border scores', 'Grid stats','Head directions', ...
    'Speed score (SLOW)','Theta indices', ...
    'Spatial cross correlations','Rate difference scores (CHRISTY ONLY)','Objects'}, ...
    'InitialValue',1:8, ...
    'ListSize',[400, 250]);
if OK == 0; return; end;
if ismember(1,selections); include_3Ss = 1; end
if ismember(2,selections); include_coherence = 1; end
if ismember(3,selections); include_fields = 1; end
if ismember(4,selections); include_grid = 1; end
if ismember(5,selections); include_HD = 1; end
if ismember(6,selections); include_speed = 1; end
if ismember(7,selections); include_theta = 1; end
if ismember(8,selections); include_CC = 1; end
if ismember(9,selections); include_DS = 1; end
if ismember(10,selections); include_obj = 1; end

%% get experiment details for cross corrs. and excel output
if include_CC || include_DS
    prompt={'How many sessions per experiment?'};
    name='Sessions/experiment';
    numlines=1;
    defaultanswer={'3'};
    Answers2 = inputdlg(prompt,name,numlines,defaultanswer,'on');
    if isempty(Answers2); return; end;
    seshPerExp = str2double(Answers2{1});
end

%% rate map settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Mininum occupancy'};
name='Map settings';
numlines=1;
defaultanswer={num2str(dSmoothing),num2str(dBinWidth),'0'};
Answers3 = inputdlg(prompt,name,numlines,defaultanswer,'on');
if isempty(Answers3); return; end;
smooth = str2double(Answers3{1});
binWidth = str2double(Answers3{2});
minTime = str2double(Answers3{3});

%% find field settings
if include_fields
    prompt={'Threshold for including surrounding bins (included if > thresh*peak)','Spatial bin width (cm)','Minimum bins for a field','Minimum peak rate for a field (Hz?)'};
    name='Find field settings';
    numlines=1;
    defaultanswer={'0.2',num2str(dBinWidth),num2str(dMinBins),'1'};
    Answers4 = inputdlg(prompt,name,numlines,defaultanswer,'on');
    if isempty(Answers4); return; end;
    fieldThresh = str2double(Answers4{1});
    binWidth = str2double(Answers4{2});
    minBins = str2double(Answers4{3});
    minPeak = str2double(Answers4{4});
end

%% grid stats settings
if include_grid
    prompt={'Normalized threshold value used to search for peaks on the autocorrelogram (0:1)'};
    name='Grid stats settings';
    numlines=1;
    defaultanswer={'0.2'};
    Answers5 = inputdlg(prompt,name,numlines,defaultanswer,'on');
    if isempty(Answers5); return; end;
    gridThresh = str2double(Answers5{1});
    if gridThresh < 0 || gridThresh > 1
        gridThresh = 0.2;
        display('Grid threshold value out of range, using default 0.2.')
    end
end

%% object settings
if include_obj
    [file,path] = uigetfile('*.mat','Choose object locations');
    load(fullfile(path,file))
end

%% excel output folder
excelFolder = uigetdir('','Choose folder for the Excel output');
if excelFolder == 0; return; end;
dt = datestr(clock,30);
ending = ['\emperor' sprintf('%s.xlsx',dt)];
fullName = [excelFolder ending];

%% excel column headers
colHeaders = {'Folder','Tetrode','Cluster','Mean rate','Peak rate','Total spikes','Spike width (usec)','Quality','L_Ratio','Isolation distance'};
if include_3Ss
    colHeaders = [colHeaders,'Spatial info','Selectivity','Sparsity'];
end
if include_coherence
    colHeaders = [colHeaders,'Coherence'];
end
if include_fields
    colHeaders = [colHeaders,'Number of fields','Mean field size (cm2)','Max field size (cm2)','COM x','COM y','Border score'];
end
if include_grid
    colHeaders = [colHeaders,'Grid score','Grid spacing','Orientation 1','Orientation 2','Orientation 3'];
end
if include_HD
    colHeaders = [colHeaders,'Mean vector length','Mean angle'];
end
if include_speed
    colHeaders = [colHeaders,'Speed score'];
end
if include_theta
    colHeaders = [colHeaders,'Theta index spikes','Theta index LFP'];
end
if include_obj
    colHeaders = [colHeaders, ...
        'Rate ratio O1', ...
        'Rate ratio O2', ...
        'P val rate O1', ...
        'P val rate O2', ...
        'P val rate all objs', ...
        'Time ratio O1', ...
        'Time ratio O2', ...
        'P val time O1', ...
        'P val time O2', ...
        'P val time all objs'];
end

%% compute stats for each folder
for iFolder = 1:length(allFolders)
    display(sprintf('Folder %d of %d',iFolder,length(allFolders)))
    writeInputBNT(penguinInput,allFolders{1,iFolder},arena,clusterFormat)
    data.loadSessions(penguinInput);
    %% get positions, spikes, map, and rates
    posAve = data.getPositions('speedFilter',[2 0]);
    posT = posAve(:,1);
    posX = posAve(:,2);
    posY = posAve(:,3);
    %% extract necessary measures that don't rely on clusters to save time
    if include_HD
        pos = data.getPositions('average','off','speedFilter',[2 0]);
        allHD = analyses.calcHeadDirection(pos);
    end
    if include_speed
        Speed = general.speed(posAve);
    end
    %% loop through all cells
    cellMatrix = data.getCells;
    numClusters = size(cellMatrix,1);
    for iCluster = 1:numClusters
        display(sprintf('Cluster %d of %d',iCluster,numClusters))        
        %% cluster quality: set PP nums for Norwegian scheme
        if cellMatrix(iCluster,1) == 1
            PP = 4;
        elseif cellMatrix(iCluster,1) == 2
            PP = 6;
        elseif cellMatrix(iCluster,1) == 3
            PP = 7;
        elseif cellMatrix(iCluster,1) == 4
            PP = 3;
        end
        % qualitative cluster quality
        try
            load(fullfile(allFolders{1,iFolder},sprintf('TT%d_%d-Quality.mat',cellMatrix(iCluster,1),cellMatrix(iCluster,2)))) % oregon
        catch
            try
                load(fullfile(allFolders{1,iFolder},sprintf('PP%d_TT%d_%d-Quality.mat',PP,cellMatrix(iCluster,1),cellMatrix(iCluster,2))))  % norway
            catch
                quality = 999999;
            end
        end
        % quantitative cluster quality
        try    % MClust 4.3
            if cellMatrix(iCluster,2) < 10 
                try
                    load(fullfile(allFolders{1,iFolder},sprintf('TT%d_0%d-CluQual.mat',cellMatrix(iCluster,1),cellMatrix(iCluster,2))))  % oregon
                catch
                    try
                        load(fullfile(allFolders{1,iFolder},sprintf('PP%d_TT%d_0%d-CluQual.mat',PP,cellMatrix(iCluster,1),cellMatrix(iCluster,2))))  % norway
                    end
                end
            else
                try
                    load(fullfile(allFolders{1,iFolder},sprintf('TT%d_%d-CluQual.mat',cellMatrix(iCluster,1),cellMatrix(iCluster,2))))  % oregon
                catch
                    load(fullfile(allFolders{1,iFolder},sprintf('PP%d_TT%d_%d-CluQual.mat',PP,cellMatrix(iCluster,1),cellMatrix(iCluster,2))))  % norway
                end
            end
            L_ratio = CluSep.L_Ratio.Lratio;
            isolationDist = CluSep.IsolationDistance;
        catch    % MClust 3.5
            try
                load(fullfile(allFolders{1,iFolder},sprintf('TT%d_%d-CluQual_MC35.mat',cellMatrix(iCluster,1),cellMatrix(iCluster,2))))
            catch
                L_ratio = 999999;
                isolationDist = 999999;
            end
        end        
        %% general calculations
        spikes = data.getSpikeTimes([cellMatrix(iCluster,1) cellMatrix(iCluster,2)]);
        map = analyses.map([posT posX posY], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime,'limits', mapLimits);
        meanRate = analyses.meanRate(spikes, posAve);
        if ~isfield(map,'peakRate')
            peakRate = 0;
        else
            peakRate = map.peakRate;
        end
        totalSpikes = length(spikes);
        try
            spikeWidth = halfMaxWidth(allFolders{1,iFolder}, cellMatrix(iCluster,1), spikes);
        catch
            spikeWidth = 999999;
        end
        %% descriptive stats
        if include_3Ss
            [info,spars,sel] = analyses.mapStatsPDF(map);
        end
        if include_coherence
            Coherence = analyses.coherence(map.z);
        end
        %% field stats and border scores
        if include_fields
            [fieldsMap, fields] = analyses.placefield(map,'threshold',fieldThresh,'binWidth',binWidth,'minBins',minBins,'minPeak',minPeak);
            if ~isempty(fields)
                fieldNo = length(fields);
                sizes = nan(1,50);
                for iField = 1:length(fields)
                    sizes(iField) = fields(1,iField).size;
                end
                biggestField = find(sizes == nanmax(sizes));
                fieldMean = nanmean(sizes);
                fieldMax = nanmax(sizes);
                fieldCOMx = fields(1,biggestField).x;
                fieldCOMy = fields(1,biggestField).y;
                if ~isempty(fieldsMap)
                    border = analyses.borderScore(map.z, fieldsMap, fields);
                else
                    border = 999999;
                end
            else
                fieldNo = 0;
                fieldMean = 999999;
                fieldMax = 999999;
                fieldCOMx = 999999;
                fieldCOMy = 999999;
                border = 999999;
            end
        end
        %% grid statistics
        if include_grid
            autoCorr = analyses.autocorrelation(map.z);
            try
                [score, stats] = analyses.gridnessScore(autoCorr, 'threshold', gridThresh);
                if ~isempty(stats.spacing)
                    gridScore = score;
                    gridSpacing = mean(stats.spacing);
                    gridOrientation1 = stats.orientation(1);
                    gridOrientation2 = stats.orientation(2);
                    gridOrientation3 = stats.orientation(3);
                else
                    gridScore = 999999;
                    gridSpacing = 999999;
                    gridOrientation1 = 999999;
                    gridOrientation2 = 999999;
                    gridOrientation3 = 999999;
                end
            catch
                gridScore = 999999;
                gridSpacing = 999999;
                gridOrientation1 = 999999;
                gridOrientation2 = 999999;
                gridOrientation3 = 999999;
            end
        end
        %% head direction
        if include_HD
            [spikePos,spkInd] = data.getSpikePositions(spikes,posAve);
            try
                spkHDdeg = analyses.calcHeadDirection(pos(spkInd,:));
                tc = analyses.turningCurve(spkHDdeg, allHD, data.sampleTime,'binWidth',6);
                tcStat = analyses.tcStatistics(tc,6,20);
                vLength = tcStat.r;
                meanAngle = tcStat.mean;
            catch
                vLength = 999999;
                meanAngle = 999999;
            end
        end
        %% speed
        if include_speed
            if ~exist('spikePos','var')
                spikePos = data.getSpikePositions(spikes,posAve);
            end
            instRate = analyses.instantRate(spikePos(:,1),posAve);
            kernel = (1 / helpers.sampleTimeFromData(posAve)) / 0.4;   % smoothing kernel = 0.4 sec
            scores = analyses.speedScore(Speed,instRate,kernel);
            speedScore = scores(2);
        end
        %% theta
        if include_theta
            try
                if length(spikes) > 100
                    [~,~,thetaIndSpikes] = thetaIndex(spikes);
                else
                    thetaIndSpikes = nan;
                end
            catch
                thetaIndSpikes = nan;
            end
            try
                thetaIndLFP = thetaIndexLFP(allFolders{1,iFolder},cellMatrix(iCluster,1));
            catch
                thetaIndLFP = nan;
            end
        end
        if include_obj
            rateMap = map.z;
            occupancyMap = map.time;                
            %% object responses using rate maps
            % bins occupied by objects
            nBinsObj1 = sum(sum(objectLocations == 1));
            nBinsObj2 = sum(sum(objectLocations == 2));
            nBinsObjAll = nBinsObj1 + nBinsObj2;
            logicObjAll = objectLocations > 0;
            % rate in each object zone
            rateObj1 = rateMap(objectLocations == 1);
            rateObj2 = rateMap(objectLocations == 2);
            rateObjAll = rateMap(logicObjAll);
            % rate outside of object zones
            rateNoObj = rateMap;
            rateNoObj(logicObjAll) = NaN;
            logicNoObj = rateNoObj > 0;
            nBinsNoObj = sum(sum(logicNoObj));
            rateNoObj = rateNoObj(rateNoObj > 0);
            % test for object responses
            objResponsesRateIncrease = nan(2,500);
            objResponsesRatePval = nan(3,500);
            if nBinsNoObj >= nBinsObjAll;
                for iTest = 1:500
                    randInds = randi(nBinsNoObj,1,nBinsNoObj);
                    compObj1 = rateNoObj(randInds(1:nBinsObj1));
                    compObj2 = rateNoObj(randInds(1:nBinsObj2));
                    compObjAll = rateNoObj(randInds(1:(nBinsObj1+nBinsObj2)));
                    objResponsesRateIncrease(1,iTest) = nanmean(rateObj1)/nanmean(compObj1);
                    objResponsesRateIncrease(2,iTest) = nanmean(rateObj2)/nanmean(compObj2);
                    [~,objResponsesRatePval(1,iTest)] = ttest2(compObj1,rateObj1);
                    [~,objResponsesRatePval(2,iTest)] = ttest2(compObj2,rateObj2);
                    [~,objResponsesRatePval(3,iTest)] = ttest2(compObjAll,rateObjAll);
                end
            end
            objRate = [nanmean(objResponsesRateIncrease(1,:)) ...
                nanmean(objResponsesRateIncrease(2,:)) ...
                nanmean(objResponsesRatePval(1,:)) ...
                nanmean(objResponsesRatePval(2,:)) ...
                nanmean(objResponsesRatePval(3,:))];
            %% object responses using occupancy maps
            % bins occupied by objects
            nBinsObj1 = sum(sum(objectLocations == 1));
            nBinsObj2 = sum(sum(objectLocations == 2));
            nBinsObjAll = nBinsObj1 + nBinsObj2;
            logicObjAll = objectLocations > 0;
            % time in each object zone
            timeObj1 = occupancyMap(objectLocations == 1);
            timeObj2 = occupancyMap(objectLocations == 2);
            timeObjAll = occupancyMap(logicObjAll);
            % time outside of object zones
            timeNoObj = map.time;
            timeNoObj(logicObjAll) = NaN;
            logicNoObj = timeNoObj > 0;
            nBinsNoObj = sum(sum(logicNoObj));
            timeNoObj = timeNoObj(timeNoObj > 0);
            % test for object responses
            objResponsesTimeIncrease = nan(2,500);
            objResponsesTimePval = nan(3,500);
            if nBinsNoObj >= nBinsObjAll;
                for iTest = 1:500
                    randInds = randi(nBinsNoObj,1,nBinsNoObj);
                    compObj1 = timeNoObj(randInds(1:nBinsObj1));
                    compObj2 = timeNoObj(randInds(1:nBinsObj2));
                    compObjAll = timeNoObj(randInds(1:(nBinsObj1+nBinsObj2)));
                    objResponsesTimeIncrease(1,iTest) = nanmean(timeObj1)/nanmean(compObj1);
                    objResponsesTimeIncrease(2,iTest) = nanmean(timeObj2)/nanmean(compObj2);
                    [~,objResponsesTimePval(1,iTest)] = ttest2(compObj1,timeObj1);
                    [~,objResponsesTimePval(2,iTest)] = ttest2(compObj2,timeObj2);
                    [~,objResponsesTimePval(3,iTest)] = ttest2(compObjAll,timeObjAll);
                end
            end
            objTime = [nanmean(objResponsesTimeIncrease(1,:)) ...
                nanmean(objResponsesTimeIncrease(2,:)) ...
                nanmean(objResponsesTimePval(1,:)) ...
                nanmean(objResponsesTimePval(2,:)) ...
                nanmean(objResponsesTimePval(3,:))];
        end
        
        %% store info from this folder in arrays
        Mfolder{iCluster,iFolder} = allFolders{1,iFolder}; %#ok<*AGROW>
        Mtetrode(iCluster,iFolder) = cellMatrix(iCluster,1);
        Mcluster(iCluster,iFolder) = cellMatrix(iCluster,2);
        MrateMap{iCluster,iFolder} = map.z;
        McountMap{iCluster,iFolder} = map.count;
        MmeanRate(iCluster,iFolder) = meanRate;
        MpeakRate(iCluster,iFolder) = peakRate;
        MtotalSpikes(iCluster,iFolder) = totalSpikes;
        MspikeWidth(iCluster,iFolder) = spikeWidth;
        Mquality(iCluster,iFolder) = quality;
        Mratio(iCluster,iFolder) = L_ratio;
        MisolationDist(iCluster,iFolder) = isolationDist;
        if include_3Ss
            MspatInfo(iCluster,iFolder) = info.content;
            Mselectivity(iCluster,iFolder) = sel;
            Msparsity(iCluster,iFolder) = spars;
        end
        if include_coherence
            Mcoherence(iCluster,iFolder) = Coherence;
        end
        if include_fields
            MfieldNo(iCluster,iFolder) = fieldNo;
            MfieldMean(iCluster,iFolder) = fieldMean;
            MfieldMax(iCluster,iFolder) = fieldMax;
            MfieldCOMx(iCluster,iFolder) = fieldCOMx;
            MfieldCOMy(iCluster,iFolder) = fieldCOMy;
            Mborder(iCluster,iFolder) = border;
        end
        if include_grid
            MgridScore(iCluster,iFolder) = gridScore;
            MgridSpacing(iCluster,iFolder) = gridSpacing;
            MgridOrientation1(iCluster,iFolder) = gridOrientation1;
            MgridOrientation2(iCluster,iFolder) = gridOrientation2;
            MgridOrientation3(iCluster,iFolder) = gridOrientation3;
        end
        if include_HD
            MvectorLength(iCluster,iFolder) = vLength;
            MmeanAngle(iCluster,iFolder) = meanAngle;
        end
        if include_speed
            MspeedScore(iCluster,iFolder) = speedScore;
        end
        if include_theta
            MthetaSpikes(iCluster,iFolder) = thetaIndSpikes;
            MthetaLFP(iCluster,iFolder) = thetaIndLFP;
        end
        if include_obj
            Mobj1(iCluster,iFolder) = objRate(1);
            Mobj2(iCluster,iFolder) = objRate(2);
            Mobj3(iCluster,iFolder) = objRate(3);
            Mobj4(iCluster,iFolder) = objRate(4);
            Mobj5(iCluster,iFolder) = objRate(5);
            Mobj6(iCluster,iFolder) = objTime(1);
            Mobj7(iCluster,iFolder) = objTime(2);
            Mobj8(iCluster,iFolder) = objTime(3);
            Mobj9(iCluster,iFolder) = objTime(4);
            Mobj10(iCluster,iFolder) = objTime(5);
        end
    end
    totalClusters(iFolder) = numClusters;
end

%% compute spatial correlations
if include_CC
    msgCC = msgbox('Computing cross correlations...');
    %% initialize
    numMaps = 1:1:seshPerExp;
    combo = nchoosek(numMaps,2);
    numExp(1:length(allFolders)/seshPerExp) = {nan(10000,size(combo,1))};
    CCstruct = {struct('expNum',numExp)};
    CCstruct = squeeze(CCstruct{1,1}(1,:));
    CCoutput = [];
    upCount = 0;
    
    for iExp = 1:(length(allFolders)/seshPerExp)    % all experiments
        cellCount = totalClusters(iExp*seshPerExp-(seshPerExp-1)); % get number of cells in first session of experiment
        %% calculate all correlations
        for iCluster = 1:cellCount    % all cells
            for iCorrs = 1:size(combo,1)       % all session comparisons
                CC = analyses.spatialCrossCorrelation(MrateMap{iCluster,combo(iCorrs,1)+upCount},MrateMap{iCluster,combo(iCorrs,2)+upCount});   % compute CC
                if isnan(CC); CC = 999999; end
                CCstruct(1,iExp).expNum(iCluster,iCorrs) = CC;
            end
        end
        %% store correlations in repeated fashion to cover all sessions (for nice viewing on spreadsheet)
        CCstruct(1,iExp).expNum(1:(cellCount*seshPerExp),1:size(combo,1)) = repmat(CCstruct(1,iExp).expNum(any(CCstruct(1,iExp).expNum(:,:),2),1:size(combo,1)),seshPerExp,1);
        upCount = upCount + seshPerExp;        % move counter past all sessions to next experiment
        CCstruct(1,iExp).expNum(all(isnan(CCstruct(1,iExp).expNum),2),:) = [];     % remove rows of all nans
        CCoutput(end+1:end+size(CCstruct(1,iExp).expNum,1),:) = CCstruct(1,iExp).expNum;    % collapse all exps onto single sheet
    end
    %% close message box
    if exist('msgCC', 'var')
        delete(msgCC);
        clear('msgCC');
    end
end

%% compute rate difference scores
if include_DS
    %% initialize
    switch seshPerExp
        case 6
            comps = [5,1; 6,2; 3,1; 4,2; 2,1];
        case 4
            comps = [3,1; 4,2; 2,1; 4,3; 4,1; 3,2];
    end
    numExp(1:length(allFolders)/seshPerExp) = {nan(10000,size(comps,1))};
    DSmeanStruct = {struct('expNum',numExp)};
    DSmeanStruct = squeeze(DSmeanStruct{1,1}(1,:));
    DSpeakStruct = {struct('expNum',numExp)};
    DSpeakStruct = squeeze(DSpeakStruct{1,1}(1,:));
    DSmeanOutput = [];
    DSpeakOutput = [];
    upCount = 0;
    
    for iExp = 1:(length(allFolders)/seshPerExp)    % all experiments
        cellCount = totalClusters(iExp*seshPerExp-(seshPerExp-1)); % get number of cells in first session of experiment
        %% calculate all diff scores
        for iCluster = 1:cellCount    % all cells
            for iComps = 1:size(comps,1)       % all session comparisons
                DSmeanStruct(1,iExp).expNum(iCluster,iComps) = ...
                    (MmeanRate(iCluster,comps(iComps,1)+upCount) - MmeanRate(iCluster,comps(iComps,2)+upCount)) / ...
                    (MmeanRate(iCluster,comps(iComps,1)+upCount) + MmeanRate(iCluster,comps(iComps,2)+upCount));
                DSpeakStruct(1,iExp).expNum(iCluster,iComps) = ...
                    (MpeakRate(iCluster,comps(iComps,1)+upCount) - MpeakRate(iCluster,comps(iComps,2)+upCount)) / ...
                    (MpeakRate(iCluster,comps(iComps,1)+upCount) + MpeakRate(iCluster,comps(iComps,2)+upCount));
            end
        end
        %% store scores in repeated fashion to cover all sessions (for nice viewing on spreadsheet)
        DSmeanStruct(1,iExp).expNum(1:(cellCount*seshPerExp),1:size(comps,1)) = repmat(DSmeanStruct(1,iExp).expNum(any(DSmeanStruct(1,iExp).expNum(:,:),2),1:size(comps,1)),seshPerExp,1);
        DSpeakStruct(1,iExp).expNum(1:(cellCount*seshPerExp),1:size(comps,1)) = repmat(DSpeakStruct(1,iExp).expNum(any(DSpeakStruct(1,iExp).expNum(:,:),2),1:size(comps,1)),seshPerExp,1);
        upCount = upCount + seshPerExp;        % move counter past all sessions to next experiment
        DSmeanStruct(1,iExp).expNum(all(isnan(DSmeanStruct(1,iExp).expNum),2),:) = [];     % remove rows of all nans
        DSpeakStruct(1,iExp).expNum(all(isnan(DSpeakStruct(1,iExp).expNum),2),:) = [];     % remove rows of all nans
        DSmeanOutput(end+1:end+size(DSmeanStruct(1,iExp).expNum,1),:) = DSmeanStruct(1,iExp).expNum;    % collapse all exps onto single sheet
        DSpeakOutput(end+1:end+size(DSpeakStruct(1,iExp).expNum,1),:) = DSpeakStruct(1,iExp).expNum;    % collapse all exps onto single sheet
    end
end

%% collapse arrays into single columns and store everything in one cell array
msgExcel = msgbox('Creating Excel output...');
emperor(:,1) = Mfolder(:);
emperor(:,size(emperor,2)+1) = num2cell(Mtetrode(:));
emperor(:,size(emperor,2)+1) = num2cell(Mcluster(:));
emperor(:,size(emperor,2)+1) = num2cell(MmeanRate(:));
emperor(:,size(emperor,2)+1) = num2cell(MpeakRate(:));
emperor(:,size(emperor,2)+1) = num2cell(MtotalSpikes(:));
emperor(:,size(emperor,2)+1) = num2cell(MspikeWidth(:));
emperor(:,size(emperor,2)+1) = num2cell(Mquality(:));
emperor(:,size(emperor,2)+1) = num2cell(Mratio(:));
emperor(:,size(emperor,2)+1) = num2cell(MisolationDist(:));
if include_3Ss
    emperor(:,size(emperor,2)+1) = num2cell(MspatInfo(:));
    emperor(:,size(emperor,2)+1) = num2cell(Mselectivity(:));
    emperor(:,size(emperor,2)+1) = num2cell(Msparsity(:));
end
if include_coherence
    emperor(:,size(emperor,2)+1) = num2cell(Mcoherence(:));
end
if include_fields
    emperor(:,size(emperor,2)+1) = num2cell(MfieldNo(:));
    emperor(:,size(emperor,2)+1) = num2cell(MfieldMean(:));
    emperor(:,size(emperor,2)+1) = num2cell(MfieldMax(:));
    emperor(:,size(emperor,2)+1) = num2cell(MfieldCOMx(:));
    emperor(:,size(emperor,2)+1) = num2cell(MfieldCOMy(:));
    emperor(:,size(emperor,2)+1) = num2cell(Mborder(:));
end
if include_grid
    emperor(:,size(emperor,2)+1) = num2cell(MgridScore(:));
    emperor(:,size(emperor,2)+1) = num2cell(MgridSpacing(:));
    emperor(:,size(emperor,2)+1) = num2cell(MgridOrientation1(:));
    emperor(:,size(emperor,2)+1) = num2cell(MgridOrientation2(:));
    emperor(:,size(emperor,2)+1) = num2cell(MgridOrientation3(:));
end
if include_HD
    emperor(:,size(emperor,2)+1) = num2cell(MvectorLength(:));
    emperor(:,size(emperor,2)+1) = num2cell(MmeanAngle(:));
end
if include_speed 
    emperor(:,size(emperor,2)+1) = num2cell(MspeedScore(:));
end
if include_theta 
    emperor(:,size(emperor,2)+1) = num2cell(MthetaSpikes(:));
    emperor(:,size(emperor,2)+1) = num2cell(MthetaLFP(:));
end
if include_obj
    emperor(:,size(emperor,2)+1) = num2cell(Mobj1(:));
    emperor(:,size(emperor,2)+1) = num2cell(Mobj2(:));
    emperor(:,size(emperor,2)+1) = num2cell(Mobj3(:));
    emperor(:,size(emperor,2)+1) = num2cell(Mobj4(:));
    emperor(:,size(emperor,2)+1) = num2cell(Mobj5(:));
    emperor(:,size(emperor,2)+1) = num2cell(Mobj6(:));
    emperor(:,size(emperor,2)+1) = num2cell(Mobj7(:));
    emperor(:,size(emperor,2)+1) = num2cell(Mobj8(:));
    emperor(:,size(emperor,2)+1) = num2cell(Mobj9(:));
    emperor(:,size(emperor,2)+1) = num2cell(Mobj10(:));
end
if include_CC
    emperor(any(cellfun(@isempty,emperor)'),:) = [];      % remove rows with empties
    emperor(:,(end+1):(end+1)+size(CCoutput,2)-1) = num2cell(CCoutput);     % add CC values to main sheet
    CC_colHeaders = cell(1,size(combo,1));  % make column headers
    for iCorrs = 1:size(combo,1)
        CC_colHeaders{iCorrs} = ['CC ',num2str(combo(iCorrs,1)),' vs ',num2str(combo(iCorrs,2))];
    end
    colHeaders = [colHeaders,CC_colHeaders];   % add CC column headers
end
if include_DS
    % add DS values to main sheet
    emperor(:,(end+1):(end+1)+size(DSmeanOutput,2)-1) = num2cell(DSmeanOutput);
    emperor(:,(end+1):(end+1)+size(DSpeakOutput,2)-1) = num2cell(DSpeakOutput);
    % add column headers
    switch seshPerExp
        case 6
            DS_colHeaders{1} = 'DS Mean 1 vs 5 ';
            DS_colHeaders{2} = 'DS Mean 2 vs 6 ';
            DS_colHeaders{3} = 'DS Mean 1 vs 3 ';
            DS_colHeaders{4} = 'DS Mean 2 vs 4 ';
            DS_colHeaders{5} = 'DS Mean 1 vs 2 ';
            DS_colHeaders{6} = 'DS Peak 1 vs 5 ';
            DS_colHeaders{7} = 'DS Peak 2 vs 6 ';
            DS_colHeaders{8} = 'DS Peak 1 vs 3 ';
            DS_colHeaders{9} = 'DS Peak 2 vs 4 ';
            DS_colHeaders{10} = 'DS Peak 1 vs 2 ';
        case 4
            DS_colHeaders{1} = 'DS Mean 1 vs 3 ';
            DS_colHeaders{2} = 'DS Mean 2 vs 4 ';
            DS_colHeaders{3} = 'DS Mean 1 vs 2 ';
            DS_colHeaders{4} = 'DS Mean 3 vs 4 ';
            DS_colHeaders{5} = 'DS Mean 1 vs 4 ';
            DS_colHeaders{6} = 'DS Mean 2 vs 3 ';
            DS_colHeaders{7} = 'DS Peak 1 vs 3 ';
            DS_colHeaders{8} = 'DS Peak 2 vs 4 ';
            DS_colHeaders{9} = 'DS Peak 1 vs 2 ';
            DS_colHeaders{10} = 'DS Peak 3 vs 4 ';
            DS_colHeaders{11} = 'DS Peak 1 vs 4 ';
            DS_colHeaders{12} = 'DS Peak 2 vs 3 ';
    end
    colHeaders = [colHeaders,DS_colHeaders];
end

%% remove 999999 placeholders
ind = false(1,numel(emperor));
for iCell = 1:numel(emperor)
    if isnumeric(emperor{iCell})
        ind(iCell) = (emperor{iCell} == 999999);
    end
end
emperor(ind) = {nan};

%% add headers and save excel sheet
emperorExcel = [colHeaders; emperor];
xlswrite(fullName,emperorExcel,'Main','A1');

%% add settings in another sheet
settingsNames = {'Cluster format', ...
    'Arena', ...
    'Map limits', ...
    '', ...
    'Spatial info, selectivity, sparsity', ...
    'Coherence', ...
    'Field info, border scores', ...
    'Grids', ...
    'HD', ...
    'Speed', ...
    'Theta', ...
    'Spatial correlations', ...
    'Rate difference scores', ...
    'Objects', ...
    '', ...
    'Num sessions', ...
    '', ...
    'Smoothing', ...
    'Bin width (cm)', ...
    'Minimum occupancy', ...
    '', ...
    'Threshold for including surrounding bins (included if > thresh*peak)', ...
    'Spatial bin width (cm)', ...
    'Minimum bins for a field', ...
    'Minimum peak rate for a field (Hz?)', ...
    '', ...
    'Normalized threshold value used to search for peaks on the autocorrelogram (0:1)', ...
    '', ...
    'Full file path'};
if ~exist('seshPerExp','var')
    seshPerExp = '';
end
if ~exist('fieldThresh','var')
    fieldThresh = '';
end
if ~exist('minBins','var')
    minBins = '';
end
if ~exist('minPeak','var')
    minPeak = '';
end
if ~exist('gridThresh','var')
    gridThresh = '';
end

settingsValues = {clusterFormat, ...
    arena, ...
    num2str(mapLimits), ...
    '', ...
    include_3Ss, ...
    include_coherence, ...
    include_fields, ...
    include_grid, ...
    include_HD, ...
    include_speed, ...
    include_theta, ...
    include_CC, ...
    include_DS, ...
    include_obj, ...
    '', ...
    seshPerExp, ...
    '', ...
    smooth, ...
    binWidth, ...
    minTime, ...
    '', ...
    fieldThresh, ...
    binWidth, ...
    minBins, ...
    minPeak, ...
    '', ...
    gridThresh, ...
    '', ...
    fullName};
emperorSettings = horzcat(settingsNames',settingsValues');
xlswrite(fullName,emperorSettings,'Settings','A1');

%% close message box
if exist('msgExcel', 'var')
    delete(msgExcel);
    clear('msgExcel');
end

toc

load handel
sound(y(1:7000),Fs)
