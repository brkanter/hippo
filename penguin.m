
% penGUIn: GUI for neurobiological analysis of spatial behavior.
%
% Written by BRK 2014 based on Behavioral Neurology Toolbox (V. Frolov 2013).

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

% Last Modified by GUIDE v2.5 17-Feb-2016 09:10:20

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
handles.output = hObject;

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
global penguinInput arena mapLimits dSmoothing dBinWidth dMinBins clusterFormat
if isempty(penguinInput)
    startup
end
handles.inputFileID = penguinInput;
handles.clusterFormat = clusterFormat;
handles.arena = arena;
handles.mapLimits = mapLimits;
handles.dSmoothing = dSmoothing;
handles.dBinWidth = dBinWidth;
handles.dMinBins = dMinBins;

%% choose directory of behavioral session
handles.userDir = '';
handles.userDir = uigetdir('E:\HM3_CA3\Screening','Choose directory');
cd(handles.userDir);             % make that directory the current one
h = msgbox('Loading...');
set(handles.text_video, 'String', handles.userDir);
if handles.userDir == 0; close(h); return; end;

%% load all data for designated session
writeInputBNT(handles.inputFileID,handles.userDir,handles.arena,handles.clusterFormat)
data.loadSessions(handles.inputFileID);

%% get N X 3 matrix of position data (timestamp, x-coordinate, y-coordinate)
clear posAve;
try
    posAve = data.getPositions('speedFilter',[2 0]);
    handles.gotPos = 1;
catch
    warndlg('Error getting position samples')
    handles.gotPos = 0;
end
if handles.gotPos
    handles.posAve = posAve;
    handles.posT = posAve(:,1);
    handles.posX = posAve(:,2);
    handles.posY = posAve(:,3);
    handles.spikePos = [];
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
    pathTrialBRK('color',[.7 .7 .7])         
    axis off
    axis equal
end

%% get spike info
handles.spikes = data.getSpikeTimes([handles.tetrode handles.cluster]);
if handles.gotPos
    handles.spikePos = data.getSpikePositions(handles.spikes,handles.posAve);
end

if handles.gotPos
    %% calculate rate map
    map = analyses.map([handles.posT handles.posX handles.posY], handles.spikes, 'smooth', handles.dSmoothing, 'binWidth', handles.dBinWidth, 'minTime', 0, 'limits', handles.mapLimits);
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
current_clusters = cellstr(num2str(handles.current_tetCells(clust_indices,2)));
set(handles.list_cluster,'String',current_clusters,'Value',1);
contents = get(handles.list_cluster,'String');
selectedText = contents{get(handles.list_cluster,'Value')};
handles.cluster = str2double(selectedText);
set(handles.text_cluster, 'String', handles.cluster);

%% get spike info
handles.spikes = data.getSpikeTimes([handles.tetrode handles.cluster]);
handles.spikePos = data.getSpikePositions(handles.spikes,handles.posAve);

%% calculate rate map
map = analyses.map([handles.posT handles.posX handles.posY], handles.spikes, 'smooth', handles.dSmoothing, 'binWidth', handles.dBinWidth, 'minTime', 0, 'limits', handles.mapLimits);
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
handles.spikeWidth = halfMaxWidth(handles.userDir, handles.tetrode, handles.spikes);
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
pathTrialBRK('color',[.7 .7 .7])
axis off
axis equal

guidata(hObject,handles);

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

%% get spike info
handles.spikes = data.getSpikeTimes([handles.tetrode handles.cluster]);
handles.spikePos = data.getSpikePositions(handles.spikes,handles.posAve);

%% calculate rate map
map = analyses.map([handles.posT handles.posX handles.posY], handles.spikes, 'smooth', handles.dSmoothing, 'binWidth', handles.dBinWidth, 'minTime', 0, 'limits', handles.mapLimits);
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

%% plot animal path
pathTrialBRK('color',[.7 .7 .7])
axis off
axis equal

guidata(hObject,handles);

% --- Executes on button press in butt_spikepathplot.
function butt_spikepathplot_Callback(hObject, eventdata, handles)
% hObject    handle to butt_spikepathplot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

pathTrialBRK('color',[.7 .7 .7])
axis off
axis equal
hold on
plot(handles.spikePos(:,2),handles.spikePos(:,3),'r+','MarkerSize',handles.Marker)
hold off

% --- Executes on selection change in edit_markersize
function edit_markersize_Callback(hObject, eventdata, handles)
% hObject    handle to edit_markersize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_markersize as text
%        str2double(get(hObject,'String')) returns contents of edit_markersize as a double

%% change marker size for spike overlay
handles.Marker = str2double(get(hObject,'String'));
axes(handles.axes1);
pathTrialBRK('color',[.7 .7 .7])
axis(handles.axes1,'equal');
axis(handles.axes1,'off');
hold on
plot(handles.spikePos(:,2),handles.spikePos(:,3),'r+','MarkerSize',handles.Marker)
hold off

guidata(hObject,handles);

