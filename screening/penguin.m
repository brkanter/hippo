
% penguin: GUI for neurobiological analysis of spatial behavior.
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

% Last Modified by GUIDE v2.5 02-Dec-2016 14:52:16

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
    pathTrialBRK('color',[.5 .5 .5])
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
pathTrialBRK('color',[.5 .5 .5])
set(gca,'color',[.8 .8 .8],'xcolor',[.8 .8 .8],'ycolor',[.8 .8 .8],'box','off','buttondownfcn',@axes1_ButtonDownFcn)
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
pathTrialBRK('color',[.5 .5 .5])
set(gca,'color',[.8 .8 .8],'xcolor',[.8 .8 .8],'ycolor',[.8 .8 .8],'box','off','buttondownfcn',@axes1_ButtonDownFcn)
axis equal

guidata(hObject,handles);

% --- Executes on button press in butt_spikepathplot.
function butt_spikepathplot_Callback(hObject, eventdata, handles)
% hObject    handle to butt_spikepathplot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

pathTrialBRK('color',[.5 .5 .5])
axis equal
hold on
plot(handles.spikePos(:,2),handles.spikePos(:,3),'r+','MarkerSize',handles.Marker)
hold off
set(gca,'color',[.8 .8 .8],'xcolor',[.8 .8 .8],'ycolor',[.8 .8 .8],'box','off','buttondownfcn',@axes1_ButtonDownFcn)

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
pathTrialBRK('color',[.5 .5 .5])
axis equal
hold on
plot(handles.spikePos(:,2),handles.spikePos(:,3),'r+','MarkerSize',handles.Marker)
hold off
set(gca,'color',[.8 .8 .8],'xcolor',[.8 .8 .8],'ycolor',[.8 .8 .8],'box','off','buttondownfcn',@axes1_ButtonDownFcn)

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
    pathTrialBRK('color',[.5 .5 .5])
    hold on
    %% overlay spikes
    plot(spikePos(:,2),spikePos(:,3),'r+','MarkerSize',Marker)
    title(sprintf('T%d C%d',cellMatrix(iCluster,1),cellMatrix(iCluster,2)))
    axis off;
    axis equal;
    hold off
end

saveas(figBatchSPP,fullfile(handles.userDir,sprintf('SPPs_%s.pdf',splitHandlesUserDir{end})));

% --- Executes on button press in butt_ratemap.
function butt_ratemap_Callback(hObject, eventdata, handles)
% hObject    handle to butt_ratemap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

map = analyses.map([handles.posT handles.posX handles.posY],handles.spikes,'smooth',handles.dSmoothing,'binWidth',handles.dBinWidth,'limits',handles.mapLimits);
colorMapBRK(map.z);
axis on
set(gca,'color',[.8 .8 .8],'xcolor',[.8 .8 .8],'ycolor',[.8 .8 .8],'box','off','buttondownfcn',@axes1_ButtonDownFcn)
guidata(hObject,handles);

% --- Executes on button press in butt_batchRM.
function butt_batchRM_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cellMatrix = data.getCells;
numClusters = size(cellMatrix,1);

%% prompt for settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.dBinWidth),'0','n','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});

