
% Compute number of spikes in interspike interval.
%
%   USAGE
%       ISIout = calc.ISI(spikes, <PLOT>)
%       spikes      vector of spike times
%       PLOT        optional. 1 will plot the results, 0 will not (default)
%
%   OUTPUT
%       ISIout      number of spikes in ISI (2 msec)
%
%   SEE ALSO
%       calc.crossCorr
%
% Written by BRK 2017

function ISIout = ISI(spikes,PLOT)

%% check if we're plotting
if ~exist('PLOT','var')
    PLOT = 0;
end

%% parameters
epsilon = 1e-100;
nBins = 500;
maxLogISI = 3;
minLogISI = -3;
binsUsed = nan; H = nan;
ISI = diff(spikes) + epsilon;

%% compute
binsUsed = logspace(minLogISI,maxLogISI,nBins);
H = histcounts(ISI+eps,binsUsed);
ISIout = sum(ISI<0.002);

%% plot
if PLOT
    figure;
    plot(binsUsed(1:end-1),H,'-','color','b')
    hold on
    plot([0.001 0.001],get(gca,'yLim'),'r-',...
        [0.002 0.002],get(gca,'yLim'),'g-')
    xlabel('ISI (sec)');
    set(gca,'XScale','log','XLim',[10^minLogISI 10^maxLogISI]);
    if sum(ISI<0.002)>0
        text(min(get(gca,'xLim')),max(get(gca,'yLim')), ...
            sprintf(' %d ISIs<2ms',sum(ISI<0.002)), ...
            'VerticalAlignment','top','HorizontalAlignment','left');
    end        
    set(gca,'YTick',max(H));    
end
   


   