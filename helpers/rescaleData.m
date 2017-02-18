
% Scale data to have new min and max values.
%
%   USAGE
%       scaledData = rescaleData(dataInput,newMin,newMax)
%       dataInput          numeric data array to scale
%       newMin             (optional) desired minimum (default = 0)
%       newMax             (optional) desired maximum (default = 1)
%
%   OUTPUT
%       scaledData         rescaled data
%
% Written by BRK 2017

function scaledData = rescaleData(dataInput,newMin,newMax)

%% check inputs
if nargin == 1
    newMin = 0;
    newMax = 1;
elseif nargin == 2
    newMax = 1;
end

%% get min and max of data
oldMin = nanmin(dataInput);
oldMax = nanmax(dataInput);
if numel(oldMin) == 1
    flag = false;
else
    flag = true;
end
% keep going through all dimensions
while flag
    oldMin = nanmin(oldMin);
    oldMax = nanmax(oldMax);
    if numel(oldMin) == 1
        flag = false;
    end
end

%% get ranges
newRange = newMax - newMin;
oldRange = oldMax - oldMin;

%% rescale
scaledData = ((newRange * (dataInput - oldMin)) ./ oldRange) + newMin;
