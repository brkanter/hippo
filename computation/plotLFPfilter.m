
% Plot broadband LFP trace, optionally adding theta- and ripple-band filtered traces.
%
%   USAGE
%       plotLFP(<options>)
%       <options>       'theta' and/or 'ripple' will add these filtered traces
%
%   NOTES
%       Theta- and ripple-band traces are plotted with their voltages offset so that they can be
%       visualized in the same figure window.
%
%   SEE ALSO
%       plotLFP
%
% Written by BRK 2017

function plotLFPfilter(varargin)

%% check inputs
for iArg = 1:length(varargin)
   if ~helpers.isstring(varargin{iArg},'theta','ripple') 
       error('Expected input arguments ''theta'' and/or ''ripple''')
   end
end

%% select and load LFP
[name,path] = uigetfile('*.ncs','Select CSC file');
filename = fullfile(path,name);

display('Loading CSC file...')
[TimeStamps,SampleFrequency,Samples,Header] = Nlx2MatCSC(filename,[1 0 1 0 1],1,1);
squeezedSamples = reshape(Samples,512*size(Samples,2),1);   

% scale to microvolts
display('Scaling voltages...')
for iRow = 1:length(Header)
    if ~isempty(strfind(Header{iRow},'ADBitVolts'))
        idx = iRow;
    end
end
[~,str] = strtok(Header{idx});
scale = 1000000*str2num(str);
squeezedSamples = squeezedSamples * scale;

% downsample to save time
display('Resampling and detrending...')
srate0 = SampleFrequency(1);
rsrate = 1000;   % 1 kHz
resampled = resample(squeezedSamples,rsrate,srate0);

% detrend to correct DC shifts
dt_resampled = detrend(resampled);

%% plot broadband signal
xVals = linspace(0,length(dt_resampled)/rsrate,length(dt_resampled));   % convert to secs

figure('position',[9 583 1900 494],'name',filename)
hold on
plot(xVals,dt_resampled,'k')
xlabel 'Time (sec)'
ylabel 'Voltage (uV)'

%% theta filter (4-12 Hz)
if sum(strcmpi('theta',varargin))
    display('Theta filter...')
    [b a] = butter(2,[4/(rsrate/2) 12/(rsrate/2)],'bandpass');
    filt_theta = filter(b,a,dt_resampled);
    offset = max(abs(dt_resampled));
    plot(xVals,filt_theta - offset,'b')
end

%% ripple filter (100-400 Hz)
if sum(strcmpi('ripple',varargin))
    display('Ripple filter...')
    [b a] = butter(2,[100/(rsrate/2) 400/(rsrate/2)],'bandpass');
    filt_ripple = filter(b,a,dt_resampled);
    if ~exist('offset','var')
        offset = max(abs(dt_resampled));
    end
    plot(xVals,filt_ripple + offset,'r')
end

%% legend
if length(varargin) == 2
    [~,icons] = legend({'Broadband','Theta','Ripple'},'orientation','horizontal','location','northoutside','box','off');
elseif sum(strcmpi('theta',varargin))
    [~,icons] = legend({'Broadband','Theta'},'orientation','horizontal','location','northoutside','box','off');
elseif sum(strcmpi('ripple',varargin))
    [~,icons] = legend({'Broadband','Ripple'},'orientation','horizontal','location','northoutside','box','off');
end
if exist('icons','var')
    set(findobj(icons,'type','line'),'linew',3)
end

display('Done.')
keyboardnavigate   % this lets you scroll with the arrow keys (when not in zoom/pan/edit modes)
