
% Write input file for BNT by extracting names of cluster timestamp files
% in specified directories.
%
%   USAGE
%       writeInputBNT(inputFile, folder, arena, clusterFormat, <sessionName>, <cutFolder>)
%       inputFile           string specifying where to write the input file
%       folder              directory with clusters, position data, etc.
%       arena               string with shape and size of recording arena (e.g. 'cylinder 60 60' or 'box 100 100')
%       clusterFormat       string describing spike timestamp files (e.g. 'MClust' or 'Tint')
%       sessionName         optional. String with session name if multiple sessions are stored in one folder
%                           (N.B.: if you have .pos files, session name is the whole name of the .pos file without the .pos itself,
%                           e.g. session name for Mouse58313_20170322_02_5Hz20mW.pos is 'Mouse58313_20170322_02_5Hz20mW')
%       cutFolder           optional. Directory where cut files should be searched for. If omitted,
%                           then `folder` is used.
%
%   SEE ALSO
%       penguin emperorPenguin emperorPenguinSelect startup
%
% Written by BRK 2015

function writeInputBNT(inputFile, folder, arena, clusterFormat, sessionName, cutFolder)

%% check inputs
if iscell(folder)
    folder = folder{1};
end
if exist('sessionName','var')
    if iscell(sessionName)
        if isempty(sessionName)
            sessionName = '';
        else
            sessionName = sessionName{1};
        end
    end
else
    sessionName = '';
end
if nargin < 6 || isempty(cutFolder)
    cutFolder = folder;
end

%% get file list
if strcmpi(clusterFormat,'MClust') || strcmpi(clusterFormat,'SS_t')

    cutList = dir(fullfile(cutFolder, '*.t*'));

elseif strcmpi(clusterFormat,'Tint')
    
    % find all .cut files in folder
    cutFiles = extractfield(dir(fullfile(cutFolder,'*.cut')),'name'); 
    
    % find .cut files for a particular session
    if numel(sessionName)
        inds = ~cellfun(@isempty,cellfun(@strfind,cutFiles,repmat({sessionName},1,length(cutFiles)),'uniformoutput',0));
        cutList = cutFiles(inds);
    else 
        cutList = cutFiles;
    end
    
else

    error('Cluster format not recognized.')

end

%% find all tetrode and cluster numbers
if ~isempty(cutList)
    cellMatrix = nan(500,2);
    flagPP = false;
    if strcmpi(clusterFormat,'MClust')

        wrongFiles = false(1, length(cutList));
        for iCluster = 1:length(cutList)
            splits = regexp(cutList(iCluster).name,'_','split');
            if length(splits) == 1
                wrongFiles(iCluster) = true;
                continue;
            end
            try
                [~, cutFilename, ~] = helpers.fileparts(cutList(iCluster).name);
                if length(cutList(iCluster).name) <= 9      % oregon
                    t_num = cellfun(@str2double,strtok(splits(1),'T'));
                    c_num = cellfun(@str2double,strtok(splits(2),'.'));
                elseif length(cutList(iCluster).name) >= 9 && isempty(strfind(cutList(iCluster).name,'SS'))  % norway
                    flagPP = true;
                    tIdx = strfind(cutFilename, 'T');
                    if isempty(tIdx)
                        continue;
                    end
                    tIdx = tIdx(end);
                    candidates = regexp(cutFilename(tIdx+1:end), '\d*', 'match');
                    if length(candidates) < 2
                        continue;
                    end
                    t_num = str2double(candidates{1});
                    c_num = str2double(candidates{2});
                else
                    continue
                end
                cellMatrix(iCluster,1) = t_num;
                cellMatrix(iCluster,2) = c_num;
            catch
                continue;
            end
        end
        cutList(wrongFiles) = [];

    elseif strcmpi(clusterFormat,'SS_t')

        for iCluster = 1:length(cutList)
            splits = regexp(cutList(iCluster).name,'_','split');
            c_num = cellfun(@str2double,strtok(splits(end),'.'));
            if length(cutList(iCluster).name) <= 13 && ~isempty(strfind(cutList(iCluster).name,'SS'))    % oregon
                t_num = cellfun(@str2double,strtok(splits(1),'T'));
            elseif length(cutList(iCluster).name) >= 13   % norway
                flagPP = true;
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
            ind = regexp(cutList{iTetrode},'(?<!\d)(\d)(?!\d)');
            t_num = str2double(cutList{iTetrode}(ind(end)));
            
            % session name could be ambiguous, so make sure it is followed by tetrode number
            if isempty(strfind(cutList{iTetrode},[sessionName,'_',num2str(t_num) '_'])) ...
                    && isempty(strfind(cutList{iTetrode},[sessionName,'_',num2str(t_num) '.']))
                
                % if not, remove that cut and continue
                cutList{iTetrode} = '';
                continue
            end
            
            clusters = unique(io.axona.getCut(fullfile(cutFolder,cutList{iTetrode})));
            clusters = clusters(clusters ~=0);
            for iCluster = 1:length(clusters)
                c_num = clusters(iCluster);
                cellMatrix(rowCount,1) = t_num;
                cellMatrix(rowCount,2) = c_num;
                rowCount = rowCount + 1;
            end
        end
        
        % update list in case some were removed above
        cutList = cutList(~cellfun(@isempty,cutList));
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
if isempty(cutList)

    error('Did not find any clusters.')