% --- Executes on button press in butt_batchSPP.
function butt_batchSPP_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchSPP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% prompt for settings
cellMatrix = data.getCells;
numClusters = size(cellMatrix,1);
prompt={'Spike marker size'};
name='Marker';
numlines=1;
defaultanswer={'3'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
Marker = str2double(Answers{1});

%% setup figure
figBatchSPP = figure;
set(figBatchSPP,'Name',handles.userDir,'Color','w')
splitHandlesUserDir = regexp(handles.userDir,'\','split');

%% plot
for iCluster = 1:numClusters    
    %% get spike times
    spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
    spikePos = data.getSpikePositions(spikes,handles.posAve);    
    %% plot animal path
    figure(figBatchSPP);
    plotSize = ceil(sqrt(numClusters));
    subplot(plotSize,plotSize,iCluster)
    pathTrialBRK('color',[.7 .7 .7])
    hold on    
    %% overlay spikes
    plot(spikePos(:,2),spikePos(:,3),'r+','MarkerSize',Marker)
    title(sprintf('T%d C%d',cellMatrix(iCluster,1),cellMatrix(iCluster,2)))
    axis off;
    axis equal;
    hold off    
end

saveas(figBatchSPP,sprintf('SPPs_%s.pdf',splitHandlesUserDir{end}));

% --- Executes on button press in butt_ratemap.
function butt_ratemap_Callback(hObject, eventdata, handles)
% hObject    handle to butt_ratemap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% prompt for settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)','Scale to peak of previous session? (y/n)','Publication quality? (y/n)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.dBinWidth),'0','n','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});
scale = Answers{4};
if strcmp('n',Answers{5})
    pubQual = 0;
else
    pubQual = 1;
end

%% calculate and plot
if scale == 'n'
    map = analyses.map([handles.posT handles.posX handles.posY], handles.spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime,'limits',handles.mapLimits);
    figRM = figure;
    colorMapBRK(map.z,'bar','on','pubQual',pubQual);
    title(sprintf('T%d C%d\nmean = %.4f Hz\npeak = %.4f Hz\n',handles.tetrode,handles.cluster,handles.meanRate,map.peakRate),'fontweight','normal','fontsize',10)
    set(figRM,'Name',handles.userDir,'Color','w')
else        % scale to peak    
    %% prompt user to find previous data
    userDir = uigetdir('E:\HM3_CA3','Choose directory for previous session');
    if userDir == 0; return; end;
    prompt={'Tetrode', 'Cell'};
    name='Previous cell';
    numlines=1;
    defaultanswer={num2str(handles.tetrode),num2str(handles.cluster)};
    Answers = inputdlg(prompt,name,numlines,defaultanswer);
    if isempty(Answers); return; end;
    trode = Answers(1);
    cell = Answers(2);
    fileID = fopen(handles.inputFileID,'w');
    fprintf(fileID,'Name: general; Version: 1.0\nSessions %s\nUnits %s %s\nRoom room146\nShape %s',userDir,trode{1,1},cell{1,1},handles.arena);
    
    %% load previous data and store it for comparisons
    data.loadSessions(handles.inputFileID);
    clear posAve;
    posAve = data.getPositions('speedFilter',[2 0]);
    spikes = data.getSpikeTimes([]);
    if isempty(spikes); warndlg('No spikes found in previous session.'); return; end;
    t = posAve(:,1);
    x = posAve(:,2);
    y = posAve(:,3);
    map = analyses.map([t x y], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
    prevMax = nanmax(nanmax(map.z));
    
    %% reload current data
    userDir = handles.userDir;
    if userDir == 0; return; end;
    cd(userDir);             % make that directory the current one    
    writeInputBNT(handles.inputFileID,userDir,handles.arena,handles.clusterFormat)
    data.loadSessions(handles.inputFileID);
    
    %% plot scaled maps
    map = analyses.map([handles.posT handles.posX handles.posY], handles.spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);    
    if ~isfield(map,'peakRate')
        map.peakRate = 0;
    end    
    figRM = figure;
    colorMapBRK(map.z,'cutoffs',[nanmin(nanmin(map.z)),prevMax],'bar','on','pubQual',pubQual);
    title(sprintf('T%d C%d\nmean = %.4f Hz\npeak = %.4f Hz\n',handles.tetrode,handles.cluster,handles.meanRate,map.peakRate),'fontweight','normal','fontsize',10)
    set(figRM,'Name',sprintf('%s scaled to peak of %s',handles.userDir,userDir),'Color','w')    
end

guidata(hObject,handles);

% --- Executes on button press in butt_batchRM.
function butt_batchRM_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


cellMatrix = data.getCells;
numClusters = size(cellMatrix,1);

%% prompt for settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)','Scale to peak of previous session? (y/n)','Publication quality? (y/n)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.dBinWidth),'0','n','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});
scale = Answers{4};
if strcmp('n',Answers{5})
    pubQual = 0;
else
    pubQual = 1;
end

