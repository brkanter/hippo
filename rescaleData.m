function dataOutput = rescaleData(dataInput,newMin,newMax)

%% scale from 0 to 1 by default
if nargin == 1
    newMin = 0;
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
dataOutput = ((newRange * (dataInput - oldMin)) ./ oldRange) + newMin;
