
% Write input file for BNT by extracting names of cluster timestamp files
% in specified directories.
%
%   USAGE
%       writeInputBNT(penguinInput,folder,arena,clusterFormat)
%       penguinInput        string specifying where to write the input file
%       folder              directory of recording session
%       arena               string with shape and size of recording arena
%       clusterFormat       string describing spike timestamp files (e.g. 'MClust' or 'Tint')
%
%   SEE ALSO
%       penguin emperorPenguin emperorPenguinSelect startup
%
% Written by BRK 2015

function writeInputBNT(penguinInput,folder,arena,clusterFormat)

%% get file list
if strcmpi(clusterFormat,'MClust') || strcmpi(clusterFormat,'SS_t')
    
    cutList = dir(fullfile(folder,'*.t'));
    
elseif strcmpi(clusterFormat,'Tint')
    
    prompt={'Enter the date and trial number'};
    name='';
    numlines=1;
    defaultanswer={'10051302'};
    Answer = inputdlg(prompt,name,numlines,defaultanswer,'on');
    if isempty(Answer); return; end;
    date_trial = Answer{1};
    cutList = dir([fullfile(folder,date_trial),'*.cut']);
    
end

%% find all tetrode and cluster numbers
if ~isempty(cutList)
    cellMatrix = nan(200,2);
    if strcmpi(clusterFormat,'MClust')
        
        for iCluster = 1:length(cutList)
            splits = regexp(cutList(iCluster).name,'_','split');
            if length(cutList(iCluster).name) <= 9      % oregon
                t_num = cellfun(@str2double,strtok(splits(1),'T'));
                c_num = cellfun(@str2double,strtok(splits(2),'.'));
            elseif length(cutList(iCluster).name) >= 9 && isempty(strfind(cutList(iCluster).name,'SS'))  % norway
                t_num = cellfun(@str2double,strtok(splits(2),'T'));
                c_num = cellfun(@str2double,strtok(splits(3),'.'));
            else
                continue
            end
            cellMatrix(iCluster,1) = t_num;
            cellMatrix(iCluster,2) = c_num;
        end
        
    elseif strcmpi(clusterFormat,'SS_t')
        
        for iCluster = 1:length(cutList)
            splits = regexp(cutList(iCluster).name,'_','split');
            c_num = cellfun(@str2double,strtok(splits(end),'.'));
            if length(cutList(iCluster).name) <= 13 && ~isempty(strfind(cutList(iCluster).name,'SS'))    % oregon
                t_num = cellfun(@str2double,strtok(splits(1),'T'));
            elseif length(cutList(iCluster).name) >= 13   % norway
                t_num = cellfun(@str2double,strtok(splits(2),'T'));
            else
                continue
            end
            cellMatrix(iCluster,1) = t_num;
            cellMatrix(iCluster,2) = c_num;
        end
        
    elseif strcmpi(clusterFormat,'Tint')
        
        rowCount = 1;
        for iTetrode = 1:length(cutList)
            splits = regexp(cutList(iTetrode).name,'_','split');
            t_num = cellfun(@str2double,strtok(splits(end),'.'));
            clusters = unique(io.axona.getCut(fullfile(folder,cutList(iTetrode).name)));
            clusters = clusters(clusters ~=0);
            for iCluster = 1:length(clusters)
                c_num = clusters(iCluster);
                cellMatrix(rowCount,1) = t_num;
                cellMatrix(rowCount,2) = c_num;
                rowCount = rowCount + 1;
            end
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
cutsForBNT = [];
if isempty(cutList) && strcmpi(clusterFormat,'MClust')   % make fake .t file
    
    '';
    cellTS = 1;
    save(fullfile(folder,'PP4_TT1_99.t'),'cellTS')
    unitList = '1 99;';
    cutsForBNT = [cutsForBNT,'PP4_TT%u_%u; '];
    
elseif isempty(cutList)
    error('Did not find any clusters.')
end
    
if strcmpi(clusterFormat,'Tint')   % Tint
    
    for iTetrode = 1:length(cutList)
        cutsForBNT = [cutsForBNT, fullfile(folder,cutList(iTetrode).name), '; '];
    end
    
elseif ~isempty(strfind(cutList(1).name,'PP')) && strcmpi(clusterFormat,'MClust')   % norway MClust
    
    if sum(find(tetrodes == 1))
        cutsForBNT = [cutsForBNT,'PP4_TT%u_%u; '];
    end
    if sum(find(tetrodes == 2))
        cutsForBNT = [cutsForBNT,'PP6_TT%u_%u; '];
    end
    if sum(find(tetrodes == 3))
        cutsForBNT = [cutsForBNT,'PP7_TT%u_%u; '];
    end
    if sum(find(tetrodes == 4))
        cutsForBNT = [cutsForBNT,'PP3_TT%u_%u; '];
    end
    
elseif ~isempty(strfind(cutList(1).name,'PP')) && strcmpi(clusterFormat,'SS_t')   % norway SS
    
    if sum(find(tetrodes == 1))
        cutsForBNT = [cutsForBNT,'PP4_TT%u_SS_%02u; '];
    end
    if sum(find(tetrodes == 2))
        cutsForBNT = [cutsForBNT,'PP6_TT%u_SS_%02u; '];
    end
    if sum(find(tetrodes == 3))
        cutsForBNT = [cutsForBNT,'PP7_TT%u_SS_%02u; '];
    end
    if sum(find(tetrodes == 4))
        cutsForBNT = [cutsForBNT,'PP3_TT%u_SS_%02u; '];
    end
    
elseif isempty(strfind(cutList(1).name,'PP')) && strcmpi(clusterFormat,'MClust')   % oregon MClust
    
    cutsForBNT = 'TT; ';
    
elseif isempty(strfind(cutList(1).name,'PP')) && strcmpi(clusterFormat,'SS_t')   % oregon SS
    
    cutsForBNT = 'TT%u_SS_%02u; ';
       
end

%% write BNT input file
fileID = fopen(penguinInput,'w');
if strcmpi(clusterFormat,'Tint')
    sessionName = fullfile(folder,splits{1});
    fprintf(fileID,'Name: general; Version: 1.0\nSessions %s\nCuts %s\nUnits %s\nShape %s',sessionName,cutsForBNT,unitList,arena);
else
    fprintf(fileID,'Name: general; Version: 1.0\nSessions %s\nCuts %s\nUnits %s\nShape %s',folder,cutsForBNT,unitList,arena);
end
fclose(fileID);

