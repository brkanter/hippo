
% Compute theta index from LFP.
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

function thetaInd = thetaIndexLFP(folder,tetrode)

%% get data
filename = [folder '\' sprintf('CSC%s.ncs',num2str(tetrode))];
cd(folder)
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

%% resample and detrend
srate0 = SampleFrequency(1);
rsrate = 500;
resampled = resample(squeezedSamples,rsrate,srate0);
ds = detrend(resampled);

%% FFT
nData = 2000000;
nHz = floor(nData/2)+1;
sineX = fft(ds,nData)/nData;
hz = linspace(0.1,rsrate/2,nHz);
tb = dsearchn(hz',[5 11]');
bb = dsearchn(hz',[0 50]');
db = dsearchn(hz',[1 4]');
Power = 2*abs(sineX(1:length(hz)));
% plot(hz,Power)
% xlim([0 20])

%% theta index
peakTheta = nanmax(Power(tb(1):tb(2)));
[~,peakThetaInd] = nanmin(abs(Power-peakTheta));
length1Hz = round(nHz/(rsrate/2));
thetaPower = nanmean(Power(peakThetaInd-length1Hz:peakThetaInd+length1Hz));
bbPower = nanmean(Power(bb(1):bb(2)));
dbPower = nanmean(Power(db(1):db(2)));
thetaInd = thetaPower/bbPower;
thetaDelta = thetaPower/dbPower;

