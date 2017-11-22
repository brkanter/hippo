

%%% --------------
% BRK flipped and transposed so that instead of reading up from bottom left, it reads right from top left. 
%%% --------------

function [ positions ] = subplot_pos(plotwidth,plotheight,leftmargin,rightmargin,bottommargin,topmargin,nbx,nby,spacex,spacey)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    subxsize=(plotwidth-leftmargin-rightmargin-spacex*(nbx-1.0))/nbx;
    subysize=(plotheight-topmargin-bottommargin-spacey*(nby-1.0))/nby;
    
    for i=1:nbx
       for j=1:nby
 
           xfirst=leftmargin+(i-1.0)*(subxsize+spacex);
           yfirst=topmargin+(j-1.0)*(subysize+spacey);
 
           % BRK change
%            positions{i,j}=[xfirst/plotwidth yfirst/plotheight subxsize/plotwidth subysize/plotheight];
           positions{j,i}=[xfirst/plotwidth yfirst/plotheight subxsize/plotwidth subysize/plotheight];
 
       end
    end

% BRK change    
positions = flipud(positions);
    
end