else

    if ~strcmpi(cutFolder, folder)
        cutAddon = cutFolder;
    else
        cutAddon = [];
    end

    if strcmpi(clusterFormat,'Tint')   % Tint

        for iTetrode = 1:length(cutList)
            cutsForBNT = [cutsForBNT, fullfile(cutFolder,cutList{iTetrode}), '; '];
        end

    elseif flagPP && strcmpi(clusterFormat,'MClust')   % norway MClust

        if sum(find(tetrodes == 1))
            cutsForBNT = [cutsForBNT,fullfile(cutAddon, 'PP4_TT%u_%u; ')];
        end
        if sum(find(tetrodes == 2))
            cutsForBNT = [cutsForBNT,fullfile(cutAddon, 'PP6_TT%u_%u; ')];
        end
        if sum(find(tetrodes == 3))
            cutsForBNT = [cutsForBNT,fullfile(cutAddon, 'PP7_TT%u_%u; ')];
        end
        if sum(find(tetrodes == 4))
            cutsForBNT = [cutsForBNT,fullfile(cutAddon, 'PP3_TT%u_%u; ')];
        end

    elseif flagPP && strcmpi(clusterFormat,'SS_t')   % norway SS

        if sum(find(tetrodes == 1))
            cutsForBNT = [cutsForBNT,fullfile(cutAddon, 'PP4_TT%u_SS_%02u; ')];
        end
        if sum(find(tetrodes == 2))
            cutsForBNT = [cutsForBNT,fullfile(cutAddon, 'PP6_TT%u_SS_%02u; ')];
        end
        if sum(find(tetrodes == 3))
            cutsForBNT = [cutsForBNT,fullfile(cutAddon, 'PP7_TT%u_SS_%02u; ')];
        end
        if sum(find(tetrodes == 4))
            cutsForBNT = [cutsForBNT,fullfile(cutAddon, 'PP3_TT%u_SS_%02u; ')];
        end

    elseif ~flagPP && strcmpi(clusterFormat,'MClust')   % oregon MClust

        cutsForBNT = fullfile(cutAddon, 'TT; ');

    elseif ~flagPP && strcmpi(clusterFormat,'SS_t')   % oregon SS

        cutsForBNT = fullfile(cutAddon, 'TT%u_SS_%02u; ');

    end
end

%% write BNT input file
fileID = data.safefopen(inputFile,'w');
if strcmpi(clusterFormat,'Tint')
    if ~numel(sessionName)
        sessionName = extractfield(dir(fullfile(folder,'*.pos')),'name');
        sessionName = sessionName{1}(1:end-4);
    end
    sessionPath = fullfile(folder,sessionName);
    fprintf(fileID,'Name: general; Version: 1.0\nSessions %s\nCuts %s\nUnits %s\nShape %s',sessionPath,cutsForBNT,unitList,arena);
else
    fprintf(fileID,'Name: general; Version: 1.0\nSessions %s\nCuts %s\nUnits %s\nShape %s',folder,cutsForBNT,unitList,arena);
end

