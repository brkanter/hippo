
% rateMapPDF: make PDFs of rate maps, where each sheet has all recording sessions for a given cell.
%
% 1. Requires proper installation of BNT (contact V. Frolov) and modified BNT files by BRK.
% 2. Use ctrl+F 'C:' to locate machine-specific directories and modify appropriately.
%
% Written by BRK 2014 based on Behavioral Neurology Toolbox (V. Frolov 2013).


function tuningCurvePDF(inputFileID,clusterFormat)

%%% input arguments
global penguinInput arena
if isempty(penguinInput)
    startup
end
if ~exist('inputFileID','var')
    inputFileID = penguinInput;
end
if ~exist('clusterFormat','var')
    clusterFormat = 'MClust'; 
end

%%% select folders to analyze and a folder for output
allFolders = uipickfilesBRK();
if ~iscell(allFolders); return; end;
outFolder = uigetdir('','Choose folder for PDF output');
if outFolder == 0; return; end;

%%% session labels
[selections, OK] = listdlg('PromptString','Choose experiment type', ...
    'SelectionMode','single',...
    'ListString',{'BL1 CNO BL2','BL1 CNO1 CNO2 CNO3 CNO4 BL2','A1 B1 A'' B'' A2 B2','A1 B1 A'' B'' A2 B2 C','A1 B1 A2 B2','A B C D E'}, ...
    'InitialValue',1, ...
    'ListSize',[400, 400]);
if OK == 0; return; end;
if ismember(1,selections); expType = 1; end
if ismember(2,selections); expType = 2; end
if ismember(3,selections); expType = 3; end
if ismember(4,selections); expType = 4; end
if ismember(5,selections); expType = 5; end
if ismember(6,selections); expType = 6; end

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
end

%%% load data and make rate maps
for iFolder = 1:length(allFolders)
    cd(allFolders{1,iFolder}); 
    writeInputBNT(inputFileID,allFolders{1,iFolder},arena,clusterFormat)
    loadSessionsBRK(inputFileID,clusterFormat);
    %%% get positions, spikes, map, and rates
    pos = data.getPositions('average','off','speedFilter',[0.2 0]);
    t = pos(:,1);
    x = pos(:,2);
    y = pos(:,3);
    cellMatrix = data.getCells;
    numClusters = size(cellMatrix,1);
    for iCluster = 1:numClusters          % loop through all cells in folder
        spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
        map = analyses.map([t x y], spikes, 'smooth', 2, 'binWidth', 4, 'minTime', 0);
        mapMat{iCluster,iFolder} = map.z;
        [~,spkInd] = data.getSpikePositions(spikes,pos);
        try
            spkHDdeg = analyses.calcHeadDirection(pos(spkInd,:));
            allHD = analyses.calcHeadDirection(pos);
            tc = analyses.turningCurve(spkHDdeg, allHD, data.sampleTime);
            tcStat = analyses.tcStatistics(tc, 6, 20);
        catch 
            tetrodeMat{iCluster,iFolder} = cellMatrix(iCluster,1);
            clusterMat{iCluster,iFolder} = cellMatrix(iCluster,2);
            tcMat{iCluster,iFolder} = nan;
            vectorLengthMat{iCluster,iFolder} = nan;
            meanAngleMat{iCluster,iFolder} = nan;
            continue
        end
        tetrodeMat{iCluster,iFolder} = cellMatrix(iCluster,1);
        clusterMat{iCluster,iFolder} = cellMatrix(iCluster,2);
        tcMat{iCluster,iFolder} = tc;
        vectorLengthMat{iCluster,iFolder} = tcStat.r;
        meanAngleMat{iCluster,iFolder} = tcStat.mean;
    end
end

% save('C:\Users\Kentros Lab\Desktop\hd.mat')
% load('C:\Users\Kentros Lab\Desktop\hd.mat')

%%% how many sheets needed for each experiment
counter = 1;
numSheets = nan(1,50);
for iSheet = 1:(length(allFolders)/numSesh)
    %%% number of cells with rate maps, divide by 4 to fit 4 cells per sheet
    numSheets(iSheet) = ceil(size(mapMat(~cellfun(@isempty,mapMat(:,counter))),1)/4);
    counter = counter + numSesh;
