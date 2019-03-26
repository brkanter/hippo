
% penguin: GUI for neurobiological analysis of spatial behavior.
%
% Written by BRK 2014

function varargout = penguin(varargin)
% PENGUIN MATLAB code for penguin.fig
%      PENGUIN, by itself, creates a new PENGUIN or raises the existing
%      singleton*.
%
%      H = PENGUIN returns the handle to a new PENGUIN or the handle to
%      the existing singleton*.
%
%      PENGUIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PENGUIN.M with the given input arguments.
%
%      PENGUIN('Property','Value',...) creates a new PENGUIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the PENGUIN before penguin_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to penguin_OpeningFcn via varargin.
%
%      *See PENGUIN Options on GUIDE's Tools menu.  Choose "PENGUIN allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help penguin

% Last Modified by GUIDE v2.5 27-Feb-2019 17:03:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @penguin_OpeningFcn, ...
    'gui_OutputFcn',  @penguin_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before penguin is made visible.
function penguin_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to penguin (see VARARGIN)

% Choose default command line output for penguin
% global penguinInput arena mapLimits dSmoothing dBinWidth dMinBins clusterFormat
% if isempty(penguinInput)
%     startup
% end
handles.output = hObject; % HELLO
handles.switchRats = 0;
set(handles.butt_switchRats,'backgroundcolor',[.8 .8 .8],'String','Red/Green rat')

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes penguin wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = penguin_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in butt_video.
function butt_video_Callback(hObject, eventdata, handles) %#ok<*INUSL,*DEFNU>
% hObject    handle to butt_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% initiliaze
global hippoGlobe
fNames = fieldnames(hippoGlobe);
for iField = 1:length(fNames)
   eval(sprintf('handles.%s = hippoGlobe.%s;',fNames{iField},fNames{iField}));
end

%% choose directory of behavioral session
handles.userDir = '';
handles.userDir = uigetdir('E:\HM3_CA3\Screening','Choose directory');
h = msgbox('Loading...');
set(handles.text_video, 'String', handles.userDir);
if handles.userDir == 0; close(h); return; end;

%% choose session within a folder for Tint cluster format
if strcmpi(handles.clusterFormat,'Tint')
    prompt={'If you have more than one session in that folder, enter the session name'};
    name='';
    numlines=1;
    defaultanswer={'10051302'};
    sessionName = inputdlg(prompt,name,numlines,defaultanswer,'on');
else
    sessionName = '';
end

%% load all data for designated session
try
    
    writeInputBNT(handles.inputFile,handles.userDir,handles.arena,handles.clusterFormat,sessionName)
    
% if there aren't any clusters, just plot the animal's path    
catch caughtErr
    
    if strcmpi(caughtErr.message,'Did not find any clusters.')
        
        % plot path
        warning('Did not find clusters, loading raw position data just to check animal''s exploration.')
        [x y] = io.neuralynx.Nlx2MatVT(fullfile(handles.userDir,'VT1.nvt'),[0 1 1 0 0],0,1);
        [x y] = general.removePosJumps(x,y,6,2.5); % default BNT values
        axes(handles.axes1);
        plot(x,y,'color',[0.5 0.5 0.5])
        set(gca,'color',[.8 .8 .8],'xcolor',[.8 .8 .8],'ycolor',[.8 .8 .8],'box','off','buttondownfcn',@axes1_ButtonDownFcn)
        axis equal
        
        % clear penguin text fields
        set(handles.list_tetrode,'String','');
        set(handles.text_tetrode,'String','');
        set(handles.list_cluster,'String','');
        set(handles.text_cluster,'String','');
        set(handles.text_meanRate,'String','');
        set(handles.text_peakRate,'String','');
        set(handles.text_totalSpikes,'String','');
        set(handles.text_spikeWidth,'String','');
        set(handles.text_spatContent,'String','');
        set(handles.text_sparsity,'String','');
        set(handles.text_selectivity,'String','');
        set(handles.text_coherence,'String','');
        set(handles.text_fieldNo,'String','');
        set(handles.text_fieldMean,'String','');
        set(handles.text_fieldMax,'String','');
        
        close(h);
        return
        
    else
        rethrow(caughtErr)
    end
    
end

data.loadSessions(handles.inputFile);

if isfield(hippoGlobe,'cameraLimits') && ~isempty(hippoGlobe.cameraLimits)
    minions.cameraLims(handles.userDir)
end

try
    posAve = data.getPositions('speedFilter',handles.posSpeedFilter);
    handles.gotPos = 1;
catch
    warndlg('Error getting position samples')
    handles.gotPos = 0;
end
if handles.gotPos
    if handles.switchRats % blue rat!
%         pos = data.getPositions('speedFilter',handles.posSpeedFilter,'mode','all','scale','off','average','off');
%         [includeRed includeGreen] = switchRatMask(handles.userDir,pos,1);
%         pos = pos(includeRed,:);
%         [cleanX,cleanY] = removePosJumpsTD(pos(:,2),pos(:,3),25);
%         cleanX = minions.rescaleData(cleanX,handles.mapLimits(1),handles.mapLimits(2));
%         cleanY = minions.rescaleData(cleanY,handles.mapLimits(3),handles.mapLimits(4));
%         handles.pos = [pos(:,1),cleanX,cleanY];
%         handles.posX = cleanX;
%         handles.posY = cleanY;
        
        %% get blue positions
        try
            posAve = blues(fullfile(handles.userDir,'VT1.nvt'),handles);
        catch
            if handles.switchRats
                handles.switchRats = 0;
                set(hObject,'value',0,'backgroundColor',[.8 .8 .8],'foregroundcolor','k','string','Red/green rat')
            else
                handles.switchRats = 1;
                set(hObject,'value',1,'backgroundColor','b','foregroundcolor','w','string','Blue rat')
            end
            msgbox('Failed to find blue LED.');
            return
        end
        handles.posAve = posAve;
        handles.posT = posAve(:,1);
        handles.posX = posAve(:,2);
        handles.posY = posAve(:,3);
        handles.spikePos = [];
        
    else % normal red green inside rat
        handles.posAve = posAve;
        handles.posT = posAve(:,1);
        handles.posX = posAve(:,2);
        handles.posY = posAve(:,3);
        handles.spikePos = [];
    end
end
% head direction position data
if ~handles.switchRats % red/green
    try
        pos = data.getPositions('average','off','speedFilter',handles.posSpeedFilter);
        pos(:,2) = minions.rescaleData(pos(:,2),handles.mapLimits(1),handles.mapLimits(2));
        pos(:,3) = minions.rescaleData(pos(:,3),handles.mapLimits(3),handles.mapLimits(4));
        pos(:,4) = minions.rescaleData(pos(:,4),handles.mapLimits(1),handles.mapLimits(2));
        pos(:,5) = minions.rescaleData(pos(:,5),handles.mapLimits(3),handles.mapLimits(4));
        handles.pos = pos;
        handles.gotPosHD = 1;
    catch
        handles.gotPosHD = 0;
    end
else % blue
    handles.pos = [];
    handles.gotPosHD = 0;
end

handles = loadData(handles);
cellMatrix = data.getCells;
handles.cellMatrix = sortrows(cellMatrix,[1 2]);

close(h);
guidata(hObject,handles);

function handles = loadData(handles)

    %% UPDATE EVERYTHING
    %% update tetrode based on current folder
    current_tetCells = data.getCells;
    handles.current_tetCells = current_tetCells;
    trode_nums = num2str(unique(current_tetCells(:, 1)));
    current_trodes = cellstr(trode_nums);
    handles.current_trodes = current_trodes;
    set(handles.list_tetrode,'String',current_trodes,'Value',1);
    contents = get(handles.list_tetrode,'String');
    selectedText = contents{get(handles.list_tetrode,'Value')};
    handles.tetrode = str2double(selectedText);
    set(handles.text_tetrode, 'String', handles.tetrode);

    %% update cluster based on current tetrode
    clust_indices = current_tetCells(:,1)==handles.tetrode;
    current_clusters = sort(cellstr(num2str(current_tetCells(clust_indices,2))));
    set(handles.list_cluster,'String',current_clusters,'Value',1);
    contents = get(handles.list_cluster,'String');
    selectedText = contents{get(handles.list_cluster,'Value')};
    handles.cluster = str2double(selectedText);
    set(handles.text_cluster, 'String', handles.cluster);

    %% initialize
    handles.meanRate = 0;
    handles.peakRate = 0;
    handles.totalSpikes = 0;
    handles.spikeWidth = 0;
    handles.marker = 15;

    %% plot animal path
    if handles.gotPos
        axes(handles.axes1);
        hSPP = plot(handles.posAve(:,2),handles.posAve(:,3),'color',[.5 .5 .5]); 
        set(hSPP,'hittest','off') 
        set(gca,'ydir','reverse')
        set(gca,'color',[.8 .8 .8],'xcolor',[.8 .8 .8],'ycolor',[.8 .8 .8],'box','off','buttondownfcn',@axes1_ButtonDownFcn)
        axis equal
    end

    %% get spike info
    handles.spikes = data.getSpikeTimes([handles.tetrode handles.cluster]);
    if handles.gotPos
        handles.spikePos = data.getSpikePositions(handles.spikes,handles.posAve);
    end

    if handles.gotPos
        %% calculate rate map
        map = analyses.map([handles.posT handles.posX handles.posY], handles.spikes, 'smooth', handles.smoothing, 'binWidth', handles.binWidth, 'minTime', 0, 'limits', handles.mapLimits);
        handles.map = map.z;

        %% calculate mean rate in Hz
        handles.meanRate = analyses.meanRate(handles.spikes, handles.posAve);
        set(handles.text_meanRate, 'String', handles.meanRate);

        %% calculate peak rate in Hz
        if ~isfield(map,'peakRate')
            handles.peakRate = 0;
        else
            handles.peakRate = map.peakRate;
        end
        set(handles.text_peakRate, 'String', handles.peakRate);
    end

    %% calculate total spikes
    handles.totalSpikes = length(handles.spikes);
    set(handles.text_totalSpikes, 'String', handles.totalSpikes);

    %% calculate spike width
    try
        handles.spikeWidth = calc.halfMaxWidth(handles.userDir, handles.tetrode, handles.spikes);
        set(handles.text_spikeWidth, 'String', round(handles.spikeWidth));
    catch
        set(handles.text_spikeWidth, 'String', 0);
    end

    %% clear map stats
    set(handles.text_spatContent, 'String', '');
    set(handles.text_sparsity, 'String', '');
    set(handles.text_selectivity, 'String', '');
    set(handles.text_coherence, 'String', '');
    set(handles.text_fieldNo, 'String', '');
    set(handles.text_fieldMean, 'String', '');
    set(handles.text_fieldMax, 'String', '');

