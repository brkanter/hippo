
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

%% initialize structure 'folder' for data storage
trode(1:8)={zeros(1,50)};
unit(1:50)={struct('unit', trode)};
folder=struct('trode',unit);   
folder(200).trode(8).unit(50) = 0;

%% find all tetrode and cluster numbers
clusterList = dir(fullfile(userDir,'*.t'));
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
            folder(1).trode(t_num).unit(c_num) = c_num;   
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
            folder(1).trode(t_num).unit(c_num) = c_num;  
        end
end

%% create unit list for input file
tetList{8} = '';
unitList = [];
for iTrode = 1:8
    if sum(folder(1).trode(iTrode).unit) > 0;
        tetList{iTrode} = num2str([iTrode,folder(1).trode(iTrode).unit(folder(1).trode(iTrode).unit~=0)]);
        unitList = [unitList, tetList{iTrode}, '; '];
    end
end

%% create cut list for input file
cutList = [];
if isempty(clusterList) % make fake .t file
    ''; 
    cellTS = 1;
    save('PP4_TT1_99.t','cellTS')
    unitList = '1 99;';
    cutList = [cutList,'PP4_TT%u_%u; '];
elseif ~isempty(strfind(clusterList(1).name,'PP')) && isempty(strfind(clusterList(1).name,'SS')) % norway MClust
    for iTrode = 1:4
        if (length(tetList{iTrode}) > 1) && iTrode == 1
            cutList = [cutList,'PP4_TT%u_%u; '];
        elseif (length(tetList{iTrode}) > 1) && iTrode == 2
            cutList = [cutList,'PP6_TT%u_%u; '];
        elseif (length(tetList{iTrode}) > 1) && iTrode == 3
            cutList = [cutList,'PP7_TT%u_%u; '];
        elseif (length(tetList{iTrode}) > 1) && iTrode == 4
            cutList = [cutList,'PP3_TT%u_%u; '];
        else
            continue
        end
    end
elseif ~isempty(strfind(clusterList(1).name,'PP')) && ~isempty(strfind(clusterList(1).name,'SS')) % norway SS
    for iTrode = 1:4
        if (length(tetList{iTrode}) > 1) && iTrode == 1
            cutList = [cutList,'PP4_TT%u_SS_%02u; '];
        elseif (length(tetList{iTrode}) > 1) && iTrode == 2
            cutList = [cutList,'PP6_TT%u_SS_%02u; '];
        elseif (length(tetList{iTrode}) > 1) && iTrode == 3
            cutList = [cutList,'PP7_TT%u_SS_%02u; '];
        elseif (length(tetList{iTrode}) > 1) && iTrode == 4
            cutList = [cutList,'PP3_TT%u_SS_%02u; '];
        else
            continue
        end
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
