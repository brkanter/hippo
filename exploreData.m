function exploreData

global penguinInput arena clusterFormat

folder = uigetdir();
cd(folder)
writeInputBNT(penguinInput,folder,arena,clusterFormat)
data.loadSessions(penguinInput)

figure;
hold on
pathTrialBRK('color',[.5 .5 .5])
axis off

clusterList = data.getCells;
display(clusterList)

% cmap = colormap('jet');
% cmap = cmap(round(linspace(1,64,size(clusterList,1))),:);
% p = data.getPositions;
% for i = 1:size(clusterList,1)
%     sp = data.getSpikePositions(data.getSpikeTimes(clusterList(i,:)),p);
%     plot(sp(:,2),sp(:,3),'.','color',cmap(i,:),'markersize',30)
% end
% colormap(cmap)
% colorbar('Ticks',linspace(0,1,size(clusterList,1)),'TickLabels',num2str(clusterList))