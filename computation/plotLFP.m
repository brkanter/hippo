
% Plot broadband LFP trace(s). If multiple channels are selected, they are plotted in the same figure window.
%
%   USAGE
%       plotLFP
%
%   NOTES
%       Multiple traces are plotted with their voltages offset so that they can be
%       visualized in the same figure window.
%
%   SEE ALSO
%       plotLFPfilter
%
% Written by BRK 2017

function plotLFP

%% select trace(s)
[name,path] = uigetfile('*.ncs','Select CSC file(s)','multiselect','on');
if iscell(name)
    numTraces = length(name);
else
    numTraces = 1;
end

%% prepare figure and colors
figure('position',[9 583 1900 494],'name',path)
hold on
xlabel 'Time (sec)'
ylabel 'Voltage (uV)'
cmap = colormap('parula');
cmap = cmap(round(linspace(1,50,numTraces)),:);
    
%% load trace(s)
for iTrace = 1:numTraces
    
    if numTraces > 1
        filename = fullfile(path,name{iTrace});
    else
        filename = fullfile(path,name);
    end
    
    display(sprintf('Loading trace %d of %d...',iTrace,numTraces))
    [TimeStamps,SampleFrequency,Samples,Header] = Nlx2MatCSC(filename,[1 0 1 0 1],1,1);
    squeezedSamples = reshape(Samples,512*size(Samples,2),1);
    
    % scale to microvolts
    if iTrace == 1
        for iRow = 1:length(Header)
            if ~isempty(strfind(Header{iRow},'ADBitVolts'))
                idx = iRow;
            end
        end
        [~,str] = strtok(Header{idx});
        scale = 1000000*str2num(str);
    end
    squeezedSamples = squeezedSamples * scale;
    
    % downsample to save time
    srate0 = SampleFrequency(1);
    rsrate = 1000;   % 1 kHz
    resampled = resample(squeezedSamples,rsrate,srate0);
    
    % detrend to correct DC shifts
    dt_resampled = detrend(resampled);
    
    %% plot broadband signal
    if iTrace == 1
        xVals = linspace(0,length(dt_resampled)/rsrate,length(dt_resampled));   % convert to secs
        if numTraces > 1
            plot(xVals,dt_resampled,'color',cmap(iTrace,:))
            offset = max(abs(dt_resampled));
        else
            plot(xVals,dt_resampled,'k')
        end
    else
        plot(xVals,dt_resampled - (offset * (iTrace-1)),'color',cmap(iTrace,:))
    end
    drawnow
    
end

%% legend
[~,icons] = legend(name,'location','eastoutside','box','off');
set(findobj(icons,'type','line'),'linew',3)

display('Done.')
keyboardnavigate   % this lets you scroll with the arrow keys (when not in zoom/pan/edit modes)
