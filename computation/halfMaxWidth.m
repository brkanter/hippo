
% Calculate width at the half maximum of a waveform.
%
%   USAGE
%       spikeWidth = halfMaxWidth(userDir,tetrode,spikes)
%       userDir        directory of recording session
%       tetrode        tetrode number
%       spikes         list of spike timestamps
%
%   OUTPUT
%       spikeWidth     width at half max
%
%   SEE ALSO
%       penguin emperorPenguin emperorPenguinUpdate
%
% Written by BRK 2014

function spikeWidth = halfMaxWidth(userDir, tetrode, spikes)

%% load data
nttFiles = dir('*.ntt');
for iTrode = 1:length(nttFiles)
    found = regexp(nttFiles(iTrode).name,sprintf('TT%d',tetrode),'once');
    if ~isempty(found)
        ind = iTrode;
    end
end
spikeFile = [userDir,'\',nttFiles(ind).name];
[trodeTS] = Nlx2MatSpike(spikeFile,[1,0,0,0,0],0,1);     % open Nlx2MatSpike for help with arguments
trodeTS_sec = (trodeTS/1000000)';
clusterTS = spikes;
clusterInds = knnsearch(trodeTS_sec,clusterTS);
[DataPoints] = Nlx2MatSpike(spikeFile,[0,0,0,0,1],0,3,clusterInds);
DataPoints = DataPoints/100;        % convert to microvolts

%% calculate mean waves
meanWave = zeros(32,4);
for iChannel = 1:4
    meanWave(:,iChannel) = squeeze(mean(DataPoints(:,iChannel,:),3));
end

for iChannel = 1:4
    peaks(iChannel) = max(max(meanWave(:,iChannel)));
end
[maxPeak, maxPeakIdx] = max(peaks);
halfMax = maxPeak / 2;

%% interpolate
interpWave = interp1(1:32,meanWave(:,maxPeakIdx),1:0.01:32,'spline');
interpMaxIdx = find(interpWave == maxPeak);
Diff = sort(abs(halfMax - interpWave(1:interpMaxIdx))); 
Diff2 = sort(abs(halfMax - interpWave(interpMaxIdx+1:end)));
closest = find(abs(halfMax - interpWave) == Diff(1));
closest2 = find(abs(halfMax - interpWave) == Diff2(1));
spikeWidth = abs(closest - closest2) * (1/3101) * 1000;

