
% Calculate and plot power spectrum over time for one animal. Used mainly
% to check for theta power in the LFP during screening.
%
%   USAGE
%       plt.powerSpectrum(<CSCnums>)
%       CSCnums         (optional) vector specifying which CSC numbers to analyze (default = 
%
%   NOTES
%       This function works by searching directories for your mouse ID and may fail
%       if the directory structure or naming scheme is not as expected. See section
%       'check mouse names' below for more info.
%
% Written by BRK 2015

function powerSpectrum(CSCnums)

%% choose directory and CSC files
userDir = uigetdir();
if ~exist('CSCnums','var')
    CSCnums = 1:4;
end

%% find directory names
splits = regexp(userDir,'\','split');
filePath0 = fullfile(splits{1:end-1});
myDir = dir(filePath0);
names = extractfield(myDir,'name');

h = msgbox('Working ...');

%% check mouse names
if ~isempty(strfind(userDir,'BK'))
    ind = strfind(userDir,'BK');
    if length(ind) > 1; ind = ind(end); end;
    mouseName = userDir(ind:ind+4);
elseif ~isempty(strfind(userDir,'CML'))
    ind = strfind(userDir,'CML');
    if length(ind) > 1; ind = ind(end); end;
    mouseName = userDir(ind:ind+5);
elseif ~isempty(strfind(userDir,'KA'))
    ind = strfind(userDir,'KA');
    if length(ind) > 1; ind = ind(end); end;
    mouseName = userDir(ind:ind+2);
elseif ~isempty(strfind(userDir,'rat'))
    ind = strfind(userDir,'rat');
    if length(ind) > 1; ind = ind(end); end;
    mouseName = userDir(ind+3:end);
else
    prompt={'Mouse name'};
    name='Did not recognize mouse naming scheme';
    numlines=1;
    defaultanswer={'BK'};
    mouseName = inputdlg(prompt,name,numlines,defaultanswer,'on');
    if isempty(mouseName); return; end;
    mouseName = mouseName{1};
end

%% find all session names and show 10 most recent
numSesh = 0;
for iFolder = 1:length(names)
    ind = strfind(names{iFolder},mouseName);
    if ~isempty(ind)
        numSesh = numSesh + 1;
        nameStore{numSesh} = names{iFolder};
    end
end
if numSesh > 10
    nameStore = nameStore(end-9:end);
    numSesh = 10;
    display('Warning! Only showing 10 most recent sessions ...')
elseif ~numSesh
    error('Did not find any directories matching mouse name: %s',mouseName)
end

%% initialize
nData = 2000000;
nHz = floor(nData/2)+1;
nPower = 1000001;
h1 = figure;
set(gcf,'name',mouseName)
h2 = figure;
set(gcf,'name',mouseName)

%% do it
plotSize = ceil(sqrt(numel(CSCnums)));
for iCSC = CSCnums
    power = nan(numSesh,nPower);
    for iSession = 1:numSesh
        % get data and clean up
        fileEnding = sprintf('CSC%d.ncs',iCSC);
        filename = fullfile(splits{1:end-1},nameStore{iSession},fileEnding);
        try
            [SampleFrequency,Samples,Header] = Nlx2MatCSC(filename,[0 0 1 0 1],1,1);
        catch
            close(h);
            error('CSC loading failed. Check that selected CSC files actually exist')
        end
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
    subplot(plotSize,plotSize,find(CSCnums == iCSC))
    colormap jet
    imagesc(hz(hzBounds(1):hzBounds(2)),1:numSesh,power(:,hzBounds(1):hzBounds(2)))
    xlabel('Frequency'), ylabel('Session')
    title(fileEnding(1:end-4))
    
    %% line graphs for each recording session for each LFP channel
    % N.B. most recent session plotted on top
    figure(h2);
    subplot(plotSize,plotSize,find(CSCnums == iCSC))
    cmap = colormap('jet');
    cmap = cmap(round(linspace(1,length(cmap),numSesh)),:);
    set(gca,'colororder',cmap,'NextPlot','replacechildren')
    plot(hz(hzBounds(1):hzBounds(2)),power(:,hzBounds(1):hzBounds(2)))
    axis([1 15 0 nanmax(nanmax(power(:,hzBounds(1):hzBounds(2))))])
    xlabel('Frequency'), ylabel('Power')
    title(fileEnding(1:end-4))

end

close(h);

% powerInds = dsearchn(hz',[4 8 16]');
% powerOther = mean([power(powerInds(1)),power(powerInds(3))]);
% powerTheta = power(powerInds(2));
% thetaRatio = powerTheta/powerOther