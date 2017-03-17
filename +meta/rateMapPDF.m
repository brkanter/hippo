
% Save PDFs of rate maps for a given experiment with 4 cells per sheet.
%
%   USAGE
%       meta.rateMapPDF
%
%   SEE ALSO
%       penguin meta.tuningCurvePDF
%
% Written by BRK 2014

function rateMapPDF

%% get globals
global hippoGlobe
if isempty(hippoGlobe.inputFile)
    startup
end

%% select folders to analyze and a folder for output
allFolders = uipickfilesBRK();
if ~iscell(allFolders); return; end;
outFolder = uigetdir('','Choose folder for PDF output');
if outFolder == 0; return; end;

%% select settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Mininum occupancy','Publication quality'};
name='Settings';
numlines=1;
defaultanswer={num2str(hippoGlobe.smoothing),num2str(hippoGlobe.binWidth),'0','n'};
options='on';
Answers = inputdlg(prompt,name,numlines,defaultanswer,options);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});
if strcmp('n',Answers{4})
    pubQual = 0;
else
    pubQual = 1;
end

%% rate map scaling
[selections, OK] = listdlg('PromptString','Choose rate map scaling', ...
    'SelectionMode','single',...
    'ListString',{'Autoscale','First session','Session w/max peak', 'As to A and Bs to B'}, ...
    'InitialValue',1, ...
    'ListSize',[200, 100]);
if OK == 0; return; end;
if ismember(1,selections); scaleMethod = 1; end
if ismember(2,selections); scaleMethod = 2; end
if ismember(3,selections); scaleMethod = 3; end
if ismember(4,selections); scaleMethod = 4; end

%% session labels
[selections, OK] = listdlg('PromptString','Choose experiment type', ...
    'SelectionMode','single',...
    'ListString',{'BL1 CNO BL2','BL1 CNO1 CNO2 CNO3 CNO4 BL2','A1 B1 A'' B'' A2 B2','A1 B1 A'' B'' A2 B2 C','A1 B1 A2 B2','A B C D E','BL1 CNO'}, ...
    'InitialValue',1, ...
    'ListSize',[400, 400]);
if OK == 0; return; end;
if ismember(1,selections); expType = 1; end
if ismember(2,selections); expType = 2; end
if ismember(3,selections); expType = 3; end
if ismember(4,selections); expType = 4; end
if ismember(5,selections); expType = 5; end
if ismember(6,selections); expType = 6; end
if ismember(7,selections); expType = 7; end

switch expType
    case 1
        numSesh = 3;
    case {2,3}
        numSesh = 6;
    case 4
        numSesh = 7;
    case 5
        numSesh = 4;
    case 6
        numSesh = 5;
    case 7
        numSesh = 2;
end

