function emperor = createEmperorArray(clusterData,numExp,include)

%% extract names of measures
fields = fieldnames(clusterData);
fields = fields(cellfun(@isempty,strfind(fields,'Map')));
numFields = length(fields);

%% add each measure in a new column
emperor = [];
for iExp = 1:numExp
    for iField = 1:numFields
        if iField == 1
            expData(:,1) = eval(sprintf('{clusterData(:,:,iExp).%s}',fields{iField}));
        else
            expData(:,size(expData,2)+1) = eval(sprintf('{clusterData(:,:,iExp).%s}',fields{iField}));
        end
    end
    
    % delete extra rows
    expData(cellfun(@isempty,expData(:,1)),:) = [];
    % sort data by tetrode and cluster
    expData = sortrows(expData,[find(strcmpi(fields,'tetrode')) find(strcmpi(fields,'cluster'))]);
    % append to full data set
    emperor = [emperor; expData];
    clear expData
end
    