%% calculate and plot
if scale == 'n'   
    splitHandlesUserDir = regexp(handles.userDir,'\','split');
    figBatchRM = figure;
    set(figBatchRM,'Name',splitHandlesUserDir{end},'Color','w')    
    for iCluster = 1:numClusters        
        spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
        map = analyses.map([handles.posT handles.posX handles.posY], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
        meanRate = analyses.meanRate(spikes, handles.posAve);        
        if ~isfield(map,'peakRate')            
            map.peakRate = 0;            
        end        
        figure(figBatchRM);
        plotSize = ceil(sqrt(numClusters));
        subplot(plotSize,plotSize,iCluster)
        colorMapBRK(map.z,'bar','on','pubQual',pubQual);
        title(sprintf('T%d C%d\nmean = %.4f Hz\npeak = %.4f Hz',cellMatrix(iCluster,1),cellMatrix(iCluster,2),meanRate,map.peakRate),'fontweight','normal','fontsize',10)
        hold on        
    end    
    saveas(figBatchRM,sprintf('rateMaps_%s.pdf',splitHandlesUserDir{end}));    
else        % scale to peak    
    %% find previous data
    userDir = uigetdir('E:\HM3_CA3','Choose directory for previous session');
    if userDir == 0; return; end;
    cd(userDir);            
    figBatchRM = figure;
    splitUserDir = regexp(userDir,'\','split');
    splitHandlesUserDir = regexp(handles.userDir,'\','split');
    set(figBatchRM,'Name',sprintf('%s scaled to %s',splitHandlesUserDir{end},splitUserDir{end}),'Color','w')

    %% load previous data and store for comparisons
    writeInputBNT(handles.inputFileID,handles.userDir,handles.arena,handles.clusterFormat)
    data.loadSessions(handles.inputFileID);
    cellMatrix = data.getCells;
    numClusters = size(cellMatrix,1);
    clear posAve;
    posAve = data.getPositions('speedFilter',[2 0]);
    spikes = data.getSpikeTimes([]);
    if isempty(spikes); warndlg('No spikes found in previous session.'); return; end;
    t = posAve(:,1);
    x = posAve(:,2);
    y = posAve(:,3);
    prevMax = zeros(1,numClusters);    
    for iCluster = 1:numClusters        
        spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
        map = analyses.map([t x y], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
        prevMax(iCluster) = nanmax(nanmax(map.z));        
    end    
    %% reload current data
    userDir = handles.userDir;
    if userDir == 0; return; end;
    cd(userDir);             % make that directory the current one    
    writeInputBNT(handles.inputFileID,userDir,handles.arena,handles.clusterFormat)
    data.loadSessions(handles.inputFileID);
    cellMatrix = data.getCells;
    numClusters = size(cellMatrix,1);    
    %% plot scaled maps
    for iCluster = 1:numClusters        
        spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
        map = analyses.map([handles.posT handles.posX handles.posY], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
        meanRate = analyses.meanRate(spikes, handles.posAve);        
        if ~isfield(map,'peakRate')
            map.peakRate = 0;
        end    
        currentMin = nanmin(nanmin(map.z));
        figure(figBatchRM);
        plotSize = ceil(sqrt(numClusters));
        subplot(plotSize,plotSize,iCluster)
        % make sure previous max and current min are not in conflict
        if prevMax(iCluster) == 0; prevMax(iCluster) = 0.0001; end;   % make sure prevMax isn't zero
        if currentMin > prevMax(iCluster)   % if min is bigger than max, set min to zero
            colorMapBRK(map.z,'bar','on','pubQual',pubQual,'cutoffs',[0,prevMax(iCluster)]);
        else
            colorMapBRK(map.z,'bar','on','pubQual',pubQual,'cutoffs',[currentMin,prevMax(iCluster)]);
        end
        title(sprintf('T%d C%d\nmean = %.4f Hz\npeak = %.4f Hz',cellMatrix(iCluster,1),cellMatrix(iCluster,2),meanRate,map.peakRate),'fontweight','normal','fontsize',10)
        hold on        
    end    
    saveas(figBatchRM,sprintf('rateMaps_%s_scaledto_%s.pdf',splitHandlesUserDir{end},splitUserDir{end}));    
end

% --- Executes on button press in butt_findFields.
function butt_findFields_Callback(hObject, eventdata, handles)
% hObject    handle to butt_findFields (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% prompt for settings
prompt={'Threshold for including surrounding bins (included if > thresh*peak)','Bin width (cm)','Minimum bins for a field','Minimum peak rate for a field (Hz?)'};
name='Find field settings';
numlines=1;
defaultanswer={'0.2',num2str(handles.dBinWidth),num2str(handles.dMinBins),'0.1'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
thresh = str2double(Answers{1});
binWidth = str2double(Answers{2});
minBins = str2double(Answers{3});
minPeak = str2double(Answers{4});

%% calculate and plot
[fieldMap,fields] = analyses.placefield(handles.map,'threshold',thresh,'binWidth',binWidth,'minBins',minBins,'minPeak',minPeak);
if isempty(fields); warndlg('No fields found'); return; end;
for iFieldNum = 1:size(fields,2)
    fieldSizes(iFieldNum) = fields(1,iFieldNum).size;
end
biggestField = find(fieldSizes == max(fieldSizes));
figFields = figure;
set(figFields,'Name',sprintf('T%d C%d',handles.tetrode,handles.cluster),'Color','w')
colorMapBRK(fieldMap);
hold on
plot(fields(1,biggestField).x,fields(1,biggestField).y,'r*','MarkerSize',10)
hold off

% --- Executes on button press in butt_timeDivRM.
function butt_timeDivRM_Callback(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to butt_timeDivRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% get cell list and all timestamps
cellMatrix = data.getCells;
numClusters = size(cellMatrix,1);
posAve = data.getPositions('speedFilter',[2 0]);
times = posAve(:,1);
numTimeStamps = length(times);

%% prompt for settings
prompt={'Number of time blocks','Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)','Publication quality? (y/n)'};
name='Settings';
numlines=1;
defaultanswer={'4','2',num2str(handles.dBinWidth),'0','n'};
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
    set(figTimeDivRM,'Name',sprintf('T%d C%d',cellMatrix(iCluster,1),cellMatrix(iCluster,2)),'Color','w');    
    %% get spike times
    spikes = data.getSpikeTimes(cellMatrix(iCluster,:));    
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
        meanRateMat(iCluster,iBlock) = analyses.meanRate(spikesStruct(iBlock).s,[spikesStruct(iBlock).t spikesStruct(iBlock).x spikesStruct(iBlock).y]);
%       subplot(1,numBlocks,iBlock)
        subplot(ceil(sqrt(numBlocks)),ceil(sqrt(numBlocks)),iBlock)
        colorMapBRK(map.z,'bar','on','pubQual',pubQual);
%         title(sprintf('%d - %dmin',spikesStruct(iBlock).tMins(1),spikesStruct(iBlock).tMins(2)))
        title(sprintf('%.2f',meanRateMat(iCluster,iBlock)))
        hold on        
    end    
end
% 
% splitUserDir = regexp(handles.userDir,'\','split');
% outputFile = ['C:\Users\chrislyk\Desktop\' splitUserDir{end}];
% save(outputFile,'meanRateMat');

% --- Executes on button press in butt_headDirection.
function butt_headDirection_Callback(hObject, eventdata, handles)
% hObject    handle to butt_headDirection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% calculate HD
pos = data.getPositions('average','off','speedFilter',[2 0]);
[~,spkInd] = data.getSpikePositions(handles.spikes, handles.posAve);
spkHDdeg = analyses.calcHeadDirection(pos(spkInd,:));
allHD = analyses.calcHeadDirection(pos);
tc = analyses.turningCurve(spkHDdeg, allHD, data.sampleTime,'binWidth',6);
tcStat = analyses.tcStatistics(tc,6,20);
figure;
circularTurningBRK(tc(:,2))
set(gcf,'color','w')
title(sprintf('T%d C%d\nlength = %.2f angle = %.2f',handles.tetrode,handles.cluster,tcStat.r,tcStat.mean));

% --- Executes on button press in butt_batchHD.
function butt_batchHD_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchHD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% get N X 5 matrix of position data (timestamp, X1, Y1, X2, Y2)
msg = msgbox('Loading position data for each LED...');
pos = data.getPositions('average','off','speedFilter',[2 0]);
close(msg);
cellMatrix = data.getCells;
numClusters = size(cellMatrix,1);
allHD = analyses.calcHeadDirection(pos);
splitHandlesUserDir = regexp(handles.userDir,'\','split');
figBatchHD = figure;
set(figBatchHD,'Name',handles.userDir,'Color','w')
for iCluster = 1:numClusters
    spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
    [~,spkInd] = data.getSpikePositions(spikes, handles.posAve);
    spkHDdeg = analyses.calcHeadDirection(pos(spkInd,:));
    figure(figBatchHD);
    plotSize = ceil(sqrt(numClusters));
    subplot(plotSize,plotSize,iCluster)
    tc = analyses.turningCurve(spkHDdeg, allHD, data.sampleTime,'binWidth',6);
    tcStat = analyses.tcStatistics(tc,6,20);
    circularTurningBRK(tc(:,2))
    axis equal
    title(sprintf('T%d C%d\nlength = %.2f angle = %.2f',handles.tetrode,handles.cluster,tcStat.r,tcStat.mean));
    title(sprintf('T%d C%d\nlength = %.2f angle = %.2f',cellMatrix(iCluster,1),cellMatrix(iCluster,2),tcStat.r,tcStat.mean));
end
saveas(figBatchHD,sprintf('HDplots_%s.pdf',splitHandlesUserDir{end}));

% --- Executes on button press in butt_grid.
function butt_grid_Callback(hObject, eventdata, handles)
% hObject    handle to butt_grid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% prompt for settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)','Normalized threshold value used to search for peaks on the autocorrelogram (0:1)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.dBinWidth),'0','0.2'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});
gridThresh = str2double(Answers{4});
if gridThresh < 0 || gridThresh > 1
    gridThresh = 0.2;
    display('Grid threshold value out of range, using default 0.2.')
end

% %% prompt for settings
% prompt={'Normalized threshold value used to search for peaks on the autocorrelogram (0:1)'};
% name='Settings';
% numlines=1;
% defaultanswer={'0.2'};
% Answers = inputdlg(prompt,name,numlines,defaultanswer);
% if isempty(Answers); return; end;
% gridThresh = str2double(Answers{1});
% if gridThresh < 0 || gridThresh > 1
%     gridThresh = 0.2;
%     display('Grid threshold value out of range, using default 0.2.')
% end

% %% shuffle
% posX = handles.posAve(:,2);
% posY = handles.posAve(:,3);
% numTimestamps = length(handles.posAve(:,1));
% totalTimeSec = numTimestamps/32;
% indices20sec = (numTimestamps*20)/totalTimeSec;
% shiftList = indices20sec:1:(numTimestamps-indices20sec);
% for iShuffle = 1:100
%     randInd = randi([min(shiftList),max(shiftList)],1);
%     shuffledX = circshift(posX,randInd);
%     shuffledY = circshift(posY,randInd);
%     map = analyses.map([handles.posT shuffledX shuffledY], handles.spikes, 'smooth', handles.dSmoothing, 'binWidth', handles.dBinWidth, 'minTime', 0, 'limits', handles.mapLimits);
%     autoCorr = analyses.autocorrelation(map.z);
%     score = analyses.gridnessScore(autoCorr, 'threshold', gridThresh);
%     if ~isempty(score)
%         gridScoreShuffle(iShuffle) = score;
%     else
%         gridScoreShuffle(iShuffle) = nan;
%     end
% end
% cutoff = prctile(gridScoreShuffle,95)

%% autocorrelation
map = analyses.map([handles.posT handles.posX handles.posY], handles.spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);    
autoCorr = analyses.autocorrelation(map.z);
[score, stats] = analyses.gridnessScore(autoCorr, 'threshold', gridThresh);
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
if gridScore >= 0.5
% if gridScore >= cutoff
    title(sprintf('SCORE = %.3f\nSPACING = %.3f', gridScore, gridSpacing),'fontweight','bold','fontsize',14)
else
    title(sprintf('Score = %.4f\nSpacing = %.4f', gridScore, gridSpacing),'fontsize',14)
end
set(ACfig, 'Name', handles.userDir, 'Color', 'w')
axis off

% --- Executes on button press in butt_batchGrid.
function butt_batchGrid_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchGrid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cellMatrix = data.getCells;
numClusters = size(cellMatrix,1);

%% prompt for settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)','Normalized threshold value used to search for peaks on the autocorrelogram (0:1)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.dBinWidth),'0','0.2'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});
gridThresh = str2double(Answers{4});
if gridThresh < 0 || gridThresh > 1
    gridThresh = 0.2;
    display('Grid threshold value out of range, using default 0.2.')
end

%% calculate and plot
splitHandlesUserDir = regexp(handles.userDir,'\','split');
figBatchAC = figure;
set(figBatchAC,'Name',splitHandlesUserDir{end},'Color','w')
for iCluster = 1:numClusters    
    spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
    map = analyses.map([handles.posT handles.posX handles.posY], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);    
    %% autocorrelations
    autoCorr = analyses.autocorrelation(map.z);
    [score, stats] = analyses.gridnessScore(autoCorr, 'threshold', gridThresh);
    if ~isempty(stats.spacing)
        gridScore = score;
        gridSpacing = mean(stats.spacing);
    else
        gridScore = nan;
        gridSpacing = nan;
    end   
    %% plot autocorrelogram with score and spacing
    figure(figBatchAC);
    plotSize = ceil(sqrt(numClusters));    
    subplot(plotSize,plotSize,iCluster)
    colorMapBRK(autoCorr);
    if gridScore >= 0.5
        title(sprintf('SCORE = %.3f\nSPACING = %.3f', gridScore, gridSpacing),'fontweight','bold')
    else
        title(sprintf('Score = %.4f\nSpacing = %.4f', gridScore, gridSpacing))
    end
    axis off
    axis equal
    hold on    
end
saveas(figBatchAC,sprintf('autoCorrs_%s.pdf',splitHandlesUserDir{end}));

% --- Executes on button press in butt_border.
function butt_border_Callback(hObject, eventdata, handles)
% hObject    handle to butt_border (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% rate map settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)','Publication quality? (y/n)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.dBinWidth),'0','n'};
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
defaultanswer={'0.2',num2str(handles.dBinWidth),num2str(handles.dMinBins),'0.1'};
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
if border >= 0.5
    title(sprintf('T%d C%d\nBORDER = %.4f',handles.tetrode,handles.cluster,border),'fontweight','bold')
else
    title(sprintf('T%d C%d\nborder = %.4f',handles.tetrode,handles.cluster,border))
end
set(figBorder,'Name',handles.userDir,'Color','w');

guidata(hObject,handles);

% --- Executes on button press in butt_batchBorder.
function butt_batchBorder_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchBorder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cellMatrix = data.getCells;
numClusters = size(cellMatrix,1);

%% rate map settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)','Publication quality? (y/n)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.dBinWidth),'0','n'};
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
defaultanswer={'0.2',num2str(handles.dBinWidth),num2str(handles.dMinBins),'0.1'};
Answers4 = inputdlg(prompt,name,numlines,defaultanswer,'on');
if isempty(Answers4); return; end;
fieldThresh = str2double(Answers4{1});
binWidth = str2double(Answers4{2});
minBins = str2double(Answers4{3});
minPeak = str2double(Answers4{4});

