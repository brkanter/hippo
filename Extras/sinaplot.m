function sinaplot(X)

% X is a m-by-p matrix with maximum m samples and p groups
% X can contain NaNs
% Sebastien  De Landtsheer November 2018
% sebdelandtsheer@gmail.com

tmp = nan(50000,length(X));
for i = 1:size(tmp,2)
    tmp(1:length(X{i}),i) = X{i};
end
tmp = minions.removeNans(tmp,'rows','all');
X = tmp;

if ~ismatrix(X) %is this a 2D matrix?
    error('Too many dimensions');
end

[m, p]=size(X);

if p<2 %are there at least two groups to plot?
    error('There is only one distribution');
end
    
MaxDatapoints=max(sum((~isnan(X)))); %The maximum number of non-NaN datapoints in any column
jit=(rand(size(X))-0.5)*0.95; %Uniform jitter centered on 0 
xdef=repmat((1:p),m,1); %Background X-axis position

%Figuring out the density of points
X=sort(X);
Dens=zeros(m,p);
k=2; Dens(k,:)=3./((X(k+1,:)-X(k-1,:)));
k=m-1; Dens(k,:)=3./((X(k+1,:)-X(k-1,:)));

for k=3:m-2
    Dens(k,:)=5./((X(k+2,:)-X(k-2,:)));
end
if MaxDatapoints>16
    for Lim=4:floor((min(40,sqrt(MaxDatapoints)))/2)
        for k=(Lim+1):(m-Lim)
            Dens(k,:)=(Lim*2+1)./((X(k+Lim,:)-X(k-Lim,:)));
        end
    end
end


Dens=Dens./max(Dens(:)); %normalizing density
xval=xdef+(jit.*Dens); %new X-axis values
% xdens1=xdef-(Dens./2);
% xdens2=xdef+(Dens./2);

% figure,
% Colors=distinguishable_colors(p);
% for Group=1:p
%     plot(xval(:,Group), X(:,Group), '.', 'Color', Colors(Group,:)), hold on,
%     plot([Group-0.3,Group+0.3],[nanmean(X(:,Group)), nanmean(X(:,Group))],'-k' )
% end
%%
for Group=1:p
    plot(xval(:,Group), X(:,Group), 'k.', 'markers', 12), 
    hold on
%     plot([Group-0.3,Group+0.3],[nanmean(X(:,Group)), nanmean(X(:,Group))],'-k' )
end
box off
%%
set(gca, 'XTick', 1:p)




