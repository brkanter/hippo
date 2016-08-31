
% Fit data with polynomial of your choice and return coefficient of determination.
%
%   USAGE
%       [R2,AR2,yfit] = benFit(x,y,degree,showLine)
%       x           vector of x values (independent variable)
%       y           vector of y values (dependent variable)
%       degree      degree of polynomial fit
%       showLine    anything other than 0 will plot fit
%
%   OUTPUTS
%       R2          R squared
%       AR2         adjusted R squared
%       yfit        value of polynomial evaluated at x
%
% Written by BRK 2015

function [R2,AR2,yfit] = benFit(x,y,degree,showLine)

if ~exist('showLine','var')
    showLine = 0;
end

%% remove nans
xnan = isnan(x);
ynan = isnan(y);
x = x(~xnan & ~ynan);
y = y(~xnan & ~ynan);

%% do the fit
p = polyfit(x,y,degree);
yfit = polyval(p, x);

%% get R vals
residY = y - yfit;
SSresid = sum(residY.^2);
SStotal = (length(y)-1) * var(y);
R2 = 1 - SSresid/SStotal;
AR2 = R2 * ((length(y)-1) / (length(y)-degree-1));

%% display results
% display(R2)
% display(AR2)

%% plot best fit line
if showLine
    plot(x,yfit,'k-','linewidth',2)
end
