function writeInputBNT(inputFileID,userDir,arena,clusterFormat)

%%% initialize structure 'folder' for data storage
trode(1:4)={zeros(1,50)};
unit(1:50)={struct('unit', trode)};
folder=struct('trode',unit);   
folder(200).trode(4).unit(50) = 0;

%%% find all tetrode and cluster numbers
switch clusterFormat
    case 'MClust'
        clusterList = dir('*.t');            
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
        clusterList = dir('*.t');            
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
    case 'SS_ntt'
        trodeList = dir('*.ntt');            
        for iTrode = 1:length(trodeList)         
            try
                [ClusterNums] = Nlx2MatSpike(trodeList(iTrode).name, [0 0 1 0 0], 0, 1);   % find all cluster numbers
            catch
                continue;    % probably an error because this tetrode was disabled
            end
            cNums = unique(ClusterNums(ClusterNums>0));       
            if ~isempty(cNums)
                trodeIndex = str2double(trodeList(iTrode).name(end-4));     % always use TT nums as opposed to PP nums
                for iCluster = 1:length(cNums)
                    folder(1).trode(trodeIndex).unit(iCluster) = iCluster;   
                end
            end
        end
end

%%% create unit list for input file
semi = ';';
tetList{4} = '';
for iTrode = 1:4
    if isempty(folder(1).trode(iTrode).unit);
        tetList{iTrode} = num2str(iTrode);
    else
        tetList{iTrode} = num2str([iTrode,folder(1).trode(iTrode).unit(folder(1).trode(iTrode).unit~=0)]);
    end
end

%%% write BNT input file
fileID = fopen(inputFileID,'w');
fprintf(fileID,'Name: general; Version: 1.0\nSessions %s\nUnits %s %s %s %s %s %s %s\nRoom room146\nShape %s',userDir,tetList{1},semi,tetList{2},semi,tetList{3},semi,tetList{4},arena);
