
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
    plot(binsUsed(1:end-1),H,'-','color','b')
    hold on
    plot([0.001 0.001],get(gca,'yLim'),'r-',...
        [0.002 0.002],get(gca,'yLim'),'g-')
    xlabel('ISI (sec)');
    set(gca,'XScale','log','XLim',[10^minLogISI 10^maxLogISI]);
    if sum(ISI<0.002)>0
        t = text(max(get(gca,'xLim')),max(get(gca,'yLim')), ...
            sprintf('%d within 2 ms (%1.1f%%)',sum(ISI<0.002),(sum(ISI<0.002)/numel(spikes))*100), ...
            'VerticalAlignment','top','HorizontalAlignment','right','fontweight','bold','backgroundcolor','w','edgecolor','k');
        if (sum(ISI<0.002)/numel(spikes))*100 > 2
            set(t,'color','red')
        end
    else
        text(max(get(gca,'xLim')),max(get(gca,'yLim')), ...
            'CLEAN', ...
            'VerticalAlignment','top','HorizontalAlignment','right', ...
            'fontweight','bold','backgroundcolor','w','edgecolor','k','color','b');
    end        
    set(gca,'YTick',max(H));    
end
   


   