%% calculate and plot
splitHandlesUserDir = regexp(handles.userDir,'\','split');
figBatchRM = figure;
set(figBatchRM,'Name',splitHandlesUserDir{end})
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
    colorMapBRK(map.z,'bar','on');
    title(sprintf('T%d C%d\nmean = %.2f Hz\npeak = %.2f Hz',cellMatrix(iCluster,1),cellMatrix(iCluster,2),meanRate,map.peakRate),'fontweight','normal','fontsize',10)
    hold on
end
saveas(figBatchRM,fullfile(handles.userDir,sprintf('rateMaps_%s.pdf',splitHandlesUserDir{end})));

% --- Executes on button press in butt_findFields.
function butt_findFields_Callback(hObject, eventdata, handles)
% hObject    handle to butt_findFields (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[fieldMap,fields] = analyses.placefield(handles.map,'minBins',handles.dMinBins);
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
h = plot(fields(1,mainField).peakX,fields(1,mainField).peakY,'o','markerfacecolor','m','markeredgecolor','w','linewidth',2,'markersize',15);
set(h,'hittest','off')
hold off
axis on

% --- Executes on button press in butt_batchFindFields.
function butt_batchFindFields_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchFindFields (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cellMatrix = data.getCells;
numClusters = size(cellMatrix,1);

%% prompt for settings
prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.dBinWidth),'0','n','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});

prompt={'Threshold for including surrounding bins (included if > thresh*peak)','Bin width (cm)', ...
    'Minimum bins for a field','Minimum peak rate for a field (Hz?)','Display rates (y/n)'};
name='Find field settings';
numlines=1;
defaultanswer={'0.2',num2str(handles.dBinWidth),num2str(handles.dMinBins),'1','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
thresh = str2double(Answers{1});
binWidth = str2double(Answers{2});
minBins = str2double(Answers{3});
minPeak = str2double(Answers{4});
displayRates = Answers{5};

%% calculate and plot
splitHandlesUserDir = regexp(handles.userDir,'\','split');
figBatchFF = figure;
hold on
set(figBatchFF,'Name',splitHandlesUserDir{end})
plotSize = ceil(sqrt(numClusters));
for iCluster = 1:numClusters
    subplot(plotSize,plotSize,iCluster)
    spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
    map = analyses.map([handles.posT handles.posX handles.posY], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
    [fieldMap,fields] = analyses.placefield(map,'threshold',thresh,'binWidth',binWidth,'minBins',minBins,'minPeak',minPeak);
    fieldMap(isnan(map.z)) = nan;
    if isempty(fields)
        colorMapBRK(zeros(30));
        colormap(gca,[1 1 1])
        title(sprintf('T%d C%d',cellMatrix(iCluster,1),cellMatrix(iCluster,2)),'fontweight','normal','fontsize',10)
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
    
    % display peak rates or just main peak
    if strcmpi(displayRates,'y')
        for iFieldNum = 1:size(fields,2)
            text(fields(1,iFieldNum).peakX,fields(1,iFieldNum).peakY,sprintf('%.2f',peakRates(iFieldNum)),'horizontalalignment','center')
        end
    else
        plot(fields(1,mainField).peakX,fields(1,mainField).peakY,'o','markerfacecolor','m','markeredgecolor','w','linewidth',2,'markersize',10);
    end
    title(sprintf('T%d C%d',cellMatrix(iCluster,1),cellMatrix(iCluster,2)),'fontweight','normal','fontsize',10)
    hold off
    
end
saveas(figBatchFF,fullfile(handles.userDir,sprintf('findFields_%s.pdf',splitHandlesUserDir{end})));

% --- Executes on button press in butt_timeDivRM.
function butt_timeDivRM_Callback(hObject, eventdata, handles)
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
prompt={'Number of time blocks','Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)'};
name='Settings';
numlines=1;
defaultanswer={'2','2',num2str(handles.dBinWidth),'0','n'};
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
    colorMapBRK(map.z,'bar','on');
    title(sprintf('%.2f',meanRateMat(1,iBlock)))
    hold on
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
cellMatrix = data.getCells;
numClusters = size(cellMatrix,1);
posAve = data.getPositions('speedFilter',[2 0]);
times = posAve(:,1);
numTimeStamps = length(times);

%% prompt for settings
prompt={'Number of time blocks','Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)','Publication quality? (y/n)'};
name='Settings';
numlines=1;
defaultanswer={'2','2',num2str(handles.dBinWidth),'0','n'};
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
        mapMat{iCluster,iBlock} = map.z;
        meanRateMat(iCluster,iBlock) = analyses.meanRate(spikesStruct(iBlock).s,[spikesStruct(iBlock).t spikesStruct(iBlock).x spikesStruct(iBlock).y]);
        subplot(ceil(sqrt(numBlocks)),ceil(sqrt(numBlocks)),iBlock)
        colorMapBRK(map.z,'bar','on','pubQual',pubQual);
        title(sprintf('%.2f',meanRateMat(iCluster,iBlock)))
        hold on
    end
end
figure;
numMaps = 1:1:numBlocks;
combo = nchoosek(numMaps,2);
for iCluster = 1:numClusters
    nametag = sprintf('T%dC%d',cellMatrix(iCluster,1),cellMatrix(iCluster,2));
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
pos = data.getPositions('average','off','speedFilter',[2 0]);
[~,spkInd] = data.getSpikePositions(handles.spikes, handles.posAve);
spkHDdeg = analyses.calcHeadDirection(pos(spkInd,:));
allHD = analyses.calcHeadDirection(pos);
tc = analyses.turningCurve(spkHDdeg, allHD, data.sampleTime,'binWidth',6);
tcStat = analyses.tcStatistics(tc,6,20);
figure;
circularTurningBRK(tc(:,2))
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
saveas(figBatchHD,fullfile(handles.userDir,sprintf('HDplots_%s.pdf',splitHandlesUserDir{end})));

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
    title(sprintf('Score = %.2f\nSpacing = %.2f', gridScore, gridSpacing),'fontsize',14)
end
set(ACfig, 'Name', handles.userDir)
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
set(figBatchAC,'Name',splitHandlesUserDir{end})
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
        title(sprintf('Score = %.2f\nSpacing = %.2f', gridScore, gridSpacing))
    end
    axis off
    axis equal
    hold on
end
saveas(figBatchAC,fullfile(handles.userDir,sprintf('autoCorrs_%s.pdf',splitHandlesUserDir{end})));

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
defaultanswer={'0.2',num2str(handles.dBinWidth),num2str(handles.dMinBins),'1'};
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
    title(sprintf('T%d C%d\nBORDER = %.2f',handles.tetrode,handles.cluster,border),'fontweight','bold')
else
    title(sprintf('T%d C%d\nborder = %.2f',handles.tetrode,handles.cluster,border))
end
set(figBorder,'Name',handles.userDir);

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
defaultanswer={'0.2',num2str(handles.dBinWidth),num2str(handles.dMinBins),'1'};
Answers4 = inputdlg(prompt,name,numlines,defaultanswer,'on');
if isempty(Answers4); return; end;
fieldThresh = str2double(Answers4{1});
binWidth = str2double(Answers4{2});
minBins = str2double(Answers4{3});
minPeak = str2double(Answers4{4});

%% calculate and plot
splitHandlesUserDir = regexp(handles.userDir,'\','split');
figBatchBorder = figure;
set(figBatchBorder,'Name',splitHandlesUserDir{end})
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
        title(sprintf('T%d C%d\nborder = %.2f',cellMatrix(iCluster,1),cellMatrix(iCluster,2),border))
    end
    hold on
end

saveas(figBatchBorder,fullfile(handles.userDir,sprintf('borders_%s.pdf',splitHandlesUserDir{end})));

guidata(hObject,handles);

% --- Executes on button press in butt_waves.
function butt_waves_Callback(hObject, eventdata, handles)
% hObject    handle to butt_waves (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% h = msgbox('Loading waves...');
%% find field settings
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
if isempty(handles.trodeTS{handles.tetrode})
    [trodeTS] = Nlx2MatSpike(spikeFile,[1,0,0,0,0],0,1);     % open Nlx2MatSpike for help with arguments
    handles.trodeTS{handles.tetrode} = trodeTS;
else
    trodeTS = handles.trodeTS{handles.tetrode};
end
trodeTS_sec = (trodeTS/1000000)';
clusterTS = handles.spikes;
clusterInds = knnsearch(trodeTS_sec,clusterTS);
[DataPoints,NlxHeader] = Nlx2MatSpike(spikeFile,[0,0,0,0,1],1,3,clusterInds);
ymin = (str2double(NlxHeader{strncmpi('-inputrange',NlxHeader,11)}(end-2:end)))*(-1);      % gets input range from header
ymax = str2double(NlxHeader{strncmpi('-inputrange',NlxHeader,11)}(end-2:end));

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

%% calculate mean waves
meanWave = zeros(32,4);
for iChannel = 1:4
    meanWave(:,iChannel) = squeeze(mean(DataPoints(:,iChannel,:),3));
end

%% plot waves
subLocWaves = [1 2 6 7];
% DataPointsAligned = nan(32,4,numWaves);
for iChannel = 1:4         % for each electrode
    subplot(2,5,subLocWaves(iChannel))
    if ~strcmpi(align,'n')
        %% peak alignment
        voltages = squeeze(DataPoints(:,iChannel,:));
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
        patchline(meshgrid(1:32,1:numWaves)',alignedVoltages,'linestyle','-','edgecolor','k','linewidth',1,'edgealpha',0.1);
        %% peak-align mean waves as well
        meanWave(:,iChannel) = nanmean(alignedVoltages,2);
    else
        patchline(meshgrid(1:32,1:numWaves)',squeeze(DataPoints(:,iChannel,:)),'linestyle','-','edgecolor','k','linewidth',1,'edgealpha',0.1);
    end
    %% plot mean wave and bring to front
    hMean = animatedline(1:32,meanWave(:,iChannel));
    set(hMean,'linestyle','-','color',clusterColor,'linewidth',2);
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

figure('name',sprintf('T%dC%d',handles.tetrode,handles.cluster));
spikes = handles.spikes;
if length(spikes) >= 100
    [counts,centers,thetaInd] = thetaIndex(spikes);
    bar(centers,counts,'facecolor','k');
    xlabel('msec');
    ylabel('Count');
    if thetaInd >= 5
        title(sprintf('theta = %.2f',thetaInd),'color','b');
    else
        title(sprintf('theta = %.2f',thetaInd),'fontweight','normal');
    end
end

% --- Executes on button press in butt_batchAutocorr.
function butt_batchAutocorr_Callback(hObject, eventdata, handles)
% hObject    handle to butt_batchAutocorr (see GCBO)
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

saveas(figAutocorr,fullfile(handles.userDir,sprintf('autocorrelations_%s.pdf',splitHandlesUserDir{end})));

% --- Executes on button press in butt_cellStats.
function butt_cellStats_Callback(hObject, eventdata, handles)
% hObject    handle to butt_cellStats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% prompt for settings
prompt={'Threshold for including surrounding bins (included if > thresh*peak)','Bin width (cm)','Minimum bins for a field','Minimum peak rate for a field (Hz?)'};
name='Find field settings';
numlines=1;
defaultanswer={'0.2',num2str(handles.dBinWidth),num2str(handles.dMinBins),'1'};
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
defaultanswer={'0.2',num2str(handles.dBinWidth),num2str(handles.dMinBins),'1'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
thresh = str2double(Answers{1});
binWidth = str2double(Answers{2});
minBins = str2double(Answers{3});
minPeak = str2double(Answers{4});

for iCluster = 1:numClusters
    figCheck = figure;
    set(figCheck,'name',sprintf('T%d C%d',cellMatrix(iCluster,1),cellMatrix(iCluster,2)))
    try
        %% path plot
        subplot(321)
        spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
        spikePos = data.getSpikePositions(spikes,handles.posAve);
        pathTrialBRK('color',[.5 .5 .5])
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
        title(sprintf('mean = %.2f Hz\npeak = %.2f Hz',meanRate,map.peakRate),'fontweight','normal','fontsize',10)
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
        title(sprintf('Score = %.2f\nSpacing = %.2f', gridScore, gridSpacing),'fontweight','normal','fontsize',10)
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
    end
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
    warndlg('No object map found')
    return
end

prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.dBinWidth),'0','n','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});
map = analyses.map([handles.posT handles.posX handles.posY], handles.spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime,'limits',handles.mapLimits);
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

figure('name',sprintf('T%dC%d',handles.tetrode,handles.cluster));
subplot(221)
colorMapBRK(rateMap,'bar','on');
subplot(223)
axis off
text(0,1,'Rate ratio object 1:')
text(0,0.75,'Rate ratio object 2:')
text(0,0.5,'P val object 1:')
text(0,0.25,'P val object 2:')
text(0,0,'P val all objects:')
values = [nanmean(objResponsesRateIncrease(1,:)) ...
    nanmean(objResponsesRateIncrease(2,:)) ...
    nanmean(objResponsesRatePval(1,:)) ...
    nanmean(objResponsesRatePval(2,:)) ...
    nanmean(objResponsesRatePval(3,:))];
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

subplot(222)
colorMapBRK(occupancyMap,'bar','on');
subplot(224)
axis off
text(0,1,'Time ratio object 1:')
text(0,0.75,'Time ratio object 2:')
text(0,0.5,'P val object 1:')
text(0,0.25,'P val object 2:')
text(0,0,'P val all objects:')
values = [nanmean(objResponsesTimeIncrease(1,:)) ...
    nanmean(objResponsesTimeIncrease(2,:)) ...
    nanmean(objResponsesTimePval(1,:)) ...
    nanmean(objResponsesTimePval(2,:)) ...
    nanmean(objResponsesTimePval(3,:))];
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
    warndlg('No object map found')
    return
end

prompt={'Smoothing (# of bins)','Spatial bin width (cm)','Minimum occupancy (s)'};
name='Settings';
numlines=1;
defaultanswer={'2',num2str(handles.dBinWidth),'0','n','n'};
Answers = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(Answers); return; end;
smooth = str2double(Answers{1});
binWidth = str2double(Answers{2});
minTime = str2double(Answers{3});

cellMatrix = data.getCells;
numClusters = size(cellMatrix,1);

for iCluster = 1:numClusters
    spikes = data.getSpikeTimes(cellMatrix(iCluster,:));
    map = analyses.map([handles.posT handles.posX handles.posY], spikes, 'smooth', smooth, 'binWidth', binWidth, 'minTime', minTime, 'limits', handles.mapLimits);
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
    
    figure('name',sprintf('T%dC%d',cellMatrix(iCluster,1),cellMatrix(iCluster,2)));
    subplot(211)
    colorMapBRK(rateMap,'bar','on');
    subplot(212)
    axis off
    text(0,1,'Rate ratio object 1:')
    text(0,0.75,'Rate ratio object 2:')
    text(0,0.5,'P val object 1:')
    text(0,0.25,'P val object 2:')
    text(0,0,'P val all objects:')
    values = [nanmean(objResponsesRateIncrease(1,:)) ...
        nanmean(objResponsesRateIncrease(2,:)) ...
        nanmean(objResponsesRatePval(1,:)) ...
        nanmean(objResponsesRatePval(2,:)) ...
        nanmean(objResponsesRatePval(3,:))];
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

figure('name',handles.userDir);
subplot(211)
colorMapBRK(occupancyMap,'bar','on');
subplot(212)
axis off
text(0,1,'Time ratio object 1:')
text(0,0.75,'Time ratio object 2:')
text(0,0.5,'P val object 1:')
text(0,0.25,'P val object 2:')
text(0,0,'P val all objects:')
values = [nanmean(objResponsesTimeIncrease(1,:)) ...
    nanmean(objResponsesTimeIncrease(2,:)) ...
    nanmean(objResponsesTimePval(1,:)) ...
    nanmean(objResponsesTimePval(2,:)) ...
    nanmean(objResponsesTimePval(3,:))];
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

% --- Executes on button press in butt_emperor.
function butt_emperor_Callback(hObject, eventdata, handles)
% hObject    handle to butt_emperor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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
    fieldMap = analyses.placefield(handles.map,'minBins',handles.dMinBins);
    fieldMap(isnan(handles.map)) = nan;
    if ~sum(sum(fieldMap == 0))
        cmap(2,:) = get(gca,'color');
    end
    colormap(gca,cmap)
    caxis([-1 8])
end

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


