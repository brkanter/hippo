
% Compute theta index from single cell autocorrelation.
%
%   USAGE
%       [counts,centers,thetaInd] = thetaIndex(spikes)
%       spikes          vector of spike timestamps
%       
%   OUTPUT
%       counts          bin counts from histogram of autocorrelation
%       centers         bin centers from histogram of autocorrelation
%       thetaInd        ratio of theta-band (5-11 Hz) power to broadband (0-50 Hz) power
%
%   NOTES
%       Will not work well for small number of spikes (i.e. < 100).
%
% Written by BRK 2016

function [counts,centers,thetaInd] = thetaIndex(spikes)

%% binning
numBins = 101; % 10 msec
range = 500;   % +/- 500 msec

%% normalize spike times (start at 0, and sec to msec)
normSpikes = ((spikes - min(spikes))*1000)';
if length(normSpikes) > 4000
    normSpikes = normSpikes(1:4000);
end
numSpikes = length(normSpikes);

%% find spike times within desired range
triMat = ones(numSpikes,1)*normSpikes - normSpikes'*ones(1,numSpikes);                                  % make triangular matrix
triMatSqueeze = triMat(:);                                                                              % collapse into single column
withinRange = triMatSqueeze(triMatSqueeze >= -range & triMatSqueeze <= range & triMatSqueeze ~= 0);     % find values within range that aren't zero

%% histogram
[counts centers] = hist(withinRange,numBins);
% set zero-lag to max
zeroLag = round(numBins/2);
counts(zeroLag) = nanmax(counts([1:zeroLag-1,zeroLag+1:end]));    

%% FFT
rsrate = 500;
resampled = resample(counts,rsrate,numBins);
data = detrend(resampled);
nData = 500000;
nHz = floor(nData/2)+1;
sineX = fft(data,nData)/nData;
hz = linspace(0.1,rsrate/2,nHz);
tb = dsearchn(hz',[5 11]');
bb = dsearchn(hz',[0 50]');
% db = dsearchn(hz',[1 4]');
Power = 2*abs(sineX(1:length(hz)));
peakTheta = nanmax(Power(tb(1):tb(2)));
[~,peakThetaInd] = min(abs(Power-peakTheta));
length1Hz = round(nHz/(rsrate/2));
thetaPower = nanmean(Power(peakThetaInd-length1Hz:peakThetaInd+length1Hz));
bbPower = nanmean(Power(bb(1):bb(2)));
thetaInd = thetaPower/bbPower;


% Bin size of all the temporal autocorrelograms
% was 10 ms (other bin sizes were tested and yielded similar results). The autocorrelogram
% was computed for ± 500-ms lags, and the peak of the autocorrelogram at zero lag was
% equalized to the maximal value not including the zero-lag peak13,14 (Fig. 4f and
% Supplementary Fig. 15). The power spectrum of the temporal autocorrelograms was
% assessed by computing the fast Fourier transform (FFT) of the autocorrelogram, and
% calculating the square of the FFT magnitude; the length of the FFT was zero padded to
% 2e16. The power spectrum was smoothed with a 2-Hz rectangular window, and the peak
% value in the 5-11 Hz band was identified. Two methods were used to assess whether a
% neuron was theta modulated. Method 1: A neuron was defined as theta-modulated if the
% mean power within 1-Hz of each side of the peak in the 5–11 Hz frequency range was at
% least 5 times greater than the mean spectral power between 0 Hz and 50 Hz (Fig. 4h, red
% line) – similar to the 'theta index' used in rat MEC recordings to identify theta modulation
% of grid-cells