%% calculate and plot
splitHandlesUserDir = regexp(handles.userDir,'\','split');
figBatchBorder = figure;
set(figBatchBorder,'Name',splitHandlesUserDir{end},'Color','w')
for iCluster = 1:numClusters
    spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
    map = analyses.map([handles.posT handles.posX handles.posY], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
    [fieldsMap, fields] = analyses.placefield(map,'threshold',fieldThresh,'binWidth',binWidth,'minBins',minBins,'minPeak',minPeak);
    border = analyses.borderScore(map.z, fieldsMap, fields);
    figure(figBatchBorder);
    plotSize = ceil(sqrt(numClusters));
    subplot(plotSize,plotSize,iCluster)
    colorMapBRK(map.z,'bar','on','pubQual',pubQual);
    if border >= 0.5
        title(sprintf('T%d C%d\nBORDER = %.3f',cellMatrix(iCluster,1),cellMatrix(iCluster,2),border),'fontweight','bold')
    else
        title(sprintf('T%d C%d\nborder = %.4f',cellMatrix(iCluster,1),cellMatrix(iCluster,2),border))
    end
    hold on
end

saveas(figBatchBorder,sprintf('borders_%s.pdf',splitHandlesUserDir{end}));

guidata(hObject,handles);

% --- Executes on button press in butt_waves.
function butt_waves_Callback(hObject, eventdata, handles)
% hObject    handle to butt_waves (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% h = msgbox('Loading waves...');
%% find field settings
prompt={'Do you want to align all the peaks?','Maximum number of waves to plot'};
name='Alignment';
numlines=1;
defaultanswer={'n','2000'};
Answers = inputdlg(prompt,name,numlines,defaultanswer,'on');
if isempty(Answers); return; end;
align = Answers{1};
waveLimit = str2double(Answers{2});

%% get all data points for cluster
nttFiles = dir('*.ntt');
for iTrode = 1:length(nttFiles)
    found = regexp(nttFiles(iTrode).name,sprintf('TT%d',handles.tetrode),'once');
    if ~isempty(found)
        ind = iTrode;
        break
    end
end
spikeFile = [handles.userDir,'\',nttFiles(ind).name];
if isempty(handles.trodeTS{handles.tetrode})
    [trodeTS] = Nlx2MatSpike(spikeFile,[1,0,0,0,0],0,1);     % open Nlx2MatSpike for help with arguments
    handles.trodeTS{handles.tetrode} = trodeTS;
else
    trodeTS = handles.trodeTS{handles.tetrode};
end
trodeTS_sec = trodeTS/1000000;
clusterTS = (handles.spikes)';
numSpikes = handles.totalSpikes;
clusterInds = zeros(1,numSpikes);
for iSpike = 1:(numSpikes)
    [~,ind] = min(abs(trodeTS_sec - clusterTS(iSpike)));
    clusterInds(1,iSpike) = ind;
end
[DataPoints,NlxHeader] = Nlx2MatSpike(spikeFile,[0,0,0,0,1],1,3,clusterInds);
ymin = (str2double(NlxHeader{strncmpi('-inputrange',NlxHeader,11)}(end-2:end)))*(-1);      % gets input range from header
ymax = str2double(NlxHeader{strncmpi('-inputrange',NlxHeader,11)}(end-2:end));

%% create figure
figWaves = figure;
set(figWaves,'Name',sprintf('T%d C%d',handles.tetrode,handles.cluster),'Color','w','position',get(0,'screensize'))
numWaves = numSpikes;
try
    load cutterColorsBRK
    clusterColor = cutterColorsBRK(handles.cluster+2,:);
catch
    clusterColor = [1 0 0];
end

%% calculate mean waves
meanWave = zeros(32,4);
for iChannel = 1:4
    meanWave(:,iChannel) = squeeze(mean(DataPoints(:,iChannel,:),3));
end

%% plot waves
subLocWaves = [1 2 6 7];
DataPointsAligned = nan(32,4,numWaves);
for iChannel = 1:4         % for each electrode
    subplot(2,5,subLocWaves(iChannel))
    if numWaves <= waveLimit
        for iWave = 1:numWaves
            voltages = squeeze(DataPoints(:,iChannel,iWave));
            if ~strcmpi(align,'n')
                %% peak alignment
                peakInd = find(voltages==max(voltages),1);
                shiftAmount = 8 - peakInd;
                alignedVoltages = circshift(voltages,shiftAmount);
                %% cutoff tail
                if shiftAmount < 0
                    alignedVoltages(end-abs(shiftAmount):end) = nan;
                end
                DataPointsAligned(1:32,iChannel,iWave) = alignedVoltages;
                patchline(1:32,alignedVoltages,'linestyle','-','edgecolor','k','linewidth',1,'edgealpha',0.1);
            else
                patchline(1:32,voltages,'linestyle','-','edgecolor','k','linewidth',1,'edgealpha',0.1);
            end
            hold on
        end
        if ~strcmpi(align,'n')
            %% peak-align mean waves as well
            for iTimepoint = 1:32
                meanWave(iTimepoint,iChannel) = nanmean(DataPointsAligned(iTimepoint,iChannel,:));
            end
        end
        %% plot mean wave and bring to front
        hMean = animatedline(1:32,meanWave(:,iChannel));
        set(hMean,'linestyle','-','color',clusterColor,'linewidth',2);
    else        % limit number of waves plotted
        waveCounter = 1;
        for iWave = 1:(numWaves/waveLimit):numWaves
            voltages = squeeze(DataPoints(:,iChannel,round(iWave)));
            if ~strcmpi(align,'n')
                %% peak alignment
                peakInd = find(voltages==max(voltages),1);
                shiftAmount = 8 - peakInd;
                alignedVoltages = circshift(voltages,shiftAmount);
                %% cutoff tail
                if shiftAmount < 0
                    alignedVoltages(end-abs(shiftAmount):end) = nan;
                end
                DataPointsAligned(1:32,iChannel,waveCounter) = alignedVoltages;
                patchline(1:32,alignedVoltages,'linestyle','-','edgecolor','k','linewidth',1,'edgealpha',0.1);
            else
                patchline(1:32,voltages,'linestyle','-','edgecolor','k','linewidth',1,'edgealpha',0.1);
            end
            hold on
            waveCounter = waveCounter + 1;
        end
        if ~strcmpi(align,'n')
            %% peak-align mean waves as well
            for iTimepoint = 1:32
                meanWave(iTimepoint,iChannel) = nanmean(DataPointsAligned(iTimepoint,iChannel,:));
            end
        end
        %% plot mean wave and bring to front
        hMean = animatedline(1:32,meanWave(:,iChannel));
        set(hMean,'linestyle','-','color',clusterColor,'linewidth',2);
    end
    axis([1,32,ymin*100,ymax*100]);
    axis square
    ylabel('Voltage (uV)')
    xlabel('Time (usec)')
    set(gca,'XTick',[1,8,16,24,32])
    set(gca,'XTickLabel',{'0','250','500','750','1000'})
end

guidata(hObject,handles);

%% calculate peaks
[DataPoints0] = Nlx2MatSpike(spikeFile,[0,0,0,0,1],0,1);  % open Nlx2MatSpike for help with arguments
numWaves0 = size(DataPoints0,3);
wavePeaks0 = zeros(4,numWaves0);
wavePeaks = zeros(4,numWaves);
for iChannel = 1:4
    wavePeaks0(iChannel,:) = squeeze(max(DataPoints0(:,iChannel,:),[],1));
    wavePeaks(iChannel,:) = squeeze(max(DataPoints(:,iChannel,:),[],1));
end

%% plot peaks
subLocPeaks = [3 4 5 8 9 10];
peakComps = [1 2; 1 3; 1 4; 2 3; 2 4; 3 4];
for iPeakPlot = 1:length(peakComps)
    subplot(2,5,subLocPeaks(iPeakPlot))
    hold on
    plot(wavePeaks0(peakComps(iPeakPlot,1),:),wavePeaks0(peakComps(iPeakPlot,2),:),'k.','markersize',1)
    plot(wavePeaks(peakComps(iPeakPlot,1),:),wavePeaks(peakComps(iPeakPlot,2),:),'.','color',clusterColor,'markersize',1)
    axis([0,ymax*100,0,ymax*100]);
    axis square
    xlabel(sprintf('Peak %d',peakComps(iPeakPlot,1)))
    ylabel(sprintf('Peak %d',peakComps(iPeakPlot,2)))
end

% --- Executes on button press in butt_autocorr.
function butt_autocorr_Callback(hObject, eventdata, handles)
% hObject    handle to butt_autocorr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% set parameters
cellMatrix = data.getCells;
numClusters = size(cellMatrix,1);
figAutocorr = figure;
set(figAutocorr,'color','white')
splitHandlesUserDir = regexp(handles.userDir,'\','split');
plotSize = ceil(sqrt(numClusters));
for iCluster = 1:numClusters
    subplot(plotSize,plotSize,iCluster)
    %% autocorrelation
    spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
    if length(spikes) >= 100
        [counts,centers,thetaInd] = thetaIndex(spikes);
        bar(centers,counts,'facecolor','k');
        xlabel('msec');
        ylabel('Count');
        if thetaInd >= 5
            title(sprintf('T%d C%d\ntheta = %.2f',cellMatrix(iCluster,1),cellMatrix(iCluster,2),thetaInd),'color','b');
        else
            title(sprintf('T%d C%d\ntheta = %.2f',cellMatrix(iCluster,1),cellMatrix(iCluster,2),thetaInd),'fontweight','normal');
        end
    else
        title(sprintf('T%d C%d',cellMatrix(iCluster,1),cellMatrix(iCluster,2)),'fontweight','normal');
    end
end

saveas(figAutocorr,sprintf('autocorrelations_%s.pdf',splitHandlesUserDir{end}));

% --- Executes on button press in butt_cellStats.
function butt_cellStats_Callback(hObject, eventdata, handles)
% hObject    handle to butt_cellStats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% prompt for settings
prompt={'Threshold for including surrounding bins (included if > thresh*peak)','Bin width (cm)','Minimum bins for a field','Minimum peak rate for a field (Hz?)'};
name='Find field settings';
numlines=1;
defaultanswer={'0.2',num2str(handles.dBinWidth),num2str(handles.dMinBins),'0.1'};
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

cellMatrix = data.getCells;
numClusters = size(cellMatrix,1);

%% prompt for settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)','Normalized threshold value used to search for peaks on the autocorrelogram (0:1)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.dBinWidth),'0','0.2'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});
gridThresh = str2double(Answers{4});
if gridThresh < 0 || gridThresh > 1
    gridThresh = 0.2;
    display('Grid threshold value out of range, using default 0.2.')
end

prompt={'Threshold for including surrounding bins (included if > thresh*peak)','Bin width (cm)','Minimum bins for a field','Minimum peak rate for a field (Hz?)'};
name='Find field settings';
numlines=1;
defaultanswer={'0.2',num2str(handles.dBinWidth),num2str(handles.dMinBins),'0.1'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
thresh = str2double(Answers{1});
binWidth = str2double(Answers{2});
minBins = str2double(Answers{3});
minPeak = str2double(Answers{4});

for iCluster = 1:numClusters
    figCheck = figure;
    set(figCheck,'name',sprintf('T%d C%d',cellMatrix(iCluster,1),cellMatrix(iCluster,2)))
      
    %% path plot
    subplot(321)
    spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
    spikePos = data.getSpikePositions(spikes,handles.posAve);
    pathTrialBRK('color',[.7 .7 .7])
    hold on
    plot(spikePos(:,2),spikePos(:,3),'r+','MarkerSize',3)
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
    title(sprintf('mean = %.4f Hz\npeak = %.4f Hz',meanRate,map.peakRate),'fontweight','normal','fontsize',10)
    hold on
    
    %% HD
    subplot(323)
    pos = data.getPositions('average','off','speedFilter',[2 0]);
    allHD = analyses.calcHeadDirection(pos);
    [~,spkInd] = data.getSpikePositions(spikes, handles.posAve);
    spkHDdeg = analyses.calcHeadDirection(pos(spkInd,:));
    tc = analyses.turningCurve(spkHDdeg, allHD, data.sampleTime);
    tcStat = analyses.tcStatistics(tc, 10, 20);
    circularTurningBRK(tc(:,2))
    axis equal
    title(sprintf('length = %.2f angle = %.2f',tcStat.r,tcStat.mean),'fontweight','normal','fontsize',10);
    
    %% grid
    subplot(324)
    autoCorr = analyses.autocorrelation(map.z);
    [score, stats] = analyses.gridnessScore(autoCorr, 'threshold', gridThresh);
    if ~isempty(stats.spacing)
        gridScore = score;
        gridSpacing = mean(stats.spacing);
    else
        gridScore = nan;
        gridSpacing = nan;
    end
    colorMapBRK(autoCorr);
    title(sprintf('Score = %.4f\nSpacing = %.4f', gridScore, gridSpacing),'fontweight','normal','fontsize',10)
    axis off
    axis equal
    hold on
    
    %% autocorrelation
    subplot(325)
    if length(spikes) >= 100
        [counts,centers,thetaInd] = thetaIndex(spikes);
        bar(centers,counts,'facecolor','k');
        xlabel('msec');
        ylabel('Count');
    else
        thetaInd = nan;
    end
    title(sprintf('theta = %.2f',thetaInd),'fontweight','normal');   
    
    %% spatial info
    [Info,spars,sel] = analyses.mapStatsPDF(map);
    
    %% border
    [fieldsMap, fields] = analyses.placefield(map,'threshold',thresh,'binWidth',binWidth,'minBins',minBins,'minPeak',minPeak);
    borderScore = analyses.borderScore(map.z, fieldsMap, fields);
    
    %% titles
    subplot(321)
    title(sprintf('info = %.4f\nborder = %.4f',Info.content,borderScore),'fontweight','normal','fontsize',10)
    subplot(326)
    if gridScore >= 0.3608
        text(0.5,1,'GRID','fontweight','bold','fontsize',10)
    end
    if borderScore >= 0.4416 && Info.content >= 0.6421
        text(0.5,0.75,'BORDER','fontweight','bold','fontsize',10)
    end
    if tcStat.r >= 0.2246
        text(0.5,0.5,'HD','fontweight','bold','fontsize',10)
    end
    if gridScore < 0.3608 && borderScore < 0.4416 && Info.content > 0.6421
        text(0.5,0.25,'SPATIAL','fontweight','bold','fontsize',10)
    end
    if thetaInd >= 5 
        text(0.5,0,'THETA','fontweight','bold','fontsize',10)
    end
    axis off

end

% --- Executes on button press in butt_emperor.
function butt_emperor_Callback(hObject, eventdata, handles)
% hObject    handle to butt_emperor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% external script for batching, can be used as standalone

emperorPenguin

% --- Executes on button press in butt_rateMapPDF.
function butt_rateMapPDF_Callback(hObject, eventdata, handles)
% hObject    handle to butt_rateMapPDF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

rateMapPDF

% --- Executes on button press in butt_HD_PDF.
function butt_HD_PDF_Callback(hObject, eventdata, handles)
% hObject    handle to butt_HD_PDF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

tuningCurvePDF

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

axis off

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
function edit_markersize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_markersize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


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



