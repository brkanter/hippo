
% Calculate and plot power spectrum over time for one animal. Used mainly
% to check for theta power in the LFP during screening.
%
%   USAGE
%       powerSpectrum
%
%   NOTES
%       This function only works if the directory naming scheme matches one
%       of the following two forms:
%
%       1) 2016-10-10_15-57-47_BK178
%       2) 2016-10-10_15-57-47_CML106
%
% Written by BRK 2015

function powerSpectrum

%% find relevant data
filePath = uigetdir('','Select any recording session from the animal of your choice');
splits = regexp(filePath,'\','split');
filePath0 = fullfile(splits{1:end-1});
ind = strfind(filePath,'BK');
if isempty(ind)
    ind2 = strfind(filePath,'CML');
    if isempty(ind2)
        return
    else
        correctMouseID = filePath(ind2:ind2+5);
    end
else
    correctMouseID = filePath(ind:ind+4);
end
myDir = dir(filePath0);
names = extractfield(myDir,'name');

%% find all session names and show 10 most recent
numSesh = 0;
for iFolder = 1:length(names)
    ind = strfind(names{iFolder},correctMouseID);
    if ~isempty(ind)
        numSesh = numSesh + 1;
        nameStore{numSesh} = names{iFolder};
    end
end
if numSesh > 10
    nameStore = nameStore(end-9:end);
    numSesh = 10;
    display('Warning! Only showing 10 most recent sessions.')
end

%% initialize
nData = 2000000;
nHz = floor(nData/2)+1;
nPower = 1000001;
h1 = figure;
set(gcf,'name',correctMouseID)
h2 = figure;
set(gcf,'name',correctMouseID)

%% do it
for iCSC = 1:4
    power = nan(numSesh,nPower);
    for iSession = 1:numSesh
        % get data and clean up
        fileEnding = sprintf('CSC%d.ncs',iCSC);
        filename = fullfile(splits{1:end-1},nameStore{iSession},fileEnding);
        [SampleFrequency,Samples,Header] = Nlx2MatCSC(filename,[0 0 1 0 1],1,1);
        squeezedSamples = reshape(Samples,512*size(Samples,2),1);
        for iRow = 1:length(Header)
            if ~isempty(strfind(Header{iRow},'ADBitVolts'))
                idx = iRow;
            end
        end
        [~,str] =strtok(Header{idx});
        scale = 1000000*str2num(str);
        squeezedSamples = squeezedSamples * scale;
        srate0 = SampleFrequency(1);
        rsrate = 500;
        resampled = resample(squeezedSamples,rsrate,srate0);
        ds = detrend(resampled);
        
        % FFT
        sineX = fft(ds,nData)/nData;
        hz = linspace(0.1,rsrate/2,nHz);
        hzBounds = dsearchn(hz',[1 15]');
        tempPower = 2*abs(sineX(1:length(hz)));
        tempPower = tempPower/max(tempPower);
        tempPower = general.smooth(tempPower,10);
        power(iSession,:) = tempPower;
    end
    
    %% heat maps for each recording session for each LFP channel
    figure(h1)
    subplot(2,2,iCSC)
    colormap jet
    imagesc(hz(hzBounds(1):hzBounds(2)),1:numSesh,power(:,hzBounds(1):hzBounds(2)))
    xlabel('Frequency'), ylabel('Session')
    title(fileEnding(1:end-4))
    
    %% line graphs for each recording session for each LFP channel
    % N.B. most recent session plotted on top
    figure(h2);
    subplot(2,2,iCSC)
    cmap = colormap('jet');
    cmap = cmap(round(linspace(1,length(cmap),numSesh)),:);
    set(gca,'colororder',cmap,'NextPlot','replacechildren')
    plot(hz(hzBounds(1):hzBounds(2)),power(:,hzBounds(1):hzBounds(2)))
    axis([1 15 0 nanmax(nanmax(power(:,hzBounds(1):hzBounds(2))))])
    xlabel('Frequency'), ylabel('Power')
    title(fileEnding(1:end-4))

end

% powerInds = dsearchn(hz',[4 8 16]');
% powerOther = mean([power(powerInds(1)),power(powerInds(3))]);
% powerTheta = power(powerInds(2));
% thetaRatio = powerTheta/powerOther