% --- Executes on button press in butt_load_mclust.
function butt_load_mclust_Callback(hObject, eventdata, handles)
% hObject    handle to butt_load_mclust (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% initiliaze
global hippoGlobe
fNames = fieldnames(hippoGlobe);
for iField = 1:length(fNames)
   eval(sprintf('handles.%s = hippoGlobe.%s;',fNames{iField},fNames{iField}));
end

isMClustActive = true;
try
    clustData = MClust.GetData;
catch
    isMClustActive = false;
end

if ~isMClustActive
    uiwait(errordlg('MClust is not active', 'Error', 'modal'));
    return;
end

% check number of available clusters
if isempty(clustData.Clusters)
    uiwait(errordlg('There are no clusters in MClust', 'Error', 'modal'));
    return;
end

h = msgbox('Loading...', 'modal');
TTdn = clustData.TTdn;
set(handles.text_video, 'String', 'MClust');
handles.userDir = TTdn;

% let's dump clusters into a temp directory. This is done in order not to
% overwrite any of user's clusters
clusterDir = tempname;
mkdir(clusterDir);
clear posAve;
try
    clustData.TTdn = clusterDir;
    clustData.WriteTfiles;
    writeInputBNT(handles.inputFile, TTdn, handles.arena, handles.clusterFormat, [], clusterDir);
    data.loadSessions(handles.inputFile);
    
    if isfield(hippoGlobe,'cameraLimits') && ~isempty(hippoGlobe.cameraLimits)
        minions.cameraLims(handles.userDir)
    end
    
    try
        posAve = data.getPositions('speedFilter',handles.posSpeedFilter);
        handles.gotPos = 1;
    catch
        warndlg('Error getting position samples')
        handles.gotPos = 0;
    end
    helpers.deleteCache(handles.inputFile);
catch
    rmdir(clusterDir);
    handles.gotPos = 0;
    clustData.TTdn = TTdn;
    close(h);
    uiwait(errordlg('Failed to load clusters from MClust', 'Error', 'modal'));
    return;
end
rmdir(clusterDir, 's');
clustData.TTdn = TTdn;

if handles.gotPos
    handles.posAve = posAve;
    handles.posT = posAve(:,1);
    handles.posX = posAve(:,2);
    handles.posY = posAve(:,3);
    handles.spikePos = [];
end

handles = loadData(handles);

close(h);
guidata(hObject,handles);

% --- Executes on selection change in list_tetrode.
function list_tetrode_Callback(hObject, eventdata, handles)
% hObject    handle to list_tetrode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_tetrode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_tetrode

%% update current tetrode
contents = get(hObject,'String');
selectedText = contents{get(hObject,'Value')};
handles.tetrode = str2double(selectedText);
set(handles.text_tetrode, 'String', handles.tetrode);

%% update cluster list based on current tetrode
clust_indices = handles.current_tetCells(:,1)==handles.tetrode;
current_clusters = sort(cellstr(num2str(handles.current_tetCells(clust_indices,2))));
set(handles.list_cluster,'String',current_clusters,'Value',1);
contents = get(handles.list_cluster,'String');
selectedText = contents{get(handles.list_cluster,'Value')};
handles.cluster = str2double(selectedText);
set(handles.text_cluster, 'String', handles.cluster);

handles = updateCurrentCluster(handles);

guidata(hObject,handles);

function handles = updateCurrentCluster(handles)

%% get spike info
handles.spikes = data.getSpikeTimes([handles.tetrode handles.cluster]);
handles.spikePos = data.getSpikePositions(handles.spikes,handles.posAve);

%% calculate rate map
map = analyses.map([handles.posT handles.posX handles.posY], handles.spikes, 'smooth', handles.smoothing, 'binWidth', handles.binWidth, 'minTime', 0, 'limits', handles.mapLimits);
handles.map = map.z;

%% calculate mean rate in Hz
handles.meanRate = analyses.meanRate(handles.spikes, handles.posAve);
set(handles.text_meanRate, 'String', handles.meanRate);

%% calculate peak rate in Hz
if ~isfield(map,'peakRate')
    handles.peakRate = 0;
else
    handles.peakRate = map.peakRate;
end
set(handles.text_peakRate, 'String', handles.peakRate);

%% calculate total spikes
handles.totalSpikes = length(handles.spikes);
set(handles.text_totalSpikes, 'String', handles.totalSpikes);

%% calculate spike width
handles.spikeWidth = calc.halfMaxWidth(handles.userDir, handles.tetrode, handles.spikes);
set(handles.text_spikeWidth, 'String', round(handles.spikeWidth));

%% clear map stats
set(handles.text_spatContent, 'String', '');
set(handles.text_sparsity, 'String', '');
set(handles.text_selectivity, 'String', '');
set(handles.text_coherence, 'String', '');
set(handles.text_fieldNo, 'String', '');
set(handles.text_fieldMean, 'String', '');
set(handles.text_fieldMax, 'String', '');

%% plot animal path
hSPP = plot(handles.posAve(:,2),handles.posAve(:,3),'color',[.5 .5 .5]);
set(hSPP,'hittest','off')
set(gca,'ydir','reverse')
set(gca,'color',[.8 .8 .8],'xcolor',[.8 .8 .8],'ycolor',[.8 .8 .8],'box','off','buttondownfcn',@axes1_ButtonDownFcn)
axis equal


% --- Executes on selection change in list_cluster.
function list_cluster_Callback(hObject, eventdata, handles)
% hObject    handle to list_cluster (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_cluster contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_cluster

%% update current cluster
contents = get(hObject,'String');
selectedText = contents{get(hObject,'Value')};
handles.cluster = str2double(selectedText);
set(handles.text_cluster, 'String', handles.cluster);

handles = updateCurrentCluster(handles);

guidata(hObject,handles);

% --- Executes on button press in butt_spikepathplot.
function butt_spikepathplot_Callback(hObject, eventdata, handles)
% hObject    handle to butt_spikepathplot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% plot path
hSPP = plot(handles.posAve(:,2),handles.posAve(:,3),'color',[.5 .5 .5]);
set(hSPP,'hittest','off') % necessary for pop-out behavior
set(gca,'ydir','reverse')
axis equal
hold on

%% either color by HD or just black
if handles.gotPosHD && handles.checkbox_SPP.Value
    [spikePos,spkInd] = data.getSpikePositions(handles.spikes,handles.pos);
    spkHDdeg = analyses.calcHeadDirection(handles.pos(spkInd,:));
    spkHDdeg2 = mod(360-spkHDdeg,360);
    [vals,inds] = sort(spkHDdeg2);
    spikePosSort = spikePos(inds,:);
    spkcmap = zeros(length(vals),3);
    cmap = hsv(360);
    colormap(gca,cmap);
    for iSpike = 1:length(vals)
        try
            spkcmap(iSpike,:) = cmap(round(vals(iSpike)),:);
        catch
            spkcmap(iSpike,:) = [0 0 0];
        end
    end
    hSPP = scatter(spikePosSort(:,2),spikePosSort(:,3),handles.marker,spkcmap,'filled');
    set(hSPP,'hittest','off')
else
    hSPP = plot(handles.spikePos(:,2),handles.spikePos(:,3),'k.','MarkerSize',handles.marker);
    set(hSPP,'hittest','off')
end
hold off
set(gca,'color',[.8 .8 .8],'xcolor',[.8 .8 .8],'ycolor',[.8 .8 .8],'box','off','buttondownfcn',@axes1_ButtonDownFcn) % enable pop-out

% --- Executes on selection change in edit_markersize
function edit_markersize_Callback(hObject, eventdata, handles)
% hObject    handle to edit_markersize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_markersize as text
%        str2double(get(hObject,'String')) returns contents of edit_markersize as a double

%% change marker size for spike overlay
handles.marker = str2double(get(hObject,'String'));
axes(handles.axes1);
guidata(hObject,handles);

%% replot
butt_spikepathplot_Callback(handles.butt_spikepathplot, eventdata,handles);

% --- Executes on button press in checkbox_SPP.
function checkbox_SPP_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_SPP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_SPP

%% replot
butt_spikepathplot_Callback(handles.butt_spikepathplot,eventdata,handles);

% --- Executes on button press in butt_batchSPP.
function butt_batchSPP_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchSPP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% prompt for settings
numClusters = size(handles.cellMatrix,1);
prompt={'Spike marker size','Color by HD (y/n)'};
name='Markers';
numlines=1;
defaultanswer={'15','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
Marker = str2double(Answers{1});
colorByHD = Answers{2};

%% set up subplots
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
numSheets = ceil(numClusters/(spRows*spCols));

cmap = hsv(360);
splitHandlesUserDir = regexp(handles.userDir,'\','split');

%% go thru clusters
for iCluster = 1:numClusters
    
    %% set up figure
    if iCluster == 1
        figBatchSPP = figure('Name',[handles.userDir,sprintf('[%d]',1)],'Color','w','units','norm','pos',[0 0.05 0.75 0.8]);
        clf(figBatchSPP);
    end
    
    %% currently supports up to 4 sheets (64 cells)
    if iCluster <= (spRows*spCols)
        iSheet = 1;
    elseif iCluster > (spRows*spCols) && iCluster <= (spRows*spCols)*2
        iSheet = 2;
    elseif iCluster > (spRows*spCols)*2 && iCluster <= (spRows*spCols)*3
        iSheet = 3;
    elseif iCluster > (spRows*spCols)*3 && iCluster <= (spRows*spCols)*4
        iSheet = 4;
    end
    [c r] = ind2sub([spRows,spCols],iCluster-((spRows*spCols)*(iSheet-1)));
    axes('position',sub_pos{r,c}); %#ok<LAXES>
    
    %% plot
    plot(handles.posAve(:,2),handles.posAve(:,3),'color',[.5 .5 .5])
    set(gca,'ydir','rev')
    hold on
    spikes = data.getSpikeTimes(handles.cellMatrix(iCluster,:));
    if handles.gotPosHD && strcmpi(colorByHD,'y')
        [spikePos,spkInd] = data.getSpikePositions(spikes,handles.pos);
        spkHDdeg = analyses.calcHeadDirection(handles.pos(spkInd,:));
        spkHDdeg2 = mod(360-spkHDdeg,360);
        [vals,inds] = sort(spkHDdeg2);
        spikePosSort = spikePos(inds,:);
        spkcmap = zeros(length(vals),3);
        colormap(gca,cmap);
        for iSpike = 1:length(vals)
            try
                spkcmap(iSpike,:) = cmap(round(vals(iSpike)),:);
            catch
                spkcmap(iSpike,:) = [0 0 0];
            end
        end
        scatter(spikePosSort(:,2),spikePosSort(:,3),handles.marker,spkcmap,'filled');
    else
        spikePos = data.getSpikePositions(spikes,handles.posAve);
        plot(spikePos(:,2),spikePos(:,3),'k.','MarkerSize',Marker)
    end
    title(sprintf('T%d C%d',handles.cellMatrix(iCluster,1),handles.cellMatrix(iCluster,2)));
    axis off
    axis equal
    hold off
    
    %% save sheet
    if mod(iCluster,spRows*spCols) == 0 || iCluster == numClusters
        set(gcf,'PaperUnits','centimeters');
        set(gcf,'PaperSize',[pageWidth pageHeight]*2);
        set(gcf,'PaperPositionMode','manual');
        set(gcf,'PaperPosition',[0 0 pageWidth pageHeight]*2);
        saveas(figBatchSPP,fullfile(handles.userDir,sprintf('SPPs_%s[%d].pdf',splitHandlesUserDir{end},iSheet)));
        if iCluster < numClusters
            figBatchSPP = figure('Name',[handles.userDir,sprintf('[%d]',iSheet+1)],'Color','w','units','norm','pos',[0 0.05 0.75 0.8]);
            clf(figBatchSPP);
        end
    end
end
    
% --- Executes on button press in butt_ratemap.
function butt_ratemap_Callback(hObject, eventdata, handles)
% hObject    handle to butt_ratemap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

map = analyses.map([handles.posT handles.posX handles.posY],handles.spikes,'smooth',handles.smoothing,'binWidth',handles.binWidth,'limits',handles.mapLimits);
colorMapBRK(map.z);
axis on
set(gca,'color',[.8 .8 .8],'xcolor',[.8 .8 .8],'ycolor',[.8 .8 .8],'box','off','buttondownfcn',@axes1_ButtonDownFcn)

% --- Executes on button press in butt_batchRM.
function butt_batchRM_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

numClusters = size(handles.cellMatrix,1);

%% prompt for settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.binWidth),'0','n','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});

%% set up subplots
pageHeight = 16;
pageWidth = 16;
spCols = 4;
spRows = 4;
leftEdge = 0.4;
rightEdge = 0;
topEdge = 1;
bottomEdge = 0;
spaceX = 0;
spaceY = 0.8;
fontsize = 10;
sub_pos = subplot_pos(pageWidth,pageHeight,leftEdge,rightEdge,topEdge,bottomEdge,spCols,spRows,spaceX,spaceY);
numSheets = ceil(numClusters/(spRows*spCols));

splitHandlesUserDir = regexp(handles.userDir,'\','split');

%% go thru clusters
for iCluster = 1:numClusters
    
    %% set up figure
    if iCluster == 1
        figBatchRM = figure('Name',[handles.userDir,sprintf('[%d]',1)],'Color','w','units','norm','pos',[0 0.05 0.75 0.8]);
        clf(figBatchRM);
    end
    
    %% currently supports up to 4 sheets (64 cells)
    if iCluster <= (spRows*spCols)
        iSheet = 1;
    elseif iCluster > (spRows*spCols) && iCluster <= (spRows*spCols)*2
        iSheet = 2;
    elseif iCluster > (spRows*spCols)*2 && iCluster <= (spRows*spCols)*3
        iSheet = 3;
    elseif iCluster > (spRows*spCols)*3 && iCluster <= (spRows*spCols)*4
        iSheet = 4;
    end
    [c r] = ind2sub([spRows,spCols],iCluster-((spRows*spCols)*(iSheet-1)));
    axes('position',sub_pos{r,c}); %#ok<LAXES>
    
    %% plot
    spikes = data.getSpikeTimes(handles.cellMatrix(iCluster,:));
    map = analyses.map([handles.posT handles.posX handles.posY], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
    meanRate = analyses.meanRate(spikes, handles.posAve);
    colorMapBRK(map.z,'bar','on');
    title(sprintf('T%d C%d\nmean = %.2f Hz',handles.cellMatrix(iCluster,1),handles.cellMatrix(iCluster,2),meanRate),'fontweight','normal','fontsize',10)
    hold on
    
    %% save sheet
    if mod(iCluster,spRows*spCols) == 0 || iCluster == numClusters
        set(gcf,'PaperUnits','centimeters');
        set(gcf,'PaperSize',[pageWidth pageHeight]);
        set(gcf,'PaperPositionMode','manual');
        set(gcf,'PaperPosition',[0 0 pageWidth pageHeight]);
        saveas(figBatchRM,fullfile(handles.userDir,sprintf('rateMaps_%s[%d].pdf',splitHandlesUserDir{end},iSheet)));
        if iCluster < numClusters
            figBatchRM = figure('Name',[handles.userDir,sprintf('[%d]',iSheet+1)],'Color','w','units','norm','pos',[0 0.05 0.75 0.8]);
            clf(figBatchRM);
        end
    end
end

% --- Executes on button press in butt_findFields.
function butt_findFields_Callback(hObject, eventdata, handles)
% hObject    handle to butt_findFields (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[fieldMap,fields] = analyses.placefield(handles.map,'minBins',handles.minBins);
if isempty(fields); warndlg('No fields found'); return; end;
fieldMap(isnan(handles.map)) = nan;
for iFieldNum = 1:size(fields,2)
    peakRates(iFieldNum) = fields(1,iFieldNum).peak;
end
mainField = find(peakRates == max(peakRates));

%% recolor fieldMap in order of field peak rate
[~,ind] = sort(peakRates,'descend');
for iFieldNum = 1:size(fields,2)
    fieldMap(fields(1,ind(iFieldNum)).PixelIdxList) = iFieldNum;
end

colorMapBRK(fieldMap);
set(gca,'color',[.8 .8 .8],'xcolor',[.8 .8 .8],'ycolor',[.8 .8 .8],'box','off','buttondownfcn',@axes1_ButtonDownFcn)
cmap = [get(gca,'color'); ...   % background
    0 0 0.6; ...                % dark blue
    0.6 0 0; ...                % dark red
    1 0.5 0; ...                % orange
    1 1 0; ...                  % yellow
    0 0.6 0; ...                % grass green
    0 1 1; ...                  % cyan
    0 0.5 1; ...                % light blue
    0.4 0 0.8];                 % purple
if ~sum(sum(fieldMap == 0))
    cmap(2,:) = get(gca,'color');
end
colormap(gca,cmap)
caxis([-1 8])

hold on
hSPP = plot(fields(1,mainField).peakX,fields(1,mainField).peakY,'o','markerfacecolor','m','markeredgecolor','w','linewidth',2,'markersize',15);
set(hSPP,'hittest','off')
hold off
axis on

% --- Executes on button press in butt_batchFindFields.
function butt_batchFindFields_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchFindFields (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

numClusters = size(handles.cellMatrix,1);

%% prompt for settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.binWidth),'0','n','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});

prompt={'Threshold for including surrounding bins (included if > thresh*peak)','Bin width (cm)', ...
    'Minimum bins for a field','Minimum peak rate for a field (Hz?)','Display rates (y/n)'};
name='Find field settings';
numlines=1;
defaultanswer={'0.2',num2str(handles.binWidth),num2str(handles.minBins),'1','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
thresh = str2double(Answers{1});
binWidth = str2double(Answers{2});
minBins = str2double(Answers{3});
minPeak = str2double(Answers{4});
displayRates = Answers{5};

%% set up subplots
pageHeight = 16;
pageWidth = 16;
spCols = 4;
spRows = 4;
leftEdge = 0.4;
rightEdge = 0;
topEdge = 1;
bottomEdge = 0.4;
spaceX = 0;
spaceY = 0.8;
fontsize = 10;
sub_pos = subplot_pos(pageWidth,pageHeight,leftEdge,rightEdge,topEdge,bottomEdge,spCols,spRows,spaceX,spaceY);
numSheets = ceil(numClusters/(spRows*spCols));

splitHandlesUserDir = regexp(handles.userDir,'\','split');

for iCluster = 1:numClusters
    
    %% set up figure
    if iCluster == 1
        figBatchFF = figure('Name',[handles.userDir,sprintf('[%d]',1)],'Color','w','units','norm','pos',[0.03 0.09 0.55 0.8]);
        clf(figBatchFF);
    end
    
    %% currently supports up to 4 sheets (64 cells)
    if iCluster <= (spRows*spCols)
        iSheet = 1;
    elseif iCluster > (spRows*spCols) && iCluster <= (spRows*spCols)*2
        iSheet = 2;
    elseif iCluster > (spRows*spCols)*2 && iCluster <= (spRows*spCols)*3
        iSheet = 3;
    elseif iCluster > (spRows*spCols)*3 && iCluster <= (spRows*spCols)*4
        iSheet = 4;
    end
    [c r] = ind2sub([spRows,spCols],iCluster-((spRows*spCols)*(iSheet-1)));
    axes('position',sub_pos{r,c}); %#ok<LAXES>
    
    %% plot
    spikes = data.getSpikeTimes(handles.cellMatrix(iCluster,:));
    map = analyses.map([handles.posT handles.posX handles.posY], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
    [fieldMap,fields] = analyses.placefield(map,'threshold',thresh,'binWidth',binWidth,'minBins',minBins,'minPeak',minPeak);
    fieldMap(isnan(map.z)) = nan;
    if isempty(fields)
        colorMapBRK(zeros(30));
        colormap(gca,[1 1 1])
        title(sprintf('T%d C%d',handles.cellMatrix(iCluster,1),handles.cellMatrix(iCluster,2)),'fontweight','normal','fontsize',10)
        axis off
        continue
    end
    clear peakRates
    for iFieldNum = 1:size(fields,2)
        peakRates(iFieldNum) = fields(1,iFieldNum).peak;
    end
    mainField = find(peakRates == max(peakRates));

    % recolor fieldMap in order of field peak rate
    [~,ind] = sort(peakRates,'descend');
    for iFieldNum = 1:size(fields,2)
        fieldMap(fields(1,ind(iFieldNum)).PixelIdxList) = iFieldNum;
    end

    colorMapBRK(fieldMap);
    cmap = [1 1 1; ...              % background
        0 0 0.6; ...                % dark blue
        0.6 0 0; ...                % dark red
        1 0.5 0; ...                % orange
        1 1 0; ...                  % yellow
        0 0.6 0; ...                % grass green
        0 1 1; ...                  % cyan
        0 0.5 1; ...                % light blue
        0.4 0 0.8];                 % purple
    if ~sum(sum(fieldMap == 0))
        cmap(2,:) = [1 1 1];
    end
    colormap(gca,cmap)
    caxis([-1 8])
    hold on
    
    %% display peak rates or just main peak
    if strcmpi(displayRates,'y')
        for iFieldNum = 1:size(fields,2)
            text(fields(1,iFieldNum).peakX,fields(1,iFieldNum).peakY,sprintf('%.2f',peakRates(iFieldNum)), ...
                'color',[255 109 221]/255,'fontweight','bold','horizontalalignment','center')
        end
    else
        plot(fields(1,mainField).peakX,fields(1,mainField).peakY,'o','markerfacecolor','m','markeredgecolor','w','linewidth',2,'markersize',10);
    end
    title(sprintf('T%d C%d',handles.cellMatrix(iCluster,1),handles.cellMatrix(iCluster,2)),'fontweight','normal','fontsize',10)
    hold off
    
    %% save sheet
    if mod(iCluster,spRows*spCols) == 0 || iCluster == numClusters
        set(gcf,'PaperUnits','centimeters');
        set(gcf,'PaperSize',[pageWidth pageHeight]);
        set(gcf,'PaperPositionMode','manual');
        set(gcf,'PaperPosition',[0 0 pageWidth pageHeight]);
        saveas(figBatchFF,fullfile(handles.userDir,sprintf('findFields_%s[%d].pdf',splitHandlesUserDir{end},iSheet)));
        if iCluster < numClusters
            figBatchFF = figure('Name',[handles.userDir,sprintf('[%d]',iSheet+1)],'Color','w','units','norm','pos',[0.03 0.09 0.55 0.8]);
            clf(figBatchFF);
        end
    end
    
end


% --- Executes on button press in butt_timeDivRM.
function butt_timeDivRM_Callback(hObject, eventdata, handles)
% hObject    handle to butt_timeDivRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% get cell list and all timestamps
numClusters = size(handles.cellMatrix,1);
posAve = handles.posAve;
times = posAve(:,1);
numTimeStamps = length(times);

%% prompt for settings
prompt={'Number of time blocks','Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)'};
name='Settings';
numlines=1;
defaultanswer={'2','2',num2str(handles.binWidth),'0','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
numBlocks = str2double(Answers{1});
smooth = str2double(Answers{2});
binWidth = str2double(Answers{3});
minTime = str2double(Answers{4});

%% make rate maps for each time block
blockLength = floor(numTimeStamps/numBlocks);
field_names = {'s','tMins','t','x','y'};
empty_cells = repmat(cell(1),1,numel(field_names));
entries = {field_names{:} ; empty_cells{:}};
spikesStruct = struct(entries{:});
nameTag = sprintf('T%d C%d',handles.tetrode,handles.cluster);
figTimeDivRM = figure('name',nameTag);

%% get spike times
spikes = data.getSpikeTimes([handles.tetrode handles.cluster]);
for iBlock = 1:numBlocks
    if iBlock == 1   %% first time block
        spikesStruct(iBlock).s = spikes(spikes <= times(blockLength));    % spike times
        spikesStruct(iBlock).tMins = [0,floor(blockLength/1920)];         % time in mins (1920 b/c sampling at 32 Hz)
        spikesStruct(iBlock).t = posAve(1:blockLength,1);                 % position times
        spikesStruct(iBlock).x = posAve(1:blockLength,2);                 % x-coordinate times
        spikesStruct(iBlock).y = posAve(1:blockLength,3);                 % y-coordinate times
    elseif iBlock == numBlocks      %% last time block
        spikesStruct(iBlock).s = spikes(times((numBlocks-1)*blockLength) < spikes);
        spikesStruct(iBlock).tMins = [floor((numTimeStamps-blockLength)/1920),floor(numTimeStamps/1920)];
        spikesStruct(iBlock).t = posAve((numBlocks-1)*blockLength:(numBlocks-1)*blockLength+(blockLength-1),1);
        spikesStruct(iBlock).x = posAve((numBlocks-1)*blockLength:(numBlocks-1)*blockLength+(blockLength-1),2);
        spikesStruct(iBlock).y = posAve((numBlocks-1)*blockLength:(numBlocks-1)*blockLength+(blockLength-1),3);
    else    %% middle time blocks
        spikesStruct(iBlock).s = spikes(spikes <= times(iBlock*blockLength));
        spikesStruct(iBlock).s = spikes(spikesStruct(iBlock).s > times((iBlock-1)*blockLength));
        spikesStruct(iBlock).tMins = [floor(((iBlock-1)*blockLength)/1920),floor((iBlock*blockLength)/1920)];
        spikesStruct(iBlock).t = posAve((iBlock-1)*blockLength+1:iBlock*blockLength,1);
        spikesStruct(iBlock).x = posAve((iBlock-1)*blockLength+1:iBlock*blockLength,2);
        spikesStruct(iBlock).y = posAve((iBlock-1)*blockLength+1:iBlock*blockLength,3);
    end
end
%% make rate maps
for iBlock = 1:numBlocks
    map = analyses.map([spikesStruct(iBlock).t spikesStruct(iBlock).x spikesStruct(iBlock).y], spikesStruct(iBlock).s, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
    mapMat{1,iBlock} = map.z;
    meanRateMat(1,iBlock) = analyses.meanRate(spikesStruct(iBlock).s,[spikesStruct(iBlock).t spikesStruct(iBlock).x spikesStruct(iBlock).y]);
    subplot(ceil(sqrt(numBlocks)),ceil(sqrt(numBlocks)),iBlock)
    try
        colorMapBRK(map.z,'bar','on');
        title(sprintf('%.2f',meanRateMat(1,iBlock)))
        hold on
    catch
        axis off
    end
end
figure;
numMaps = 1:1:numBlocks;
combo = nchoosek(numMaps,2);
text(1,1,nameTag,'horizontalalignment','center')
for iComp = 1:size(combo,1)
    compTag = sprintf('%d vs %d',combo(iComp,1),combo(iComp,2));
    text((iComp+1),0,compTag,'horizontalalignment','center')
    cc = analyses.spatialCrossCorrelation(mapMat{1,combo(iComp,1)},mapMat{1,combo(iComp,2)});
    ccTag = sprintf('%.2f',cc);
    h = text((iComp+1),1,ccTag,'horizontalalignment','center');
    if cc >= 0.5
        set(h,'fontweight','bold','color','b')
    end
end
axis([0.5 (iComp+1.5) -0.5 1.5])
set(gca,'ydir','reverse')
axis off

% --- Executes on button press in butt_batchTimeDivRM.
function butt_batchTimeDivRM_Callback(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to butt_batchTimeDivRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% get cell list and all timestamps
numClusters = size(handles.cellMatrix,1);
posAve = handles.posAve;
times = posAve(:,1);
numTimeStamps = length(times);

%% prompt for settings
prompt={'Number of time blocks','Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)','Publication quality? (y/n)'};
name='Settings';
numlines=1;
defaultanswer={'2','2',num2str(handles.binWidth),'0','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
numBlocks = str2double(Answers{1});
smooth = str2double(Answers{2});
binWidth = str2double(Answers{3});
minTime = str2double(Answers{4});
if strcmp('n',Answers{5})
    pubQual = 0;
else
    pubQual = 1;
end

%% make rate maps for each time block
blockLength = floor(numTimeStamps/numBlocks);
field_names = {'s','tMins','t','x','y'};
empty_cells = repmat(cell(1),1,numel(field_names));
entries = {field_names{:} ; empty_cells{:}};
spikesStruct = struct(entries{:});
for iCluster = 1:numClusters
    figTimeDivRM = figure;
    set(figTimeDivRM,'Name',sprintf('T%d C%d',handles.cellMatrix(iCluster,1),handles.cellMatrix(iCluster,2)),'Color','w');
    %% get spike times
    spikes = data.getSpikeTimes(handles.cellMatrix(iCluster,:));
    for iBlock = 1:numBlocks
        if iBlock == 1   %% first time block
            spikesStruct(iBlock).s = spikes(spikes <= times(blockLength));    % spike times
            spikesStruct(iBlock).tMins = [0,floor(blockLength/1920)];         % time in mins (1920 b/c sampling at 32 Hz)
            spikesStruct(iBlock).t = posAve(1:blockLength,1);                 % position times
            spikesStruct(iBlock).x = posAve(1:blockLength,2);                 % x-coordinate times
            spikesStruct(iBlock).y = posAve(1:blockLength,3);                 % y-coordinate times
        elseif iBlock == numBlocks      %% last time block
            spikesStruct(iBlock).s = spikes(times((numBlocks-1)*blockLength) < spikes);
            spikesStruct(iBlock).tMins = [floor((numTimeStamps-blockLength)/1920),floor(numTimeStamps/1920)];
            spikesStruct(iBlock).t = posAve((numBlocks-1)*blockLength:(numBlocks-1)*blockLength+(blockLength-1),1);
            spikesStruct(iBlock).x = posAve((numBlocks-1)*blockLength:(numBlocks-1)*blockLength+(blockLength-1),2);
            spikesStruct(iBlock).y = posAve((numBlocks-1)*blockLength:(numBlocks-1)*blockLength+(blockLength-1),3);
        else    %% middle time blocks
            spikesStruct(iBlock).s = spikes(spikes <= times(iBlock*blockLength));
            spikesStruct(iBlock).s = spikes(spikesStruct(iBlock).s > times((iBlock-1)*blockLength));
            spikesStruct(iBlock).tMins = [floor(((iBlock-1)*blockLength)/1920),floor((iBlock*blockLength)/1920)];
            spikesStruct(iBlock).t = posAve((iBlock-1)*blockLength+1:iBlock*blockLength,1);
            spikesStruct(iBlock).x = posAve((iBlock-1)*blockLength+1:iBlock*blockLength,2);
            spikesStruct(iBlock).y = posAve((iBlock-1)*blockLength+1:iBlock*blockLength,3);
        end
    end
    %% make rate maps
    for iBlock = 1:numBlocks
        try
            map = analyses.map([spikesStruct(iBlock).t spikesStruct(iBlock).x spikesStruct(iBlock).y], spikesStruct(iBlock).s, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
            mapMat{iCluster,iBlock} = map.z;
            meanRateMat(iCluster,iBlock) = analyses.meanRate(spikesStruct(iBlock).s,[spikesStruct(iBlock).t spikesStruct(iBlock).x spikesStruct(iBlock).y]);
            subplot(ceil(sqrt(numBlocks)),ceil(sqrt(numBlocks)),iBlock)
            colorMapBRK(map.z,'bar','on','pubQual',pubQual);
            title(sprintf('%.2f',meanRateMat(iCluster,iBlock)))
            hold on
        end
    end
end
figure;
numMaps = 1:1:numBlocks;
combo = nchoosek(numMaps,2);
for iCluster = 1:numClusters
    nametag = sprintf('T%dC%d',handles.cellMatrix(iCluster,1),handles.cellMatrix(iCluster,2));
    text(1,iCluster,nametag,'horizontalalignment','center')
    for iComp = 1:size(combo,1)
        if iCluster == 1
            comptag = sprintf('%d vs %d',combo(iComp,1),combo(iComp,2));
            text((iComp+1),0,comptag,'horizontalalignment','center')
        end
        cc = analyses.spatialCrossCorrelation(mapMat{iCluster,combo(iComp,1)},mapMat{iCluster,combo(iComp,2)});
        cctag = sprintf('%.2f',cc);
        h = text((iComp+1),iCluster,cctag,'horizontalalignment','center');
        if cc >= 0.5
            set(h,'fontweight','bold','color','b')
        end
    end
end
axis([0 (iComp+1) 0 numClusters+1])
set(gca,'ydir','reverse')
axis off

% --- Executes on button press in butt_headDirection.
function butt_headDirection_Callback(hObject, eventdata, handles)
% hObject    handle to butt_headDirection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% calculate HD
[~,spkInd] = data.getSpikePositions(handles.spikes,handles.pos);
spkHDdeg = analyses.calcHeadDirection(handles.pos(spkInd,:));
allHD = analyses.calcHeadDirection(handles.pos);
tc = analyses.turningCurve(spkHDdeg, allHD, data.sampleTime,'binWidth',handles.binWidthHD);
tcStat = analyses.tcStatistics(tc,handles.binWidthHD,20);
figure;
circularTurningBRK(tc(:,2)/max(tc(:,2)),'k-','linewidth',3)
hold on
circularTurningBRK(tc(:,3)/max(tc(:,3)),'adjustaxis',false,'color',[.5 .5 .5])
title(sprintf('T%d C%d\nlength = %.2f angle = %.2f',handles.tetrode,handles.cluster,tcStat.r,mod(360-tcStat.mean,360)));

% --- Executes on button press in butt_batchHD.
function butt_batchHD_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchHD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% get N X 5 matrix of position data (timestamp, X1, Y1, X2, Y2)
numClusters = size(handles.cellMatrix,1);
allHD = analyses.calcHeadDirection(handles.pos);

%% set up subplots
pageHeight = 10;
pageWidth = 10;
spCols = 4;
spRows = 4;
leftEdge = 0.2;
rightEdge = 0;
topEdge = 1.2;
bottomEdge = 0;
spaceX = 0;
spaceY = 0.8;
fontsize = 10;
sub_pos = subplot_pos(pageWidth,pageHeight,leftEdge,rightEdge,topEdge,bottomEdge,spCols,spRows,spaceX,spaceY);
numSheets = ceil(numClusters/(spRows*spCols));

splitHandlesUserDir = regexp(handles.userDir,'\','split');

for iCluster = 1:numClusters
    
    %% set up figure
    if iCluster == 1
        figBatchHD = figure('Name',[handles.userDir,sprintf('[%d]',1)],'Color','w','units','norm','pos',[0 0.01 0.5 0.9]);
        clf(figBatchHD);
    end
    
    %% currently supports up to 4 sheets (64 cells)
    if iCluster <= (spRows*spCols)
        iSheet = 1;
    elseif iCluster > (spRows*spCols) && iCluster <= (spRows*spCols)*2
        iSheet = 2;
    elseif iCluster > (spRows*spCols)*2 && iCluster <= (spRows*spCols)*3
        iSheet = 3;
    elseif iCluster > (spRows*spCols)*3 && iCluster <= (spRows*spCols)*4
        iSheet = 4;
    end
    [c r] = ind2sub([spRows,spCols],iCluster-((spRows*spCols)*(iSheet-1)));
    axes('position',sub_pos{r,c}); %#ok<LAXES>
    
    spikes = data.getSpikeTimes(handles.cellMatrix(iCluster,:));
    [~,spkInd] = data.getSpikePositions(spikes,handles.pos);
    spkHDdeg = analyses.calcHeadDirection(handles.pos(spkInd,:));

    if ~isempty(spkHDdeg)
        tc = analyses.turningCurve(spkHDdeg, allHD, data.sampleTime,'binWidth',handles.binWidthHD);
        tcStat = analyses.tcStatistics(tc,handles.binWidthHD,20);
        circularTurningBRK(tc(:,2)/max(tc(:,2)),'k-','linewidth',3)
        hold on
        circularTurningBRK(tc(:,3)/max(tc(:,3)),'adjustaxis',false,'color',[.5 .5 .5])
        axis equal
        title(sprintf('T%d C%d\nlength = %.2f\nangle = %.2f',handles.cellMatrix(iCluster,1),handles.cellMatrix(iCluster,2),tcStat.r,mod(360-tcStat.mean,360)),'fontsize',10);
    else
        title(sprintf('T%d C%d\n\n',handles.cellMatrix(iCluster,1),handles.cellMatrix(iCluster,2)),'fontsize',10);
        axis off
    end
    
    %% save sheet
    if mod(iCluster,spRows*spCols) == 0 || iCluster == numClusters
        set(figBatchHD,'PaperUnits','centimeters');
        set(figBatchHD,'PaperSize',[pageWidth*2 pageHeight*2]);
        set(figBatchHD,'PaperPositionMode','manual');
        set(figBatchHD,'PaperPosition',[0 0 pageWidth*2 pageHeight*2]);
        saveas(figBatchHD,fullfile(handles.userDir,sprintf('HDplots_%s[%d].pdf',splitHandlesUserDir{end},iSheet)));
        if iCluster < numClusters
            figBatchHD = figure('Name',[handles.userDir,sprintf('[%d]',iSheet+1)],'Color','w','units','norm','pos',[0 0.01 0.5 0.9]);
            clf(figBatchHD);
        end
    end
    
end

% --- Executes on button press in butt_grid.
function butt_grid_Callback(hObject, eventdata, handles)
% hObject    handle to butt_grid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% prompt for settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.binWidth),'0'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});

%% autocorrelation
map = analyses.map([handles.posT handles.posX handles.posY], handles.spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
autoCorr = analyses.autocorrelation(map.z);
try
    [score, stats] = analyses.gridnessScore(autoCorr);
catch % old method
    [score, stats] = analyses.gridnessScore(autoCorr,'threshold',0.2);
end
if ~isempty(stats.spacing)
    gridScore = score;
    gridSpacing = mean(stats.spacing);
else
    gridScore = nan;
    gridSpacing = nan;
end

%% plot autocorrelogram with score and spacing
ACfig = figure;
colorMapBRK(autoCorr);
title(sprintf('score = %.2f\nspacing = %.2f', gridScore, gridSpacing),'fontsize',14)
set(ACfig, 'Name', handles.userDir)
axis off

% --- Executes on button press in butt_batchGrid.
function butt_batchGrid_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchGrid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

numClusters = size(handles.cellMatrix,1);

%% prompt for settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.binWidth),'0'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});

%% set up subplots
pageHeight = 16;
pageWidth = 16;
spCols = 4;
spRows = 4;
leftEdge = 0.4;
rightEdge = 0;
topEdge = 1;
bottomEdge = 0;
spaceX = 0;
spaceY = 0.8;
fontsize = 10;
sub_pos = subplot_pos(pageWidth,pageHeight,leftEdge,rightEdge,topEdge,bottomEdge,spCols,spRows,spaceX,spaceY);
numSheets = ceil(numClusters/(spRows*spCols));

splitHandlesUserDir = regexp(handles.userDir,'\','split');

%% go thru clusters
for iCluster = 1:numClusters
    
    %% set up figure
    if iCluster == 1
        figBatchAC = figure('Name',[handles.userDir,sprintf('[%d]',1)],'Color','w','units','norm','pos',[0 0.05 0.75 0.8]);
        clf(figBatchAC);
    end
    
    %% currently supports up to 4 sheets (64 cells)
    if iCluster <= (spRows*spCols)
        iSheet = 1;
    elseif iCluster > (spRows*spCols) && iCluster <= (spRows*spCols)*2
        iSheet = 2;
    elseif iCluster > (spRows*spCols)*2 && iCluster <= (spRows*spCols)*3
        iSheet = 3;
    elseif iCluster > (spRows*spCols)*3 && iCluster <= (spRows*spCols)*4
        iSheet = 4;
    end
    [c r] = ind2sub([spRows,spCols],iCluster-((spRows*spCols)*(iSheet-1)));
    axes('position',sub_pos{r,c}); %#ok<LAXES>
    
    spikes = data.getSpikeTimes(handles.cellMatrix(iCluster,:));
    map = analyses.map([handles.posT handles.posX handles.posY], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
    autoCorr = analyses.autocorrelation(map.z);
    try
        [score, stats] = analyses.gridnessScore(autoCorr);
    catch % old method
        [score, stats] = analyses.gridnessScore(autoCorr,'threshold',0.2);
    end
    if ~isempty(stats.spacing)
        gridScore = score;
        gridSpacing = mean(stats.spacing);
    else
        gridScore = nan;
        gridSpacing = nan;
    end
    colorMapBRK(autoCorr);
    title(sprintf('T%dC%d\nscore = %.2f',handles.cellMatrix(iCluster,1),handles.cellMatrix(iCluster,2),gridScore),'fontsize',10,'fontweight','normal')
    axis off
    axis equal
    hold on
    
    %% save sheet
    if mod(iCluster,spRows*spCols) == 0 || iCluster == numClusters
        set(gcf,'PaperUnits','centimeters');
        set(gcf,'PaperSize',[pageWidth pageHeight]);
        set(gcf,'PaperPositionMode','manual');
        set(gcf,'PaperPosition',[0 0 pageWidth pageHeight]);
        saveas(figBatchAC,fullfile(handles.userDir,sprintf('grids_%s[%d].pdf',splitHandlesUserDir{end},iSheet)));
        if iCluster < numClusters
            figBatchAC = figure('Name',[handles.userDir,sprintf('[%d]',iSheet+1)],'Color','w','units','norm','pos',[0 0.05 0.75 0.8]);
            clf(figBatchAC);
        end
    end
end

% --- Executes on button press in butt_border.
function butt_border_Callback(hObject, eventdata, handles)
% hObject    handle to butt_border (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% rate map settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)','Publication quality? (y/n)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.binWidth),'0','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});
if strcmp('n',Answers{4})
    pubQual = 0;
else
    pubQual = 1;
end

%% find field settings
prompt={'Threshold for including surrounding bins (included if > thresh*peak)','Bin width (cm)','Minimum bins for a field','Minimum peak rate for a field (Hz?)'};
name='Find field settings';
numlines=1;
defaultanswer={'0.2',num2str(handles.binWidth),num2str(handles.minBins),'1'};
Answers4 = inputdlg(prompt,name,numlines,defaultanswer,'on');
if isempty(Answers4); return; end;
fieldThresh = str2double(Answers4{1});
binWidth = str2double(Answers4{2});
minBins = str2double(Answers4{3});
minPeak = str2double(Answers4{4});

% %% shuffle
% posX = handles.posAve(:,2);
% posY = handles.posAve(:,3);
% numTimestamps = length(handles.posAve(:,1));
% totalTimeSec = numTimestamps/32;
% indices20sec = (numTimestamps*20)/totalTimeSec;
% shiftList = indices20sec:1:(numTimestamps-indices20sec);
% for iShuffle = 1:40
%     randInd = randi([min(shiftList),max(shiftList)],1);
%     shuffledX = circshift(posX,randInd);
%     shuffledY = circshift(posY,randInd);
%     map = analyses.map([handles.posT shuffledX shuffledY], handles.spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
%     [fieldsMap, fields] = analyses.placefield(map,'threshold',fieldThresh,'binWidth',binWidth,'minBins',minBins,'minPeak',minPeak);
%     if ~isempty(fields)
%         if ~isempty(fieldsMap)
%             borderShuffle(iShuffle) = analyses.borderScore(map.z, fieldsMap, fields);
%         else
%             borderShuffle(iShuffle) = nan;
%         end
%     else
%         borderShuffle(iShuffle) = nan;
%     end
% end
% cutoff = prctile(borderShuffle,95)

%% calculate and plot
map = analyses.map([handles.posT handles.posX handles.posY], handles.spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
[fieldsMap, fields] = analyses.placefield(map,'threshold',fieldThresh,'binWidth',binWidth,'minBins',minBins,'minPeak',minPeak);
if ~isempty(fields)
    if ~isempty(fieldsMap)
        border = analyses.borderScore(map.z, fieldsMap, fields);
    else
        border = nan;
    end
else
    border = nan;
end

figBorder = figure;
colorMapBRK(map.z,'bar','on','pubQual',pubQual);
title(sprintf('T%d C%d\nborder = %.2f',handles.tetrode,handles.cluster,border))
set(figBorder,'Name',handles.userDir);

% --- Executes on button press in butt_batchBorder.
function butt_batchBorder_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchBorder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

numClusters = size(handles.cellMatrix,1);

%% rate map settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)','Publication quality? (y/n)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.binWidth),'0','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});
if strcmp('n',Answers{4})
    pubQual = 0;
else
    pubQual = 1;
end

%% find field settings
prompt={'Threshold for including surrounding bins (included if > thresh*peak)','Bin width (cm)','Minimum bins for a field','Minimum peak rate for a field (Hz?)'};
name='Find field settings';
numlines=1;
defaultanswer={'0.2',num2str(handles.binWidth),num2str(handles.minBins),'1'};
Answers4 = inputdlg(prompt,name,numlines,defaultanswer,'on');
if isempty(Answers4); return; end;
fieldThresh = str2double(Answers4{1});
binWidth = str2double(Answers4{2});
minBins = str2double(Answers4{3});
minPeak = str2double(Answers4{4});

%% set up subplots
pageHeight = 16;
pageWidth = 16;
spCols = 4;
spRows = 4;
leftEdge = 0.4;
rightEdge = 0;
topEdge = 1;
bottomEdge = 0;
spaceX = 0;
spaceY = 0.8;
fontsize = 10;
sub_pos = subplot_pos(pageWidth,pageHeight,leftEdge,rightEdge,topEdge,bottomEdge,spCols,spRows,spaceX,spaceY);
numSheets = ceil(numClusters/(spRows*spCols));

splitHandlesUserDir = regexp(handles.userDir,'\','split');

%% go thru clusters
for iCluster = 1:numClusters
    
    %% set up figure
    if iCluster == 1
        figBatchBorder = figure('Name',[handles.userDir,sprintf('[%d]',1)],'Color','w','units','norm','pos',[0 0.05 0.75 0.8]);
        clf(figBatchBorder);
    end
    
    %% currently supports up to 4 sheets (64 cells)
    if iCluster <= (spRows*spCols)
        iSheet = 1;
    elseif iCluster > (spRows*spCols) && iCluster <= (spRows*spCols)*2
        iSheet = 2;
    elseif iCluster > (spRows*spCols)*2 && iCluster <= (spRows*spCols)*3
        iSheet = 3;
    elseif iCluster > (spRows*spCols)*3 && iCluster <= (spRows*spCols)*4
        iSheet = 4;
    end
    [c r] = ind2sub([spRows,spCols],iCluster-((spRows*spCols)*(iSheet-1)));
    axes('position',sub_pos{r,c}); %#ok<LAXES>
    
    %% plot
    spikes = data.getSpikeTimes(handles.cellMatrix(iCluster,:));
    map = analyses.map([handles.posT handles.posX handles.posY], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
    [fieldsMap, fields] = analyses.placefield(map,'threshold',fieldThresh,'binWidth',binWidth,'minBins',minBins,'minPeak',minPeak);
    border = analyses.borderScore(map.z, fieldsMap, fields);
    colorMapBRK(map.z,'bar','on','pubQual',pubQual);
    title(sprintf('T%d C%d\nborder = %.2f',handles.cellMatrix(iCluster,1),handles.cellMatrix(iCluster,2),border),'fontweight','normal','fontsize',10)
    hold on
    
    %% save sheet
    if mod(iCluster,spRows*spCols) == 0 || iCluster == numClusters
        set(gcf,'PaperUnits','centimeters');
        set(gcf,'PaperSize',[pageWidth pageHeight]);
        set(gcf,'PaperPositionMode','manual');
        set(gcf,'PaperPosition',[0 0 pageWidth pageHeight]);
        saveas(figBatchBorder,fullfile(handles.userDir,sprintf('borders_%s[%d].pdf',splitHandlesUserDir{end},iSheet)));
        if iCluster < numClusters
            figBatchBorder = figure('Name',[handles.userDir,sprintf('[%d]',iSheet+1)],'Color','w','units','norm','pos',[0 0.05 0.75 0.8]);
            clf(figBatchBorder);
        end
    end
end

% --- Executes on button press in butt_waves.
function butt_waves_Callback(hObject, eventdata, handles)
% hObject    handle to butt_waves (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% fix me
if strcmpi(handles.clusterFormat,'Tint')
    disp('Not currently available for this cluster format.')
    return
end

%% settings
prompt={'Do you want to align all the peaks?'};
name='Alignment';
numlines=1;
defaultanswer={'n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer,'on');
if isempty(Answers); return; end;
align = Answers{1};

%% get all data points for cluster
nttFiles = dir(fullfile(handles.userDir,'*.ntt'));
for iTrode = 1:length(nttFiles)
    found = regexp(nttFiles(iTrode).name,sprintf('TT%d',handles.tetrode),'once');
    if ~isempty(found)
        ind = iTrode;
        break
    end
end
spikeFile = [handles.userDir,'\',nttFiles(ind).name];
[trodeTS,tetrodeData,NlxHeader] = io.neuralynx.Nlx2MatSpike(spikeFile,[1,0,0,0,1],1,1);     % open Nlx2MatSpike for help with arguments
trodeTS_sec = (trodeTS/1000000)';
clusterTS = handles.spikes;
clusterData = tetrodeData(:,:,knnsearch(trodeTS_sec,clusterTS));
if numel(clusterTS) < 1
    return
end

%% create figure
figWaves = figure;
set(figWaves,'Name',sprintf('T%d C%d',handles.tetrode,handles.cluster),'position',get(0,'screensize'))
numWaves = numel(handles.spikes);
try
    load cutterColorsBRK
    clusterColor = cutterColorsBRK(handles.cluster+2,:);
catch
    clusterColor = [1 0 0];
end
pageHeight = 16;
pageWidth = 16;
spCols = 5;
spRows = 2;
leftEdge = 0.5;
rightEdge = 0.2;
topEdge = 0.2;
bottomEdge = 0.2;
spaceX = 0.75;
spaceY = 0.05;
fontsize = 6;
sub_pos = subplot_pos(pageWidth,pageHeight,leftEdge,rightEdge,topEdge,bottomEdge,spCols,spRows,spaceX,spaceY);
plotInds = [1 3 2 4 5 7 9 6 8 10];

%% plot waves
meanWave = zeros(32,4);
for iChannel = 1:4         % for each electrode
    axes('position',sub_pos{ind2sub([2 5],plotInds(iChannel))});
    meanWave(:,iChannel) = squeeze(mean(clusterData(:,iChannel,:),3));
    if ~strcmpi(align,'n')
        
        %% peak alignment
        voltages = squeeze(clusterData(:,iChannel,:));
        % trick to find max for each wave in matrix
        idx = find(voltages==repmat(max(voltages,[],1),32,1));
        [r,c] = ind2sub(size(voltages),idx);
        peakInds = accumarray(c,r,[],@min);
        shiftAmount = 8 - peakInds;
        % trick for circshift using different shift amounts for each wave
        [r,c] = size(voltages);
        temp = mod(bsxfun(@plus,(0:r-1).',-shiftAmount(:).' ),r)+1;
        temp = bsxfun(@plus,temp,(0:c-1)*r);
        alignedVoltages = voltages(temp);
        % cutoff tail (can we vectorize this??)
        for iWave = 1:numWaves
            v = alignedVoltages(:,iWave);
            if shiftAmount(iWave) < 0
                v(end-abs(shiftAmount(iWave)):end) = nan;
                alignedVoltages(:,iWave) = v;
            end
        end
        % plot
        patchline(meshgrid(1:32,1:numWaves)',alignedVoltages,'linestyle','-','edgecolor',clusterColor,'linewidth',1,'edgealpha',0.1);
        %% peak-align mean waves as well
        meanWave(:,iChannel) = nanmean(alignedVoltages,2);
    else
        patchline(meshgrid(1:32,1:numWaves)',squeeze(clusterData(:,iChannel,:)),'linestyle','-','edgecolor',clusterColor,'linewidth',1,'edgealpha',0.1);
    end
    %% plot mean wave and bring to front
    hold on
    plot(1:32,meanWave(:,iChannel),'k:','linewidth',2);
    hold off
    axis([1,32,min(clusterData(:)),max(clusterData(:))]);
    axis square
    ylabel('Voltage (uV)')
    xlabel('Time (usec)')
    set(gca,'XTick',[1,8,16,24,32])
    set(gca,'XTickLabel',{'0','250','500','750','1000'})
    
    peaks(iChannel) = max(max(meanWave(:,iChannel)));
    [maxPeak, maxPeakIdx] = max(peaks);
    halfMax = maxPeak / 2;
end

%% spike width
interpWave = interp1(1:32,meanWave(:,maxPeakIdx),1:0.01:32,'spline');
interpMaxIdx = find(interpWave == maxPeak);
Diff = sort(abs(halfMax - interpWave(1:interpMaxIdx))); 
Diff2 = sort(abs(halfMax - interpWave(interpMaxIdx+1:end)));
closest = find(abs(halfMax - interpWave) == Diff(1));
closest2 = find(abs(halfMax - interpWave) == Diff2(1));
spikeWidth = abs(closest - closest2) * (1/3101) * 1000;

%% calculate peaks
numWaves0 = size(tetrodeData,3);
wavePeaks0 = zeros(4,numWaves0);
wavePeaks = zeros(4,numWaves);
for iChannel = 1:4
    wavePeaks0(iChannel,:) = squeeze(max(tetrodeData(:,iChannel,:),[],1));
    wavePeaks(iChannel,:) = squeeze(max(clusterData(:,iChannel,:),[],1));
end

%% plot peaks
peakComps = [1 2; 1 3; 1 4; 2 3; 2 4; 3 4];
for iPeakPlot = 1:length(peakComps)
    axes('position',sub_pos{ind2sub([2 5],plotInds(iPeakPlot+4))});
    hold on
    plot(wavePeaks0(peakComps(iPeakPlot,1),:),wavePeaks0(peakComps(iPeakPlot,2),:),'k.','markersize',1)
    plot(wavePeaks(peakComps(iPeakPlot,1),:),wavePeaks(peakComps(iPeakPlot,2),:),'.','color',clusterColor,'markersize',5)
    try
        axis([0,max(wavePeaks0(peakComps(iPeakPlot,1),:)),0,max(wavePeaks0(peakComps(iPeakPlot,2),:))]);
    end
    axis square
    xlabel(sprintf('Peak %d',peakComps(iPeakPlot,1)))
    ylabel(sprintf('Peak %d',peakComps(iPeakPlot,2)))
end

t = suptitle(sprintf('Spike width = %.2f usec',spikeWidth));
% trust the spike width less if peaks are misaligned...
if strcmpi(align,'n')
    set(t,'color',[.5 .5 .5])
end

% --- Executes on button press in butt_clustView.
function butt_clustView_Callback(hObject, eventdata, handles)
% hObject    handle to butt_clustView (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% get clusters
cellMatrix = sortrows(handles.cellMatrix(handles.cellMatrix(:,1) == handles.tetrode,:),[1 2]);
numClusters = size(cellMatrix,1);

%% fix me
if strcmpi(handles.clusterFormat,'Tint')
    disp('Not currently available for this cluster format.')
    return
end

%% settings
prompt={'Do you want to align all the peaks?'};
name='Alignment';
numlines=1;
defaultanswer={'n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer,'on');
if isempty(Answers); return; end;
align = Answers{1};

%% create figure
figWaves = figure;
set(figWaves,'position',get(0,'screensize'))
try
    load cutterColorsBRK
    clusterColor = cutterColorsBRK(3:numClusters+2,:);
catch
    cmap = colormap('jet');
    clusterColor = cmap(round(linspace(1,64,numClusters)),:);
end
pageHeight = 16;
pageWidth = 16;
spCols = 5;
spRows = 2;
leftEdge = 0.5;
rightEdge = 0.2;
topEdge = 0.2;
bottomEdge = 0.2;
spaceX = 0.75;
spaceY = 0.05;
fontsize = 6;
sub_pos = subplot_pos(pageWidth,pageHeight,leftEdge,rightEdge,topEdge,bottomEdge,spCols,spRows,spaceX,spaceY);
plotInds = [1 3 2 4 5 7 9 6 8 10];

%% tetrode data
nttFiles = dir(fullfile(handles.userDir,'*.ntt'));
for iTrode = 1:length(nttFiles)
    found = regexp(nttFiles(iTrode).name,sprintf('TT%d',handles.tetrode),'once');
    if ~isempty(found)
        ind = iTrode;
        break
    end
end
spikeFile = [handles.userDir,'\',nttFiles(ind).name];
[trodeTS,tetrodeData,NlxHeader] = io.neuralynx.Nlx2MatSpike(spikeFile,[1,0,0,0,1],1,1);     % open Nlx2MatSpike for help with arguments
trodeTS_sec = (trodeTS/1000000)';

%% cluster data
for iCluster = 1:numClusters
    spikes = data.getSpikeTimes([cellMatrix(iCluster,1) cellMatrix(iCluster,2)]);
    clusterTS = spikes;
    clusterData{iCluster} = tetrodeData(:,:,knnsearch(trodeTS_sec,clusterTS));
end

%% plot waves
meanWave = zeros(32,4);
for iChannel = 1:4         % for each electrode
    axes('position',sub_pos{ind2sub([2 5],plotInds(iChannel))});
    for iCluster = 1:numClusters
        meanWave(:,iChannel) = squeeze(mean(clusterData{iCluster}(:,iChannel,:),3));
        if ~strcmpi(align,'n')
            
            %% peak alignment
            voltages = squeeze(clusterData{iCluster}(:,iChannel,:));
            % trick to find max for each wave in matrix
            idx = find(voltages==repmat(max(voltages,[],1),32,1));
            [r,c] = ind2sub(size(voltages),idx);
            peakInds = accumarray(c,r,[],@min);
            shiftAmount = 8 - peakInds;
            % trick for circshift using different shift amounts for each wave
            [r,c] = size(voltages);
            temp = mod(bsxfun(@plus,(0:r-1).',-shiftAmount(:).' ),r)+1;
            temp = bsxfun(@plus,temp,(0:c-1)*r);
            alignedVoltages = voltages(temp);
            % cutoff tail (can we vectorize this??)
            for iWave = 1:size(alignedVoltages,2)
                v = alignedVoltages(:,iWave);
                if shiftAmount(iWave) < 0
                    v(end-abs(shiftAmount(iWave)):end) = nan;
                    alignedVoltages(:,iWave) = v;
                end
            end
            %% peak-align mean waves as well
            meanWave(:,iChannel) = nanmean(alignedVoltages,2);
        else
        end
        %% plot mean wave
%         hold on
%         plot(1:32,meanWave(:,iChannel),'-','color',clusterColor(iCluster,:),'linewidth',3)
%         hold off
        patchline(meshgrid(1:32,1:2)',[meanWave(:,iChannel),meanWave(:,iChannel)],'linestyle','-','edgecolor',clusterColor(iCluster,:),'linewidth',3,'edgealpha',0.4)
        axis([1,32,min(tetrodeData(:)),max(tetrodeData(:))]);
        axis square
        ylabel('Voltage (uV)')
        xlabel('Time (usec)')
        set(gca,'XTick',[1,8,16,24,32])
        set(gca,'XTickLabel',{'0','250','500','750','1000'})
    end
end

%% calculate peaks
numWaves0 = size(tetrodeData,3);
wavePeaks0 = zeros(4,numWaves0);
wavePeaks = cell(1,numClusters);
for iChannel = 1:4
    wavePeaks0(iChannel,:) = squeeze(max(tetrodeData(:,iChannel,:),[],1));
    for iCluster = 1:numClusters
        wavePeaks{iCluster}(iChannel,:) = squeeze(max(clusterData{iCluster}(:,iChannel,:),[],1));
    end
end

%% plot peaks
peakComps = [1 2; 1 3; 1 4; 2 3; 2 4; 3 4];
for iPeakPlot = 1:length(peakComps)
    axes('position',sub_pos{ind2sub([2 5],plotInds(iPeakPlot+4))});
    hold on
    plot(wavePeaks0(peakComps(iPeakPlot,1),:),wavePeaks0(peakComps(iPeakPlot,2),:),'k.','markersize',1)
    for iCluster = 1:numClusters
        plot(wavePeaks{iCluster}(peakComps(iPeakPlot,1),:),wavePeaks{iCluster}(peakComps(iPeakPlot,2),:),'.','color',clusterColor(iCluster,:),'markersize',5)
    end
    try
        axis([0,max(wavePeaks0(peakComps(iPeakPlot,1),:)),0,max(wavePeaks0(peakComps(iPeakPlot,2),:))]);
    end
    axis square
    xlabel(sprintf('Peak %d',peakComps(iPeakPlot,1)))
    ylabel(sprintf('Peak %d',peakComps(iPeakPlot,2)))
end

% --- Executes on button press in butt_autocorr.
function butt_autocorr_Callback(hObject, eventdata, handles)
% hObject    handle to butt_autocorr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

figure('name',sprintf('T%dC%d',handles.tetrode,handles.cluster));
spikes = handles.spikes;
if length(spikes) >= 100
    [counts,centers,thetaInd] = calc.thetaIndex(spikes);
    bar(centers,counts,'facecolor','k');
    xlabel('msec');
    ylabel('Count');
    title(sprintf('theta = %.2f',thetaInd),'fontweight','normal');
end

% --- Executes on button press in butt_batchAutocorr.
function butt_batchAutocorr_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchAutocorr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

numClusters = size(handles.cellMatrix,1);

%% set up subplots
pageHeight = 16;
pageWidth = 16;
spCols = 4;
spRows = 4;
leftEdge = 1;
rightEdge = 0.6;
topEdge = 1;
bottomEdge = 1;
spaceX = 1;
spaceY = 1.8;
fontsize = 10;
sub_pos = subplot_pos(pageWidth,pageHeight,leftEdge,rightEdge,topEdge,bottomEdge,spCols,spRows,spaceX,spaceY);
numSheets = ceil(numClusters/(spRows*spCols));

splitHandlesUserDir = regexp(handles.userDir,'\','split');

%% go thru clusters
for iCluster = 1:numClusters
    
    %% set up figure
    if iCluster == 1
        figAutocorr = figure('Name',[handles.userDir,sprintf('[%d]',1)],'Color','w','units','norm','pos',[0 0.05 0.75 0.8]);
        clf(figAutocorr);
    end
    
    %% currently supports up to 4 sheets (64 cells)
    if iCluster <= (spRows*spCols)
        iSheet = 1;
    elseif iCluster > (spRows*spCols) && iCluster <= (spRows*spCols)*2
        iSheet = 2;
    elseif iCluster > (spRows*spCols)*2 && iCluster <= (spRows*spCols)*3
        iSheet = 3;
    elseif iCluster > (spRows*spCols)*3 && iCluster <= (spRows*spCols)*4
        iSheet = 4;
    end
    [c r] = ind2sub([spRows,spCols],iCluster-((spRows*spCols)*(iSheet-1)));
    axes('position',sub_pos{r,c}); %#ok<LAXES>
    
    %% plot
    spikes = data.getSpikeTimes(handles.cellMatrix(iCluster,:));
    if length(spikes) >= 100
        [counts,centers,thetaInd] = calc.thetaIndex(spikes);
        bar(centers,counts,'facecolor','k');
        xlabel('msec');
        ylabel('Count');
        title(sprintf('T%d C%d\ntheta = %.2f',handles.cellMatrix(iCluster,1),handles.cellMatrix(iCluster,2),thetaInd),'fontweight','normal','fontsize',10);
    else
        title(sprintf('T%d C%d\n',handles.cellMatrix(iCluster,1),handles.cellMatrix(iCluster,2)),'fontweight','normal','fontsize',10);
    end
    hold on
    
    %% save sheet
    if mod(iCluster,spRows*spCols) == 0 || iCluster == numClusters
        set(gcf,'PaperUnits','centimeters');
        set(gcf,'PaperSize',[pageWidth pageHeight]*1.5);
        set(gcf,'PaperPositionMode','manual');
        set(gcf,'PaperPosition',[0 0 pageWidth pageHeight]*1.5);
        saveas(figAutocorr,fullfile(handles.userDir,sprintf('autocorrs_%s[%d].pdf',splitHandlesUserDir{end},iSheet)));
        if iCluster < numClusters
            figAutocorr = figure('Name',[handles.userDir,sprintf('[%d]',iSheet+1)],'Color','w','units','norm','pos',[0 0.05 0.75 0.8]);
            clf(figAutocorr);
        end
    end
end

% --- Executes on button press in butt_cellStats.
function butt_cellStats_Callback(hObject, eventdata, handles)
% hObject    handle to butt_cellStats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% prompt for settings
prompt={'Threshold for including surrounding bins (included if > thresh*peak)','Bin width (cm)','Minimum bins for a field','Minimum peak rate for a field (Hz?)'};
name='Find field settings';
numlines=1;
defaultanswer={'0.2',num2str(handles.binWidth),num2str(handles.minBins),'1'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
thresh = str2double(Answers{1});
binWidth = str2double(Answers{2});
minBins = str2double(Answers{3});
minPeak = str2double(Answers{4});

msg = msgbox('Calculating...');

%% make smoothed rate map and position PDF, then calculate stats
if (get(handles.checkSpatInfo, 'Value') == get(handles.checkSpatInfo, 'Max'))   % see if box is checked

    map = analyses.map([handles.posT handles.posX handles.posY], handles.spikes, 'smooth', 2, 'binWidth', binWidth, 'minTime', 0, 'limits', handles.mapLimits);
    [Info,spars,sel] = analyses.mapStatsPDF(map);
    set(handles.text_spatContent, 'String', Info.content);
    set(handles.text_sparsity, 'String', spars);
    set(handles.text_selectivity, 'String', sel);

end

if (get(handles.checkCoherence, 'Value') == get(handles.checkCoherence, 'Max'))

    Coherence = analyses.coherence(handles.map);
    set(handles.text_coherence, 'String', Coherence);

end

if (get(handles.checkFieldNo, 'Value') == get(handles.checkFieldNo, 'Max'))

    %% calculate and store
    [~,fields] = analyses.placefield(handles.map,'threshold',thresh,'binWidth',binWidth,'minBins',minBins,'minPeak',minPeak);
    fieldNo = length(fields);
    set(handles.text_fieldNo, 'String', fieldNo);
    sizes = nan(1,50);
    for iField = 1:length(fields)
        sizes(iField) = fields(1,iField).size;
    end
    fieldMean = nanmean(sizes);
    fieldMax = nanmax(sizes);
    set(handles.text_fieldMean, 'String', fieldMean);
    set(handles.text_fieldMax, 'String', fieldMax);

end

close(msg);

guidata(hObject,handles);

% --- Executes on button press in butt_statsHelp.
function butt_statsHelp_Callback(hObject, eventdata, handles)
% hObject    handle to butt_statsHelp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

msgbox({'SPATIAL INFORMATION CONTENT (bits/spike) is a value between 0 and inf which measures how much spatial information is carried by each spike. HIGH value for place cells.' ...
    ''...
    'SELECTIVITY (unitless) is a value between 1 and inf which measures the ratio of max rate to mean rate. HIGH value for place cells.' ...
    ''...
    'SPARSITY (unitless) is a value between 0 and 1 which measures the ratio of mean rate squared to mean squared rate. LOW value for place cells.' ...
    ''...
    'COHERENCE (unitless) is a value between 0 and inf which measures the correlation between rate in a given spatial bin with the average rate of its neighboring bins. HIGH for place cells.'...
    },'Stats helper')

% --- Executes on button press in butt_MECcells.
function butt_MECcells_Callback(hObject, eventdata, handles)
% hObject    handle to butt_MECcells (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

numClusters = size(handles.cellMatrix,1);

%% prompt for settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.binWidth),'0'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});

prompt={'Threshold for including surrounding bins (included if > thresh*peak)','Bin width (cm)','Minimum bins for a field','Minimum peak rate for a field (Hz?)'};
name='Find field settings';
numlines=1;
defaultanswer={'0.2',num2str(handles.binWidth),num2str(handles.minBins),'1'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
thresh = str2double(Answers{1});
binWidth = str2double(Answers{2});
minBins = str2double(Answers{3});
minPeak = str2double(Answers{4});

allHD = analyses.calcHeadDirection(handles.pos);

for iCluster = 1:numClusters
    figCheck = figure;
    set(figCheck,'name',sprintf('T%d C%d',handles.cellMatrix(iCluster,1),handles.cellMatrix(iCluster,2)))
%     try
        %% path plot
        subplot(321)
        cmap = hsv(360);
        colormap(gca,cmap);
        spikes = data.getSpikeTimes(handles.cellMatrix(iCluster,:));
%         spikePos = data.getSpikePositions(spikes,handles.posAve);
        [spikePos,spkInd] = data.getSpikePositions(spikes,handles.pos);
        spkHDdeg = analyses.calcHeadDirection(handles.pos(spkInd,:));
        spkHDdeg2 = mod(360-spkHDdeg,360); % invert y-dir for colored spikes
        [vals,inds] = sort(spkHDdeg2);
        spikePosSort = spikePos(inds,:);
        spkcmap = zeros(length(vals),3);
        for iSpike = 1:length(vals)
            try
                spkcmap(iSpike,:) = cmap(round(vals(iSpike)),:);
            catch
                spkcmap(iSpike,:) = [0 0 0];
            end
        end
        plot(handles.posAve(:,2),handles.posAve(:,3),'color',[.5 .5 .5]);
        set(gca,'ydir','reverse')
        hold on
        scatter(spikePosSort(:,2),spikePosSort(:,3),handles.marker,spkcmap,'filled')
        cbar = colorbar;
        cbar.Ticks = linspace(0,1,5);
        cbar.TickLabels = num2cell(0:90:360);
%         plot(spikePos(:,2),spikePos(:,3),'k.','MarkerSize',15)
        axis off;
        axis equal;
        hold off

        %% rate maps
        subplot(322)
        map = analyses.map([handles.posT handles.posX handles.posY], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
        meanRate = analyses.meanRate(spikes, handles.posAve);
        if ~isfield(map,'peakRate')
            map.peakRate = 0;
        end
        colorMapBRK(map.z,'bar','on');
        title(sprintf('mean = %.2f Hz\npeak = %.2f Hz',meanRate,map.peakRate),'fontweight','normal','fontsize',10)
        hold on

        %% HD
        subplot(323)
        tc = analyses.turningCurve(spkHDdeg,allHD,data.sampleTime,'binWidth',handles.binWidthHD);
        tcStat = analyses.tcStatistics(tc,handles.binWidthHD,20);
        circularTurningBRK(tc(:,2)/max(tc(:,2)),'k-','linewidth',3)
        hold on
        circularTurningBRK(tc(:,3)/max(tc(:,3)),'adjustaxis',false,'color',[.5 .5 .5])
        axis equal
        title(sprintf('length = %.2f angle = %.2f',tcStat.r,mod(360-tcStat.mean,360)),'fontweight','normal','fontsize',10);

        %% grid
        subplot(324)
        autoCorr = analyses.autocorrelation(map.z);
        try
            [score, stats] = analyses.gridnessScore(autoCorr);
        catch % old method
            [score, stats] = analyses.gridnessScore(autoCorr,'threshold',0.2);
        end
        if ~isempty(stats.spacing)
            gridScore = score;
            gridSpacing = mean(stats.spacing);
        else
            gridScore = nan;
            gridSpacing = nan;
        end
        colorMapBRK(autoCorr);
        title(sprintf('Score = %.2f\nSpacing = %.2f', gridScore, gridSpacing),'fontweight','normal','fontsize',10)
        axis off
        axis equal
        hold on

        %% autocorrelation
        subplot(325)
        if length(spikes) >= 100
            [counts,centers,thetaInd] = calc.thetaIndex(spikes);
            bar(centers,counts,'facecolor','k');
            xlabel('msec');
            ylabel('Count');
        else
            thetaInd = nan;
        end
        title(sprintf('theta = %.2f',thetaInd),'fontweight','normal');

        %% spatial info
        Info = analyses.mapStatsPDF(map);

        %% border
        [fieldsMap, fields] = analyses.placefield(map,'threshold',thresh,'binWidth',binWidth,'minBins',minBins,'minPeak',minPeak);
        borderScore = analyses.borderScore(map.z, fieldsMap, fields);

        %% titles
        subplot(321)
        title(sprintf('info = %.2f\nborder = %.2f',Info.content,borderScore),'fontweight','normal','fontsize',10)
        subplot(326)
        if gridScore >= 0.4052
            text(0.5,1,'GRID','fontweight','bold','fontsize',10)
        end
        if borderScore >= 0.4680 && Info.content >= 0.6367
            text(0.5,0.75,'BORDER','fontweight','bold','fontsize',10)
        end
        if tcStat.r >= 0.1844
            text(0.5,0.5,'HD','fontweight','bold','fontsize',10)
        end
        if gridScore < 0.4052 && borderScore < 0.4680 && Info.content > 0.6367
            text(0.5,0.25,'SPATIAL','fontweight','bold','fontsize',10)
        end
        if thetaInd >= 5
            text(0.5,0,'THETA','fontweight','bold','fontsize',10)
        end
        axis off
%     end
end

% --- Executes on button press in butt_objects.
function butt_objects_Callback(hObject, eventdata, handles)
% hObject    handle to butt_objects (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% get rate map, occupancy map, and object map
try
    load objectLocations
catch
    [name path] = uigetfile('objectLocations.mat','Choose object locations');
    load(fullfile(path,name))
end

prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.binWidth),'0','n','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});
map = analyses.map([handles.posT handles.posX handles.posY], handles.spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime,'limits',handles.mapLimits);

%% compute
[objRate objTime] = calc.objectAnalysis(map,objectLocations);

%% plot rate measues
figure('name',sprintf('T%dC%d',handles.tetrode,handles.cluster));
subplot(221)
colorMapBRK(map.z,'bar','on');
subplot(223)
axis off
text(0,1,'Rate ratio object 1:')
text(0,0.75,'Rate ratio object 2:')
text(0,0.5,'P val object 1:')
text(0,0.25,'P val object 2:')
text(0,0,'P val all objects:')
values = [nanmean(objRate(1)) ...
    nanmean(objRate(2)) ...
    nanmean(objRate(3)) ...
    nanmean(objRate(4)) ...
    nanmean(objRate(5))];
yLocs = 1:-0.25:0;
for iVal = 1:5
    if iVal < 3
        text(0.75,yLocs(iVal),sprintf('%.2f',values(iVal)))
    else
        if values(iVal) < 0.05
            text(0.75,yLocs(iVal),sprintf('%.2f',values(iVal)),'color','b','fontweight','bold')
        else
            text(0.75,yLocs(iVal),sprintf('%.2f',values(iVal)))
        end
    end
end

%% plot time measures
subplot(222)
colorMapBRK(map.time,'bar','on');
subplot(224)
axis off
text(0,1,'Time ratio object 1:')
text(0,0.75,'Time ratio object 2:')
text(0,0.5,'P val object 1:')
text(0,0.25,'P val object 2:')
text(0,0,'P val all objects:')
values = [nanmean(objTime(1)) ...
    nanmean(objTime(2)) ...
    nanmean(objTime(3)) ...
    nanmean(objTime(4)) ...
    nanmean(objTime(5))];
yLocs = 1:-0.25:0;
for iVal = 1:5
    if iVal < 3
        text(0.75,yLocs(iVal),sprintf('%.2f',values(iVal)))
    else
        if values(iVal) < 0.05
            text(0.75,yLocs(iVal),sprintf('%.2f',values(iVal)),'color','b','fontweight','bold')
        else
            text(0.75,yLocs(iVal),sprintf('%.2f',values(iVal)))
        end
    end
end

% --- Executes on button press in butt_batchObjects.
function butt_batchObjects_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchObjects (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% get rate map, occupancy map, and object map
try
    load objectLocations
catch
    [name path] = uigetfile('objectLocations.mat','Choose object locations');
    load(fullfile(path,name))
end

prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.binWidth),'0','n','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});

h = msgbox('Working ...');

numClusters = size(handles.cellMatrix,1);

for iCluster = 1:numClusters
    spikes = data.getSpikeTimes(handles.cellMatrix(iCluster,:));
    map = analyses.map([handles.posT handles.posX handles.posY], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);

    %% compute
    [objRate objTime] = calc.objectAnalysis(map,objectLocations);
    
    %% rate plot
    figure('name',sprintf('T%dC%d',handles.cellMatrix(iCluster,1),handles.cellMatrix(iCluster,2)));
    subplot(211)
    colorMapBRK(map.z,'bar','on');
    subplot(212)
    axis off
    text(0,1,'Rate ratio object 1:')
    text(0,0.75,'Rate ratio object 2:')
    text(0,0.5,'P val object 1:')
    text(0,0.25,'P val object 2:')
    text(0,0,'P val all objects:')
    values = [nanmean(objRate(1)) ...
        nanmean(objRate(2)) ...
        nanmean(objRate(3)) ...
        nanmean(objRate(4)) ...
        nanmean(objRate(5))];
    yLocs = 1:-0.25:0;
    for iVal = 1:5
        if iVal < 3
            text(0.75,yLocs(iVal),sprintf('%.2f',values(iVal)))
        else
            if values(iVal) < 0.05
                text(0.75,yLocs(iVal),sprintf('%.2f',values(iVal)),'color','b','fontweight','bold')
            else
                text(0.75,yLocs(iVal),sprintf('%.2f',values(iVal)))
            end
        end
    end

end

%% time plot
figure('name',handles.userDir);
subplot(211)
colorMapBRK(map.time,'bar','on');
subplot(212)
axis off
text(0,1,'Time ratio object 1:')
text(0,0.75,'Time ratio object 2:')
text(0,0.5,'P val object 1:')
text(0,0.25,'P val object 2:')
text(0,0,'P val all objects:')
values = [nanmean(objTime(1)) ...
    nanmean(objTime(2)) ...
    nanmean(objTime(3)) ...
    nanmean(objTime(4)) ...
    nanmean(objTime(5))];
yLocs = 1:-0.25:0;
for iVal = 1:5
    if iVal < 3
        text(0.75,yLocs(iVal),sprintf('%.2f',values(iVal)))
    else
        if values(iVal) < 0.05
            text(0.75,yLocs(iVal),sprintf('%.2f',values(iVal)),'color','b','fontweight','bold')
        else
            text(0.75,yLocs(iVal),sprintf('%.2f',values(iVal)))
        end
    end
end

close(h);

% --- Executes on button press in butt_emperor.
function butt_emperor_Callback(hObject, eventdata, handles)
% hObject    handle to butt_emperor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

meta.emperorPenguin

% --- Executes on button press in butt_rateMapPDF.
function butt_rateMapPDF_Callback(hObject, eventdata, handles)
% hObject    handle to butt_rateMapPDF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

meta.rateMapPDF

% --- Executes on button press in butt_HD_PDF.
function butt_HD_PDF_Callback(hObject, eventdata, handles)
% hObject    handle to butt_HD_PDF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

meta.tuningCurvePDF

% --- Executes during object creation, after setting all properties.
function list_tetrode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_tetrode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function list_cluster_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_cluster (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1

axis on
set(gca,'color',[.8 .8 .8],'xcolor',[.8 .8 .8],'ycolor',[.8 .8 .8],'box','off','buttondownfcn',@axes1_ButtonDownFcn)

% --- Executes during object creation, after setting all properties.
function edit_markersize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_markersize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% replot in new figure
handles = guidata(hObject);
oldKids = get(gca,'Children');
figure;
h = axes;
copyobj(oldKids,h);

%% make visually pleasing
set(gca,'ydir','reverse')
axis equal, axis off
set(gcf,'name',sprintf('T%dC%d',handles.tetrode,handles.cluster))
if strcmpi(class(oldKids),'matlab.graphics.primitive.Image')
    colorbar
    cmap = colormap;
    if ~isequal(cmap(1, :), [1 1 1])
        colormap(gca, [1 1 1; cmap]);
    end
    title(sprintf('mean = %.2f Hz\npeak = %.2f Hz\n',handles.meanRate,handles.peakRate),'fontweight','normal','fontsize',10)
elseif strcmpi(class(oldKids),'matlab.graphics.primitive.Data')
    cmap = [get(gca,'color'); ...   % background
        0 0 0.6; ...                % dark blue
        0.6 0 0; ...                % dark red
        1 0.5 0; ...                % orange
        1 1 0; ...                  % yellow
        0 0.6 0; ...                % grass green
        0 1 1; ...                  % cyan
        0 0.5 1; ...                % light blue
        0.4 0 0.8];                 % purple
    fieldMap = analyses.placefield(handles.map,'minBins',handles.minBins);
    fieldMap(isnan(handles.map)) = nan;
    if ~sum(sum(fieldMap == 0))
        cmap(2,:) = get(gca,'color');
    end
    colormap(gca,cmap)
    caxis([-1 8])
end

% --- Executes on button press in butt_switchRats.
function butt_switchRats_Callback(hObject, eventdata, handles)
% hObject    handle to butt_switchRats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% check which rat
if handles.switchRats
    handles.switchRats = 0;
    set(hObject,'value',0,'backgroundColor',[.8 .8 .8],'foregroundcolor','k','string','Red/green rat')
else
    handles.switchRats = 1;
    set(hObject,'value',1,'backgroundColor','b','foregroundcolor','w','string','Blue rat')  
end

%% get N X 3 matrix of position data (timestamp, x-coordinate, y-coordinate)
clear pos;
try
    posAve = data.getPositions('speedFilter',handles.posSpeedFilter);
    handles.gotPos = 1;
catch
    warndlg('Error getting position samples')
    handles.gotPos = 0;
end
if handles.gotPos
    if handles.switchRats % blue rat!
%         pos = data.getPositions('speedFilter',handles.posSpeedFilter,'mode','all','scale','off','average','off');
%         [includeRed includeGreen] = switchRatMask(handles.userDir,pos,1);
%         pos = pos(includeRed,:);
%         [cleanX,cleanY] = removePosJumpsTD(pos(:,2),pos(:,3),25);
%         cleanX = minions.rescaleData(cleanX,handles.mapLimits(1),handles.mapLimits(2));
%         cleanY = minions.rescaleData(cleanY,handles.mapLimits(3),handles.mapLimits(4));
%         handles.pos = [pos(:,1),cleanX,cleanY];
%         handles.posX = cleanX;
%         handles.posY = cleanY;
        
        %% get blue positions
        try
            posAve = blues(fullfile(handles.userDir,'VT1.nvt'),handles);
        catch
            if handles.switchRats
                handles.switchRats = 0;
                set(hObject,'value',0,'backgroundColor',[.8 .8 .8],'foregroundcolor','k','string','Red/green rat')
            else
                handles.switchRats = 1;
                set(hObject,'value',1,'backgroundColor','b','foregroundcolor','w','string','Blue rat')
            end
            msgbox('Failed to find blue LED.');
            return
        end
        handles.posAve = posAve;
        handles.posT = posAve(:,1);
        handles.posX = posAve(:,2);
        handles.posY = posAve(:,3);
        handles.spikePos = [];
        
    else % normal red green inside rat
        handles.posAve = posAve;
        handles.posT = posAve(:,1);
        handles.posX = posAve(:,2);
        handles.posY = posAve(:,3);
        handles.spikePos = [];
    end
end
% head direction position data
if ~handles.switchRats % red/green
    try
        pos = data.getPositions('average','off','speedFilter',handles.posSpeedFilter);
        pos(:,2) = minions.rescaleData(pos(:,2),handles.mapLimits(1),handles.mapLimits(2));
        pos(:,3) = minions.rescaleData(pos(:,3),handles.mapLimits(3),handles.mapLimits(4));
        pos(:,4) = minions.rescaleData(pos(:,4),handles.mapLimits(1),handles.mapLimits(2));
        pos(:,5) = minions.rescaleData(pos(:,5),handles.mapLimits(3),handles.mapLimits(4));
        handles.pos = pos;
        handles.gotPosHD = 1;
    catch
        handles.gotPosHD = 0;
    end
else % blue
    handles.pos = [];
    handles.gotPosHD = 0;
end

%% UPDATE EVERYTHING
%% update tetrode based on current folder
clear current_tetCells;
current_tetCells = data.getCells;
handles.current_tetCells = current_tetCells;
trode_nums = num2str(current_tetCells(:,1));
current_trodes = cellstr(unique(trode_nums));
handles.current_trodes = current_trodes;
set(handles.list_tetrode,'String',current_trodes,'Value',1);
contents = get(handles.list_tetrode,'String');
selectedText = contents{get(handles.list_tetrode,'Value')};
handles.tetrode = str2double(selectedText);
set(handles.text_tetrode, 'String', handles.tetrode);

%% update cluster based on current tetrode
clust_indices = current_tetCells(:,1)==handles.tetrode;
current_clusters = cellstr(num2str(current_tetCells(clust_indices,2)));
set(handles.list_cluster,'String',current_clusters,'Value',1);
set(handles.list_cluster,'String',current_clusters,'Value',1);
contents = get(handles.list_cluster,'String');
selectedText = contents{get(handles.list_cluster,'Value')};
handles.cluster = str2double(selectedText);
set(handles.text_cluster, 'String', handles.cluster);

%% initialize
handles.meanRate = 0;
handles.peakRate = 0;
handles.totalSpikes = 0;
handles.spikeWidth = 0;
handles.Marker = 3;
for iTrode = 1:8
   handles.trodeTS{iTrode} = ''; 
end

%% plot animal path
if handles.gotPos
        axes(handles.axes1);
        hSPP = plot(handles.posX,handles.posY,'color',[.5 .5 .5]); 
        set(hSPP,'hittest','off') 
        set(gca,'ydir','reverse')
        set(gca,'color',[.8 .8 .8],'xcolor',[.8 .8 .8],'ycolor',[.8 .8 .8],'box','off','buttondownfcn',@axes1_ButtonDownFcn)
        axis(handles.mapLimits)
        axis equal
end

%% get spike info
handles.spikes = data.getSpikeTimes([handles.tetrode handles.cluster]);
if handles.gotPos
    handles.spikePos = data.getSpikePositions(handles.spikes,handles.posAve);
end

if handles.gotPos
    %% calculate rate map
    map = analyses.map([handles.posT handles.posX handles.posY], handles.spikes, 'smooth', handles.smoothing, 'binWidth', handles.binWidth, 'minTime', 0);
    handles.map = map.z;
    
    %% calculate mean rate in Hz
    handles.meanRate = analyses.meanRate(handles.spikes, handles.pos);
    set(handles.text_meanRate, 'String', handles.meanRate);
    
    %% calculate peak rate in Hz
    if ~isfield(map,'peakRate')
        handles.peakRate = 0;
    else
        handles.peakRate = map.peakRate;
    end
    set(handles.text_peakRate, 'String', handles.peakRate);
end

%% calculate total spikes
handles.totalSpikes = length(handles.spikes);
set(handles.text_totalSpikes, 'String', handles.totalSpikes);

%% calculate spike width
try
    handles.spikeWidth = halfMaxWidth(handles.userDir, handles.tetrode, handles.spikes);
    set(handles.text_spikeWidth, 'String', round(handles.spikeWidth));
catch
    set(handles.text_spikeWidth, 'String', 0);
end

%% clear map stats
set(handles.text_spatContent, 'String', '');
set(handles.text_sparsity, 'String', '');
set(handles.text_selectivity, 'String', '');
set(handles.text_coherence, 'String', '');
set(handles.text_fieldNo, 'String', '');
set(handles.text_fieldMean, 'String', '');
set(handles.text_fieldMax, 'String', '');

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function text_meanRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_meanRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function text_peakRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_peakRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function text_tetrode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_tetrode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function text_cluster_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_cluster (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function text_totalSpikes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_totalSpikes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function text_video_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in checkSpatInfo.
function checkSpatInfo_Callback(hObject, eventdata, handles)
% hObject    handle to checkSpatInfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkSpatInfo


% --- Executes on button press in checkCoherence.
function checkCoherence_Callback(hObject, eventdata, handles)
% hObject    handle to checkCoherence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkCoherence


% --- Executes on button press in checkFieldNo.
function checkFieldNo_Callback(hObject, eventdata, handles)
% hObject    handle to checkFieldNo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkFieldNo


% --- Executes during object creation, after setting all properties.
function checkSpatInfo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to checkSpatInfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function text_spikeWidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_spikeWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


function positions = blues(videoFile,handles)


%% load targets
% videoFile = 'O:\annikau\Test_tracking\2019-02-26_15-01-48_AttemptReflexion\VT1.nvt';
fieldSelect = [1,0,0,0,1,0];
getHeader = 0;
extractMode = 1;
[posT,targets] = io.neuralynx.Nlx2MatVT(videoFile,fieldSelect,getHeader,extractMode);
posT = posT/1e6; % msec to sec
dTargets = io.neuralynx.decodeTargets(targets);

%% extract position
% 1 - Luminance, 3 in targets
% 2 - Pure Red, 7 in targets
% 3 - Pure Green, 8 in targets
% 4 - Pure Blue, 9 in targets
% 5 - Raw Red, 4 in targets
% 6 - Raw Green, 5 in targets
% 7 - Raw Blue, 6 in targets
blueInd = 9; % pure blue
numSamp = size(dTargets,1);
blueX = zeros(numSamp,1);
blueY = zeros(numSamp,1);
for i = 1:numSamp
    ind = find(sum(dTargets(i,:,blueInd),3),1);
    if ~isempty(ind)
        blueX(i) = (dTargets(i,ind,1));
        blueY(i) = (dTargets(i,ind,2));
    end
end
    
if length(blueX) ~= 1
    ind = find(blueX == 0 & blueY == 0);
    blueX(ind) = NaN;
    blueY(ind) = NaN;
end

% % plot before cleaning
% hold on
% plot(blueX,blueY,'bo-')

%% clean up
p.distanceThreshold = 6;
p.maxInterpolationGap = 1;
p.posStdThreshold = 2.5;
meanFilterOrder = 15;

[blueX,blueY] = general.removePosJumps(blueX,blueY,p.distanceThreshold,p.posStdThreshold);
blueX = helpers.fixIsolatedData(blueX);
blueY = helpers.fixIsolatedData(blueY);
[tmpPosx, tmpPosy] = general.interpolatePositions(posT,[blueX,blueY]);

tmpPosx = medfilt1(tmpPosx', meanFilterOrder); % there should be no NaNs in input for medfilt1.
tmpPosy = medfilt1(tmpPosy', meanFilterOrder);

maxDiff = abs(nanmax(tmpPosx) - nanmax(tmpPosy));
maxDiff_prev = abs(nanmax(blueX) - nanmax(blueY));
diffPercentage = round(maxDiff / maxDiff_prev * 100);
if maxDiff > 1000 || ((maxDiff > maxDiff_prev) && diffPercentage > 200)
    warning('BNT:positionInQuestion', 'Seems that the interpolation of position samples have failed. Will remove suspicious values.');
    minx = min(blueX);
    maxx = max(blueX);
    miny = min(blueY);
    maxy = max(blueY);
    badIndX = tmpPosx > maxx | tmpPosx < minx;
    badIndY = tmpPosy > maxy | tmpPosy < miny;
    tmpPosx(badIndX) = nan;
    tmpPosy(badIndY) = nan;
end
blueX = tmpPosx;
blueY = tmpPosy;
clear tmpPosx tmpPosy;
positions = [posT',blueX,blueY];
negIdx = posT < 0;
positions(negIdx,:) = [];

%% scale to arena
% XLIM = 100;
% YLIM = 100;
XLIM = handles.mapLimits(2)-handles.mapLimits(1);
YLIM = handles.mapLimits(4)-handles.mapLimits(3);
bntConstants.PosX = 2;
bntConstants.PosY = 3;
minX = nanmin(positions(:, bntConstants.PosX));
maxX = nanmax(positions(:, bntConstants.PosX));
minY = nanmin(positions(:, bntConstants.PosY));
maxY = nanmax(positions(:, bntConstants.PosY));
xLength = maxX - minX;
yLength = maxY - minY;
firstLedArenaIsBigger = true;
scaleCoefX = XLIM / xLength;
scaleCoefY = YLIM / yLength;
if yLength == 1 || isinf(scaleCoefY)
    % the data is probably from a VR linear track, thus all values along y-axis are the same.
    scaleCoefY = 1;
end
% use single factor to scale positions in order to preserve distances between LEDs
positions(:, bntConstants.PosX) = positions(:, bntConstants.PosX) * scaleCoefX;
positions(:, bntConstants.PosY) = positions(:, bntConstants.PosY) * scaleCoefY;
% This is more a hack. So far, scaling is disabled just for one
% project where positions of different trials should be aligned
% to a common value. Scaling and centring messes-up this allignment.
% Centre the box in the coordinate system
if firstLedArenaIsBigger
    centre = general.centreBox(positions(:, bntConstants.PosX), positions(:, bntConstants.PosY));
else
    centre = general.centreBox(positions(:, bntConstants.PosX2), positions(:, bntConstants.PosY2));
end
positions(:, bntConstants.PosX) = positions(:, bntConstants.PosX) - centre(1);
positions(:, bntConstants.PosY) = positions(:, bntConstants.PosY) - centre(2);


%% speed filter (don't need for outside rat)
% xIdx = bntConstants.PosX;
% yIdx = bntConstants.PosY;
% [startInd, endInd] = data.getRunIndices(s);
% validInd = startInd:endInd;
% 
% sessionPos = positions(validInd, [bntConstants.PosT xIdx yIdx]);
% 
% % Indices of positions from LED1 that should be filtered
% led1ToFilter = general.speedThreshold(sessionPos, speedFilter(1), speedFilter(2));
% gBntData{gCurrentTrial}.numGoodSamplesFiltered(1) = length(led1ToFilter);
% 
% % Since we have only exact indices, make complete logical indices that can be used in
% % logical operations (combination)
% selected = false(1, size(sessionPos, 1));
% selected(led1ToFilter) = true;
% 
% % NB! Time stays without NaNs since it should be continuous.
% sessionPos(selected, 2:end) = nan;
% positions(validInd, [xIdx yIdx]) = sessionPos(:, 2:end);
% 
% if size(positions, 2) > 3
%     xIdx = bntConstants.PosX2;
%     yIdx = bntConstants.PosY2;
%     
%     sessionPos = positions(validInd, [bntConstants.PosT xIdx yIdx]);
%     
%     led2ToFilter = general.speedThreshold(sessionPos, speedFilter(1), speedFilter(2));
%     gBntData{gCurrentTrial}.numGoodSamplesFiltered(2) = length(led2ToFilter);
%     
%     selected = false(1, size(sessionPos, 1));
%     selected(led2ToFilter) = true;
%     
%     % NB! Time stays without NaNs since it should be continuous.
%     sessionPos(selected, 2:end) = nan;
%     positions(validInd, [xIdx yIdx]) = sessionPos(:, 2:end);
% end


