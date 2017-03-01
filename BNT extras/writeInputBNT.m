
% Write input file for BNT by extracting names of cluster timestamp files
% in specified directories.
%
%   USAGE
%       writeInputBNT(penguinInput,userDir,arena,clusterFormat)
%       penguinInput        string specifying where to write the input file
%       userDir             directory of recording session
%       arena               string with shape and size of recording arena
%       clusterFormat       string describing spike timestamp files (e.g. 'MClust')
%
%   SEE ALSO
%       penguin emperorPenguin emperorPenguinSelect startup
%
% Written by BRK 2015

function writeInputBNT(penguinInput,userDir,arena,clusterFormat)

%% find all tetrode and cluster numbers
clusterList = dir(fullfile(userDir,'*.t'));
if ~isempty(clusterList)
    cellMatrix = nan(200,2);
    switch clusterFormat
        case 'MClust'
            for iCluster = 1:length(clusterList)
                splits = regexp(clusterList(iCluster).name,'_','split');
                if length(clusterList(iCluster).name) <= 9      % oregon
                    t_num = cellfun(@str2double,strtok(splits(1),'T'));
                    c_num = cellfun(@str2double,strtok(splits(2),'.'));
                elseif length(clusterList(iCluster).name) >= 9 && isempty(strfind(clusterList(iCluster).name,'SS'))  % norway
                    t_num = cellfun(@str2double,strtok(splits(2),'T'));
                    c_num = cellfun(@str2double,strtok(splits(3),'.'));
                else
                    continue
                end
                cellMatrix(iCluster,1) = t_num;
                cellMatrix(iCluster,2) = c_num;
            end
        case 'SS_t'
            for iCluster = 1:length(clusterList)
                splits = regexp(clusterList(iCluster).name,'_','split');
                c_num = cellfun(@str2double,strtok(splits(end),'.'));
                if length(clusterList(iCluster).name) <= 13 && ~isempty(strfind(clusterList(iCluster).name,'SS'))    % oregon
                    t_num = cellfun(@str2double,strtok(splits(1),'T'));
                elseif length(clusterList(iCluster).name) >= 13   % norway
                    t_num = cellfun(@str2double,strtok(splits(2),'T'));
                else
                    continue
                end
                cellMatrix(iCluster,1) = t_num;
                cellMatrix(iCluster,2) = c_num;
            end
    end
    cellMatrix(all(arrayfun(@isnan,cellMatrix),2),:) = [];
    
    %% create unit list for input file
    tetrodes = unique(cellMatrix(:,1));
    unitList = [];
    for iTetrode = 1:length(tetrodes)
        clusters = cellMatrix(cellMatrix(:,1) == tetrodes(iTetrode),2);
        unitList = [unitList, num2str(tetrodes(iTetrode)), '  ', num2str(clusters'), '; '];
    end
end

%% create cut list for input file
cutList = [];
if isempty(clusterList) % make fake .t file
    ''; 
    cellTS = 1;
    save(fullfile(userDir,'PP4_TT1_99.t'),'cellTS')
    unitList = '1 99;';
    cutList = [cutList,'PP4_TT%u_%u; '];
elseif ~isempty(strfind(clusterList(1).name,'PP')) && isempty(strfind(clusterList(1).name,'SS')) % norway MClust
    if sum(find(tetrodes == 1))
        cutList = [cutList,'PP4_TT%u_%u; '];
    end
    if sum(find(tetrodes == 2))
        cutList = [cutList,'PP6_TT%u_%u; '];
    end
    if sum(find(tetrodes == 3))
        cutList = [cutList,'PP7_TT%u_%u; '];
    end
    if sum(find(tetrodes == 4))
        cutList = [cutList,'PP3_TT%u_%u; '];
    end
elseif ~isempty(strfind(clusterList(1).name,'PP')) && ~isempty(strfind(clusterList(1).name,'SS')) % norway SS
    if sum(find(tetrodes == 1))
        cutList = [cutList,'PP4_TT%u_SS_%02u; '];
    end
    if sum(find(tetrodes == 2))
        cutList = [cutList,'PP6_TT%u_SS_%02u; '];
    end
    if sum(find(tetrodes == 3))
        cutList = [cutList,'PP7_TT%u_SS_%02u; '];
    end
    if sum(find(tetrodes == 4))
        cutList = [cutList,'PP3_TT%u_SS_%02u; '];
    end
elseif isempty(strfind(clusterList(1).name,'SS')) && isempty(strfind(clusterList(1).name,'PP')) % oregon MClust
    cutList = 'TT; ';
elseif ~isempty(strfind(clusterList(1).name,'SS')) && isempty(strfind(clusterList(1).name,'PP')) % oregon SS
    cutList = 'TT%u_SS_%02u; ';
else
    error('Unknown cluster type.')
end

%% write BNT input file
fileID = fopen(penguinInput,'w');
fprintf(fileID,'Name: general; Version: 1.0\nSessions %s\nCuts %s\nUnits %s\nShape %s',userDir,cutList,unitList,arena);
fclose(fileID);