end
%%% initialize some variables
sessionCount = 1;
pdfName = 1;
%%% setup for each experiment
for iExp = 1:(length(allFolders)/numSesh)  % every experiment
    cellCount = 1;
    sheetNumber = 0;
    for iSheet = 1:numSheets(iExp)   % every sheet for that experiment
        if iExp > 1
            pdfName = iExp + (numSesh - 1);
        end
        %%% get name of folder
        splitFolder = regexp(allFolders{1,pdfName},'\','split');
        %%% set subplot specs
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
        end
        %%% set the Matlab figure
        figBatchHD = figure;
        clf(figBatchHD);
        set(gcf, 'PaperUnits', 'centimeters');
        set(gcf, 'PaperSize', [plotwidth plotheight]);
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperPosition', [0 0 plotwidth plotheight]);
        %%% create subplots
        for iPlotsY = 1:subplotsy           % each cell
            if iPlotsY > 1 || iSheet > 1
                sessionCount = 1;
                if iExp > 1
                    sessionCount = iExp + (numSesh-1);
                end
            end
            %%% if we've plotted all the maps already...
            if cellCount > size(mapMat(~cellfun(@isempty,mapMat(:,sessionCount))),1); break; end;
            for iPlotsX = 1:subplotsx           % each session
                axes('position',sub_pos{iPlotsX,5-iPlotsY},'XGrid','off','XMinorGrid','off','FontSize',fontsize,'Box','on','Layer','top'); %#ok<LAXES>
                if ~isempty(mapMat{cellCount,sessionCount})    % make sure map exists
                    circularTurningBRK(tcMat{cellCount,sessionCount}(:,2))
                    axis equal
                else
                    cellCount = cellCount + 1;
                end
                %%% subplot labels
                axis off
                Xlims = get(gca,'xlim');
                Ylims = get(gca,'ylim');
                switch expType
                    case 1
                        if ~isempty(mapMat{cellCount,sessionCount})
                            bottomTitle = title(sprintf('T%dC%d  r = %.2f',tetrodeMat{cellCount,sessionCount},clusterMat{cellCount,sessionCount},vectorLengthMat{cellCount,sessionCount}));
                            set(bottomTitle,'Position',[0,Ylims(2)+(Ylims(2)*0.1)],'VerticalAlignment','bottom','FontSize',9)
                        end
                    case {2,3,5,6}
                        if ~isempty(mapMat{cellCount,sessionCount})
                            bottomTitle = title(sprintf('T%dC%d  r = %.4f',tetrodeMat{cellCount,sessionCount},clusterMat{cellCount,sessionCount},vectorLengthMat{cellCount,sessionCount}));
                            set(bottomTitle,'Position',[0,Ylims(2)+(Ylims(2)*0.1)],'VerticalAlignment','bottom','FontSize',9)
                        end
                    case 4
                        if ~isempty(mapMat{cellCount,sessionCount})
                            bottomTitle = title(sprintf('T%dC%d  r = %.4f',tetrodeMat{cellCount,sessionCount},clusterMat{cellCount,sessionCount},vectorLengthMat{cellCount,sessionCount}));
                            set(bottomTitle,'Position',[0,Ylims(2)+(Ylims(2)*0.1)],'VerticalAlignment','bottom','FontSize',9)
                        end
                end
                %%% column labels
                if iPlotsY == 1
                    switch expType
                        case 1      % labels for 1 Env 3 sessions
                            switch iPlotsX        % add column labels whose position is determined by current axes limits
                                case 1
                                    text(0,(Ylims(2)*1.35),'BL1','horizontalalignment','center','FontSize',20,'FontWeight','bold')
                                case 2
                                    text(0,(Ylims(2)*1.35),'CNO','horizontalalignment','center','FontSize',20,'FontWeight','bold')
                                case 3
                                    text(0,(Ylims(2)*1.35),'BL2','horizontalalignment','center','FontSize',20,'FontWeight','bold')
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
                    end
                end
                sessionCount = sessionCount + 1;
            end
            cellCount = cellCount + 1;
        end
        %%% change figure properties, then save as PDF and close
        set(figBatchHD,'Color','w','Position', get(0,'Screensize'));
        sheetNumber = sheetNumber + 1;
        switch numSesh
            case 3
                saveas(figBatchHD,sprintf('%s\\tuningCurves_%s[%d].pdf',outFolder,splitFolder{end},sheetNumber));
            otherwise
                saveas(figBatchHD,sprintf('%s\\tuningCurves_%s[%d].pdf',outFolder,splitFolder{end-1},sheetNumber));
        end
        close(figBatchHD);
    end
    sessionCount = sessionCount + numSesh;
end



