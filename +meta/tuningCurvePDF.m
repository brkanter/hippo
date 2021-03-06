
% Save PDFs of tuning curves for a given experiment with 4 cells per sheet.
%
%   USAGE
%       meta.tuningCurvePDF
%
%   SEE ALSO
%       penguin meta.rateMapPDF
%
% Written by BRK 2014

function tuningCurvePDF

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
prompt = {'Angle bin width','Percentile'};
name = 'HD settings';
numlines = 1;
defaultanswer = {num2str(hippoGlobe.binWidthHD),'20'};
Answers = inputdlg(prompt,name,numlines,defaultanswer,'on');
if isempty(Answers); return; end;
binWidthHD = str2double(Answers{1});
percentileHD = str2double(Answers{2});

%% session labels
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

%% load data and make rate maps
for iFolder = 1:length(allFolders)
    cd(allFolders{1,iFolder}); 
    writeInputBNT(hippoGlobe.inputFile,allFolders{1,iFolder},hippoGlobe.arena,hippoGlobe.clusterFormat)
    data.loadSessions(hippoGlobe.inputFile);
    %% get positions, spikes, map, and rates
    pos = data.getPositions('average','off','speedFilter',hippoGlobe.posSpeedFilter);
    t = pos(:,1);
    x = pos(:,2);
    y = pos(:,3);
    cellMatrix = data.getCells;
    numClusters = size(cellMatrix,1);
    for iCluster = 1:numClusters          % loop through all cells in folder
        spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
        map = analyses.map([t x y],spikes,'smooth',hippoGlobe.smoothing,'binWidth',hippoGlobe.binWidth,'minTime',0,'limits',hippoGlobe.mapLimits);
        mapMat{iCluster,iFolder} = map.z;
        [~,spkInd] = data.getSpikePositions(spikes,pos);
        try
            spkHDdeg = analyses.calcHeadDirection(pos(spkInd,:));
            allHD = analyses.calcHeadDirection(pos);
            tc = analyses.turningCurve(spkHDdeg,allHD,data.sampleTime);
            tcStat = analyses.tcStatistics(tc,binWidthHD,percentileHD);
        catch 
            tetrodeMat{iCluster,iFolder} = cellMatrix(iCluster,1);
            clusterMat{iCluster,iFolder} = cellMatrix(iCluster,2);
            tcMat{iCluster,iFolder} = nan(1,3);
            vectorLengthMat{iCluster,iFolder} = nan;
            meanAngleMat{iCluster,iFolder} = nan;
            continue
        end
        tetrodeMat{iCluster,iFolder} = cellMatrix(iCluster,1);
        clusterMat{iCluster,iFolder} = cellMatrix(iCluster,2);
        tcMat{iCluster,iFolder} = tc;
        vectorLengthMat{iCluster,iFolder} = tcStat.r;
        meanAngleMat{iCluster,iFolder} = tcStat.mean;
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
                pageHeight = 16;
                pageWidth = 16;
                spCols = 3;
                spRows = 4;
                leftEdge = 1.2;
                rightEdge = 0.4;
                topEdge = 1;
                bottomEdge = 1;
                spaceX = 0.4;
                spaceY = 0.8;
                fontsize = 10;
                sub_pos = subplot_pos(pageWidth,pageHeight,leftEdge,rightEdge,bottomEdge,topEdge,spCols,spRows,spaceX,spaceY);
            case 4       % 4 sessions
                pageHeight = 12;
                pageWidth = 16;
                spCols = 4;
                spRows = 4;
                leftEdge = 1.2;
                rightEdge = 0.4;
                topEdge = 1;
                bottomEdge = 1;
                spaceX = 0;
                spaceY = 0.6;
                fontsize = 10;
                sub_pos = subplot_pos(pageWidth,pageHeight,leftEdge,rightEdge,bottomEdge,topEdge,spCols,spRows,spaceX,spaceY);
            case 5       % 5 sessions
                pageHeight = 12;
                pageWidth = 24;
                spCols = 5;
                spRows = 4;
                leftEdge = 1.2;
                rightEdge = 0.4;
                topEdge = 1;
                bottomEdge = 1;
                spaceX = 0;
                spaceY = 0.6;
                fontsize = 10;
                sub_pos = subplot_pos(pageWidth,pageHeight,leftEdge,rightEdge,bottomEdge,topEdge,spCols,spRows,spaceX,spaceY);
            case 6       % 6 sessions
                pageHeight = 12;
                pageWidth = 24;
                spCols = 6;
                spRows = 4;
                leftEdge = 1.2;
                rightEdge = 0.4;
                topEdge = 1;
                bottomEdge = 1;
                spaceX = 0;
                spaceY = 0.6;
                fontsize = 10;
                sub_pos = subplot_pos(pageWidth,pageHeight,leftEdge,rightEdge,bottomEdge,topEdge,spCols,spRows,spaceX,spaceY);
            case 7       % 7 sessions
                pageHeight = 10;
                pageWidth = 24;
                spCols = 7;
                spRows = 4;
                leftEdge = 1.2;
                rightEdge = 0.4;
                topEdge = 1;
                bottomEdge = 1;
                spaceX = 0;
                spaceY = 0.6;
                fontsize = 10;
                sub_pos = subplot_pos(pageWidth,pageHeight,leftEdge,rightEdge,bottomEdge,topEdge,spCols,spRows,spaceX,spaceY);
        end
        %% set the Matlab figure
        figBatchHD = figure;
        clf(figBatchHD);
        set(gcf,'PaperUnits','centimeters');
        set(gcf,'PaperSize',[pageWidth pageHeight]);
        set(gcf,'PaperPositionMode','manual');
        set(gcf,'PaperPosition',[0 0 pageWidth pageHeight]);
        %% create subplots
        for iPltCluster = 1:spRows           % each cell
            if iPltCluster > 1 || iSheet > 1
                sessionCount = 1;
                if iExp > 1
                    sessionCount = iExp + (numSesh-1);
                end
            end
            %% if we've plotted all the maps already...
            if cellCount > size(mapMat(~cellfun(@isempty,mapMat(:,sessionCount))),1); break; end;
            for iPltSession = 1:spCols           % each session
                axes('position',sub_pos{iPltCluster,iPltSession}); %#ok<LAXES>
                if ~isempty(mapMat{cellCount,sessionCount})    % make sure map exists
                    circularTurningBRK(tcMat{cellCount,sessionCount}(:,2)/max(tcMat{cellCount,sessionCount}(:,2)),'k-','linewidth',3)
                    hold on
                    circularTurningBRK(tcMat{cellCount,sessionCount}(:,3)/max(tcMat{cellCount,sessionCount}(:,3)),'adjustaxis',false,'color',[.5 .5 .5])
                    axis equal
                else
                    cellCount = cellCount + 1;
                end
                %% subplot labels
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
                            set(bottomTitle,'Position',[0,Ylims(2)+(Ylims(2)*0.45)],'VerticalAlignment','bottom','FontSize',9)
                        end
                    case 4
                        if ~isempty(mapMat{cellCount,sessionCount})
                            bottomTitle = title(sprintf('T%dC%d  r = %.4f',tetrodeMat{cellCount,sessionCount},clusterMat{cellCount,sessionCount},vectorLengthMat{cellCount,sessionCount}));
                            set(bottomTitle,'Position',[0,Ylims(2)+(Ylims(2)*0.1)],'VerticalAlignment','bottom','FontSize',9)
                        end
                end
                % add quality
                Q = qualityMat{cellCount,sessionCount};
                if strcmpi(Q,'4')
                    Q = 'off';
                end
                if strcmpi(Q,'3')
                    set(bottomTitle,'color','r')
                elseif strcmpi(Q,'off')
                    set(bottomTitle,'color',[0.5 0.5 0.5])
                end
                %% column labels
                if iPltCluster == 1
                    switch expType
                        case 1      % labels for 1 Env 3 sessions
                            switch iPltSession        % add column labels whose position is determined by current axes limits
                                case 1
                                    text(0,(Ylims(2)*1.35),'BL1','horizontalalignment','center','FontSize',20,'FontWeight','bold')
                                case 2
                                    text(0,(Ylims(2)*1.35),'CNO','horizontalalignment','center','FontSize',20,'FontWeight','bold')
                                case 3
                                    text(0,(Ylims(2)*1.35),'BL2','horizontalalignment','center','FontSize',20,'FontWeight','bold')
                            end
                        case 2       % labels for 1 Env 6 sessions
                            switch iPltSession        % add column labels whose position is determined by current axes limits
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
                            switch iPltSession        % add column labels whose position is determined by current axes limits
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
                            switch iPltSession        % add column labels whose position is determined by current axes limits
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
                            switch iPltSession        % add column labels whose position is determined by current axes limits
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
        %% change figure properties, then save as PDF and close
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


%% close penguin if it's open because BNT data has changed
openPenguin = findobj('name','penguin');
if ~isempty(openPenguin)
    close(openPenguin);
end