%% load data and make rate maps
for iFolder = 1:length(allFolders)    
    cd(allFolders{1,iFolder});   
    writeInputBNT(hippoGlobe.inputFile,allFolders{1,iFolder},hippoGlobe.arena,hippoGlobe.clusterFormat)
    data.loadSessions(hippoGlobe.inputFile);
    %% get positions, spikes, map, and rates
    posAve = data.getPositions('speedFilter',hippoGlobe.posSpeedFilter);
    t = posAve(:,1);
    x = posAve(:,2);
    y = posAve(:,3);
    cellMatrix = data.getCells;
    numClusters = size(cellMatrix,1);    
    for iCluster = 1:numClusters          % loop through all cells in folder
        spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
        map = analyses.map([t x y], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', hippoGlobe.mapLimits);
        meanRate = analyses.meanRate(spikes, posAve);
        mapMat{iCluster,iFolder} = map.z;
        meanMat{iCluster,iFolder} = meanRate;        
        if ~isfield(map,'peakRate')     % rate map was all zeros
            peakMat{iCluster,iFolder} = 0;
        else
            peakMat{iCluster,iFolder} = map.peakRate;
        end        
        tetrodeMat{iCluster,iFolder} = cellMatrix(iCluster,1);
        clusterMat{iCluster,iFolder} = cellMatrix(iCluster,2);
        quality = minions.loadQualityInfo(allFolders{1,iFolder},cellMatrix(iCluster,1),cellMatrix(iCluster,2));
        qualityMat{iCluster,iFolder} = num2str(quality);
    end
end

%% how many sheets needed for each experiment
counter = 1;
numSheets = nan(1,50);
for iSheet = 1:(length(allFolders)/numSesh)    
    %% number of cells with rate maps, divide by 4 to fit 4 cells per sheet
    numSheets(iSheet) = ceil(size(mapMat(~cellfun(@isempty,mapMat(:,counter))),1)/4);
    counter = counter + numSesh;    
end
%% initialize some variables
sessionCount = 1;
pdfName = 1;
%% setup for each experiment
for iExp = 1:(length(allFolders)/numSesh)  % every experiment
    cellCount = 1;
    sheetNumber = 0;    
    for iSheet = 1:numSheets(iExp)   % every sheet for that experiment        
        if iExp > 1            
            pdfName = iExp + (numSesh - 1);            
        end        
        %% get name of folder
        splitFolder = regexp(allFolders{1,pdfName},'\','split');        
        %% set subplot specs
        switch numSesh            
            case 3       % 3 sessions
                plotheight=16;
                plotwidth=16;
                subplotsx=3;
                subplotsy=4;
                leftedge=1.2;
                rightedge=0.4;
                topedge=1;
                bottomedge=1;
                spacex=0.4;
                spacey=0.8;
                fontsize=10;
                sub_pos=subplot_pos(plotwidth,plotheight,leftedge,rightedge,bottomedge,topedge,subplotsx,subplotsy,spacex,spacey);                
            case 4       % 4 sessions
                plotheight=12;
                plotwidth=16;
                subplotsx=4;
                subplotsy=4;
                leftedge=1.2;
                rightedge=0.4;
                topedge=1;
                bottomedge=1;
                spacex=0;
                spacey=0.6;
                fontsize=10;
                sub_pos=subplot_pos(plotwidth,plotheight,leftedge,rightedge,bottomedge,topedge,subplotsx,subplotsy,spacex,spacey);                                        
            case 6       % 6 sessions
                plotheight=12;
                plotwidth=24;
                subplotsx=6;
                subplotsy=4;
                leftedge=1.2;
                rightedge=0.4;
                topedge=1;
                bottomedge=1;
                spacex=0;
                spacey=0.6;
                fontsize=10;
                sub_pos=subplot_pos(plotwidth,plotheight,leftedge,rightedge,bottomedge,topedge,subplotsx,subplotsy,spacex,spacey); 
            case 7       % 7 sessions
                plotheight=10;
                plotwidth=24;
                subplotsx=7;
                subplotsy=4;
                leftedge=1.2;
                rightedge=0.4;
                topedge=1;
                bottomedge=1;
                spacex=0;
                spacey=0.6;
                fontsize=10;
                sub_pos=subplot_pos(plotwidth,plotheight,leftedge,rightedge,bottomedge,topedge,subplotsx,subplotsy,spacex,spacey); 
            case 5       % 5 sessions
                plotheight=12;
                plotwidth=24;
                subplotsx=5;
                subplotsy=4;
                leftedge=1.2;
                rightedge=0.4;
                topedge=1;
                bottomedge=1;
                spacex=0;
                spacey=0.6;
                fontsize=10;
                sub_pos=subplot_pos(plotwidth,plotheight,leftedge,rightedge,bottomedge,topedge,subplotsx,subplotsy,spacex,spacey); 
            case 2       % 2 sessions
                plotheight=16;
                plotwidth=16;
                subplotsx=2;
                subplotsy=4;
                leftedge=1.2;
                rightedge=0.4;
                topedge=1;
                bottomedge=1;
                spacex=0.4;
                spacey=0.8;
                fontsize=10;
                sub_pos=subplot_pos(plotwidth,plotheight,leftedge,rightedge,bottomedge,topedge,subplotsx,subplotsy,spacex,spacey);       
        end
        %% set the Matlab figure
        figBatchRM = figure;
        clf(figBatchRM);
        set(gcf, 'PaperUnits', 'centimeters');
        set(gcf, 'PaperSize', [plotwidth plotheight]);
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperPosition', [0 0 plotwidth plotheight]);        
        %% create subplots
        for iPlotsY = 1:subplotsy           % each cell            
            if iPlotsY > 1 || iSheet > 1                
                sessionCount = 1;                
                if iExp > 1                    
                    sessionCount = iExp + (numSesh-1);                    
                end                
            end            
            %% if we've plotted all the maps already...
            if cellCount > size(mapMat(~cellfun(@isempty,mapMat(:,sessionCount))),1); break; end;            
            for iPlotsX = 1:subplotsx           % each session                
                axes('position',sub_pos{iPlotsX,5-iPlotsY},'XGrid','off','XMinorGrid','off','FontSize',fontsize,'Box','on','Layer','top'); %#ok<LAXES>                
                if ~isempty(mapMat{cellCount,sessionCount})    % make sure map exists                    
                    if scaleMethod == 1     % autoscale each session                                  
                        [scaleBar,~] = colorMapBRK(mapMat{cellCount,sessionCount},'bar','on','pubQual',pubQual);
                    elseif scaleMethod == 2  % scale to peak of first session                        
                        if ~isempty(mapMat{cellCount,sessionCount-(iPlotsX-1)})    % make sure 1st map exists                            
                            prevMax = nanmax(nanmax(mapMat{cellCount,sessionCount-(iPlotsX-1)}));  % find previous max                            
                            if prevMax == 0; prevMax = 0.0001; end;   % make sure prevMax isn't zero                            
                            if nanmin(nanmin(mapMat{cellCount,sessionCount})) > prevMax   % if min is bigger than max, set min to zero                                
                                [scaleBar,~] = colorMapBRK(mapMat{cellCount,sessionCount},'bar','on','pubQual',pubQual,'cutoffs',[0,prevMax]);                                
                            else                                
                                [scaleBar,~] = colorMapBRK(mapMat{cellCount,sessionCount},'bar','on','pubQual',pubQual,'cutoffs',[nanmin(nanmin(mapMat{cellCount,sessionCount})),prevMax]);                                
                            end                            
                        else                            
                            [scaleBar,~] = colorMapBRK(mapMat{cellCount,sessionCount},'bar','on','pubQual',pubQual);   % autoscale cause 1st map doesn't exist                            
                        end                            
                    elseif scaleMethod == 3   % scale to peak of session with highest peak
                        allPeaks = zeros(1,numSesh);    % initialize vector                        
                        for iSession = (numSesh*iExp-(numSesh-1)):(numSesh*iExp)    % all sessions of current experiment                            
                            if ~isempty(mapMat{cellCount,iSession})                                
                                allPeaks(iSession) = nanmax(nanmax(mapMat{cellCount,iSession}));                                
                            end                            
                        end                        
                        maxPeak = nanmax(allPeaks);    % find max peak across all sessions                        
                        if maxPeak == 0; maxPeak = 0.0001; end;   % make sure max isn't zero                        
                        if nanmin(nanmin(mapMat{cellCount,sessionCount})) > maxPeak   % if min is bigger than max, set min to zero                            
                            [scaleBar,~] = colorMapBRK(mapMat{cellCount,sessionCount},'bar','on','pubQual',pubQual,'cutoffs',[0,maxPeak]);                            
                        else                            
                            [scaleBar,~] = colorMapBRK(mapMat{cellCount,sessionCount},'bar','on','pubQual',pubQual,'cutoffs',[nanmin(nanmin(mapMat{cellCount,sessionCount})),maxPeak]);                            
                        end                        
                    elseif scaleMethod == 4    % scale to peak As to A and Bs to B                        
                        switch iPlotsX                            
                            case {1,2}                                
                                [scaleBar,~] = colorMapBRK(mapMat{cellCount,sessionCount},'bar','on','pubQual',pubQual);  % autoscale                                
                            case {3,4}                                
                                if ~isempty(mapMat{cellCount,sessionCount-2})    % make sure old map exists                                    
                                    prevMax = nanmax(nanmax(mapMat{cellCount,sessionCount-2}));   % scale to 2 sessions ago                                    
                                    if prevMax == 0; prevMax = 0.0001; end; % make sure max isn't zero                                    
                                    if nanmin(nanmin(mapMat{cellCount,sessionCount})) > prevMax   % if min is bigger than max, set min to zero                                        
                                        [scaleBar,~] = colorMapBRK(mapMat{cellCount,sessionCount},'bar','on','pubQual',pubQual,'cutoffs',[0,prevMax]);                                        
                                    else                                        
                                        [scaleBar,~] = colorMapBRK(mapMat{cellCount,sessionCount},'bar','on','pubQual',pubQual,'cutoffs',[nanmin(nanmin(mapMat{cellCount,sessionCount})),prevMax]);                                        
                                    end                                    
                                else                                    
                                    [scaleBar,~] = colorMapBRK(mapMat{cellCount,sessionCount},'bar','on','pubQual',pubQual);   % autoscale cause old map doesn't exist                                    
                                end                                    
                            case {5,6}                                                                    
                                if ~isempty(mapMat{cellCount,sessionCount-4})    % make sure old map exists                                    
                                    prevMax = nanmax(nanmax(mapMat{cellCount,sessionCount-4}));   % scale to 4 sessions ago                                    
                                    if prevMax == 0; prevMax = 0.0001; end;  % make sure max isn't zero                                    
                                    if nanmin(nanmin(mapMat{cellCount,sessionCount})) > prevMax    % if min is bigger than max, set min to zero                                        
                                        [scaleBar,~] = colorMapBRK(mapMat{cellCount,sessionCount},'bar','on','pubQual',pubQual,'cutoffs',[0,prevMax]);                                        
                                    else                                        
                                        [scaleBar,~] = colorMapBRK(mapMat{cellCount,sessionCount},'bar','on','pubQual',pubQual,'cutoffs',[nanmin(nanmin(mapMat{cellCount,sessionCount})),prevMax]);                                        
                                    end                                    
                                else                                    
                                    [scaleBar,~] = colorMapBRK(mapMat{cellCount,sessionCount},'bar','on','pubQual',pubQual);   % autoscale cause old map doesn't exist                                    
                                end                               
                        end                        
                    end                
                else                    
                    cellCount = cellCount + 1;                    
                end                
                %% subplot labels
                axis off                
                Xlims = get(gca,'xlim');
                Ylims = get(gca,'ylim');                
                switch expType                    
                    case {1,7}
                        if ~isempty(mapMat{cellCount,sessionCount})
                            Q = qualityMat{cellCount,sessionCount};
                            if strcmpi(Q,'4')
                                Q = 'off';
                            end
                            bottomTitle = title(sprintf('T%dC%d  Q%s  m=%.2f',tetrodeMat{cellCount,sessionCount},clusterMat{cellCount,sessionCount},Q,meanMat{cellCount,sessionCount}));
                            set(bottomTitle,'Position',[(Xlims(2)-Xlims(1))/1.87,(Ylims(2)-Ylims(1))+7.5],'VerticalAlignment','bottom','FontSize',9)
                            if strcmpi(Q,'3')
                                set(bottomTitle,'color','r')
                            elseif strcmpi(Q,'off')
                                set(bottomTitle,'color','b')
                            end
                            try
                                set(scaleBar,'FontSize',8)
                            end
                        end
                    case {2,3,5,6}
                        if ~isempty(mapMat{cellCount,sessionCount})
                            bottomTitle = title(sprintf('T%dC%d  [%.2f]  [%.2f]',tetrodeMat{cellCount,sessionCount},clusterMat{cellCount,sessionCount},meanMat{cellCount,sessionCount},peakMat{cellCount,sessionCount}));
                            set(bottomTitle,'Position',[(Xlims(2)-Xlims(1))/1.87,(Ylims(2)-Ylims(1))/0.85],'VerticalAlignment','bottom','FontSize',9)
                            set(scaleBar,'FontSize',9)
                        end
                    case 4
                        if ~isempty(mapMat{cellCount,sessionCount})
                            bottomTitle = title(sprintf('T%dC%d  [%.2f]  [%.2f]',tetrodeMat{cellCount,sessionCount},clusterMat{cellCount,sessionCount},meanMat{cellCount,sessionCount},peakMat{cellCount,sessionCount}));
                            set(bottomTitle,'Position',[(Xlims(2)-Xlims(1))/1.87,(Ylims(2)-Ylims(1))/-2.5],'VerticalAlignment','bottom','FontSize',8)
                            set(scaleBar,'FontSize',8)
                        end
                end
                %% column labels
                if iPlotsY == 1                    
                    switch expType                        
                        case 1      % labels for 1 Env 3 sessions                            
                            switch iPlotsX        % add column labels whose position is determined by current axes limits                                
                                case 1                                    
                                    text((Xlims(2)-Xlims(1))/3.5,(Ylims(1))-5,'BL1','FontSize',20,'FontWeight','bold')                                    
                                case 2                                    
                                    text((Xlims(2)-Xlims(1))/4,(Ylims(1))-5,'CNO','FontSize',20,'FontWeight','bold')                                    
                                case 3                                    
                                    text((Xlims(2)-Xlims(1))/3.5,(Ylims(1))-5,'BL2','FontSize',20,'FontWeight','bold')                                    
                            end                            
                        case 2       % labels for 1 Env 6 sessions                            
                            switch iPlotsX        % add column labels whose position is determined by current axes limits                                
                                case 1                                    
                                    text(13,77,'BL1','FontSize',20,'FontWeight','bold')                                    
                                case 2                                    
                                    text(8,77,'CNO1','FontSize',20,'FontWeight','bold')                                    
                                case 3                                    
                                    text(8,77,'CNO2','FontSize',20,'FontWeight','bold')                                    
                                case 4                                    
                                    text(8,77,'CNO3','FontSize',20,'FontWeight','bold')                                    
                                case 5                                    
                                    text(8,77,'CNO4','FontSize',20,'FontWeight','bold')                                    
                                case 6                                    
                                    text(13,77,'BL2','FontSize',20,'FontWeight','bold')                                    
                            end                            
                        case 3     % labels for 2 Env 6 sessions                            
                            switch iPlotsX        % add column labels whose position is determined by current axes limits                                
                                case 1                                    
                                    text((Xlims(2)-Xlims(1))/4,(Ylims(2)-Ylims(1))/0.78,'A1','FontSize',26,'FontWeight','bold')                                    
                                case 2                                    
                                    text((Xlims(2)-Xlims(1))/4,(Ylims(2)-Ylims(1))/0.78,'B1','FontSize',26,'FontWeight','bold')                                    
                                case 3                                    
                                    text((Xlims(2)-Xlims(1))/3.53,(Ylims(2)-Ylims(1))/0.78,'A''','FontSize',26,'FontWeight','bold')                                    
                                case 4                                    
                                    text((Xlims(2)-Xlims(1))/3.53,(Ylims(2)-Ylims(1))/0.78,'B''','FontSize',26,'FontWeight','bold')                                    
                                case 5                                    
                                    text((Xlims(2)-Xlims(1))/4,(Ylims(2)-Ylims(1))/0.78,'A2','FontSize',26,'FontWeight','bold')                                    
                                case 6                                    
                                    text((Xlims(2)-Xlims(1))/4,(Ylims(2)-Ylims(1))/0.78,'B2','FontSize',26,'FontWeight','bold')                                    
                            end
                        case 4     % labels for 3 Env 7 sessions
                            switch iPlotsX        % add column labels whose position is determined by current axes limits
                                case 1
                                    text((Xlims(2)-Xlims(1))/4.5,(Ylims(2)-Ylims(1))/0.78,'A1','FontSize',26,'FontWeight','bold')
                                case 2
                                    text((Xlims(2)-Xlims(1))/4.5,(Ylims(2)-Ylims(1))/0.78,'B1','FontSize',26,'FontWeight','bold')
                                case 3
                                    text((Xlims(2)-Xlims(1))/3.53,(Ylims(2)-Ylims(1))/0.78,'A''','FontSize',26,'FontWeight','bold')
                                case 4
                                    text((Xlims(2)-Xlims(1))/3.53,(Ylims(2)-Ylims(1))/0.78,'B''','FontSize',26,'FontWeight','bold')
                                case 5
                                    text((Xlims(2)-Xlims(1))/4.5,(Ylims(2)-Ylims(1))/0.78,'A2','FontSize',26,'FontWeight','bold')
                                case 6
                                    text((Xlims(2)-Xlims(1))/4.5,(Ylims(2)-Ylims(1))/0.78,'B2','FontSize',26,'FontWeight','bold')
                                case 7
                                    text((Xlims(2)-Xlims(1))/3.53,(Ylims(2)-Ylims(1))/0.78,'C','FontSize',26,'FontWeight','bold')
                            end
                        case 5     % labels for 2 Env 4 sessions
                            switch iPlotsX        % add column labels whose position is determined by current axes limits
                                case 1                                    
                                    text((Xlims(2)-Xlims(1))/4,(Ylims(2)-Ylims(1))/0.78,'A1','FontSize',26,'FontWeight','bold')                                    
                                case 2                                    
                                    text((Xlims(2)-Xlims(1))/4,(Ylims(2)-Ylims(1))/0.78,'B1','FontSize',26,'FontWeight','bold')                                    
                                case 3                                   
                                    text((Xlims(2)-Xlims(1))/3.53,(Ylims(2)-Ylims(1))/0.78,'A2','FontSize',26,'FontWeight','bold')                                    
                                case 4                                    
                                    text((Xlims(2)-Xlims(1))/3.53,(Ylims(2)-Ylims(1))/0.78,'B2','FontSize',26,'FontWeight','bold')                                                                       
                            end   
                        case 6     % labels for 1 Env 5 sessions
                            switch iPlotsX        % add column labels whose position is determined by current axes limits
                                case 1
                                    text((Xlims(2)-Xlims(1))/4,(Ylims(2)-Ylims(1))/-5,'A','FontSize',26,'FontWeight','bold')
                                case 2
                                    text((Xlims(2)-Xlims(1))/4,(Ylims(2)-Ylims(1))/-5,'B','FontSize',26,'FontWeight','bold')
                                case 3
                                    text((Xlims(2)-Xlims(1))/3.53,(Ylims(2)-Ylims(1))/-5,'C','FontSize',26,'FontWeight','bold')
                                case 4
                                    text((Xlims(2)-Xlims(1))/3.53,(Ylims(2)-Ylims(1))/-5,'D','FontSize',26,'FontWeight','bold')
                                case 5
                                    text((Xlims(2)-Xlims(1))/3.53,(Ylims(2)-Ylims(1))/-5,'E','FontSize',26,'FontWeight','bold')
                            end
                        case 7      % labels for 1 Env 3 sessions
                            switch iPlotsX        % add column labels whose position is determined by current axes limits                                
                                case 1                                    
                                    text((Xlims(2)-Xlims(1))/3.5,(Ylims(1))-5,'BL1','FontSize',20,'FontWeight','bold')                                    
                                case 2                                    
                                    text((Xlims(2)-Xlims(1))/4,(Ylims(1))-5,'CNO','FontSize',20,'FontWeight','bold')                                                                   
                            end  
                    end                    
                end                                
                sessionCount = sessionCount + 1;                
            end            
            cellCount = cellCount + 1;            
        end        
        %% change figure properties, then save as PDF and close
        set(figBatchRM,'Color','w','Position', get(0,'Screensize'));
        sheetNumber = sheetNumber + 1;        
        switch numSesh            
            case {2,3}                
                if scaleMethod == 1                    
                    saveas(figBatchRM,sprintf('%s\\auto_%s[%d].pdf',outFolder,splitFolder{end},sheetNumber));                    
                elseif scaleMethod == 2                    
                    saveas(figBatchRM,sprintf('%s\\peak1_%s[%d].pdf',outFolder,splitFolder{end},sheetNumber));                    
                elseif scaleMethod == 3                    
                    saveas(figBatchRM,sprintf('%s\\maxPeak_%s[%d].pdf',outFolder,splitFolder{end},sheetNumber));                    
                end                
            otherwise                
                saveas(figBatchRM,sprintf('%s\\rateMaps_%s[%d].pdf',outFolder,splitFolder{end-1},sheetNumber));                
        end        
        close(figBatchRM);        
    end    
    sessionCount = sessionCount + numSesh;    
end



