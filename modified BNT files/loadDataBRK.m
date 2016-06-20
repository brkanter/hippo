%%% BRK modifications to loadData
% add option for SpikeSort cuts
%%%

% Load NeuraLynx data
%
function loadDataBRK(trialNum,clusterFormat)
global gBntData;

if length(gBntData) < trialNum
    error('Invalid argument');
end

if strcmpi(gBntData{trialNum}.system, bntConstants.RecSystem.Neuralynx) == false
    error('Invalid recording system');
end

numSessions = length(gBntData{trialNum}.sessions);

% eegDataAll = {};
% s = 1;
numSamples = 0;
timeOffset = nan(1, numSessions);
numSpikes = 0;

% TODO: Read EEG information
% ==========================
% maxEegs = 16;
% eegFiles = strcat(gBntData{trialNum}.sessions{s}, '*.Ncs');
% dirInfo = dir(eegFiles);
% if size(dirInfo, 1) ~= maxEegs
% end

numCutFiles = size(gBntData{trialNum}.cuts, 1);

for s = 1:numSessions
    [~, sessionName] = helpers.fileparts(gBntData{trialNum}.sessions{s});
    
    videoFile = fullfile(gBntData{trialNum}.sessions{s}, 'VT1.Nvt');
    if exist(videoFile, 'file') == 0
        videoFile = fullfile(gBntData{trialNum}.path, 'VT1.Nvt');
        if exist(videoFile, 'file') == 0
            error('File %s doesn''t exists', videoFile);
        end
    end
    
    fprintf('Loading video file "%s"...', videoFile);
    [pos, targets] = io.neuralynx.readVideoData(videoFile);
    fprintf(' done\n');
    
    % check that timestamps are monotonic
    positiveDiff = diff(pos(:, bntConstants.PosT)) >= 0;
    if ~all(positiveDiff > 0)
        pos(:, bntConstants.PosT) = sort(pos(:, bntConstants.PosT));
    end
    
    % check for identical values
    badTime = find(diff(pos(:, bntConstants.PosT)) <= 0);
    if ~isempty(badTime)
        warning('BNT:badTimestamps', 'Some timestamps of position samples are incorrect. Will remove them. values of timestamps should increase monotonically.')
        pos(badTime, :) = [];
        targets(:, badTime) = [];
    end
    
    pos = helpers.fixIsolatedData(pos);
    
    curSessionSamples = length(pos(:, bntConstants.PosT));
    offset = 0;
    if s > 1
        gBntData{trialNum}.startIndices(s) = numSamples + 1;
        offset = gBntData{trialNum}.positions(end, bntConstants.PosT) + gBntData{trialNum}.sampleTime;
    else
        gBntData{trialNum}.startIndices(s) = 1;
    end
    timeOffset(s) = offset;
    
    gBntData{trialNum}.positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosT) = pos(:, bntConstants.PosT) + offset;
    gBntData{trialNum}.positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosX) = pos(:, bntConstants.PosX);
    gBntData{trialNum}.positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosY) = pos(:, bntConstants.PosY);
    gBntData{trialNum}.nlx.targets(:, numSamples+1:numSamples+curSessionSamples) = targets;
    % we do not have second LED positions at the moment
    
    numSamples = numSamples + curSessionSamples;
    
    % TODO: change this to session path, introduce cut file for neuralynx
    
    if numCutFiles == 0 && size(gBntData{1}.cuts, 1) > 0
        % we have a cut file for first session, which should be used for all sessions
        trialNumForCuts = 1;
    else
        trialNumForCuts = trialNum;
    end
    
    tetrodes = unique(gBntData{trialNum}.units(:, 1), 'stable');
    for i = 1:length(tetrodes)
        tetrode = tetrodes(i);
        selected = gBntData{trialNum}.units(:, 1) == tetrode;
        cells = gBntData{trialNum}.units(selected, 2);
        
        for c = 1:length(cells)
            cutExists = false;
            
            % parse cut file information, extract file pattern, directory
            if numCutFiles > 0
                if i <= size(gBntData{trialNumForCuts}.cuts, 1)
                    [cutPath, cutName, cutExt] = fileparts(gBntData{trialNumForCuts}.cuts{i});
                else
                    [cutPath, cutName, cutExt] = fileparts(gBntData{trialNumForCuts}.cuts{1});
                end
                
                if isempty(cutExt)
                    cutExt = 't*'; % must be without .
                else
                    if cutExt(1) == '.'
                        cutExt(1) = [];
                    end
                end
                if isempty(cutPath)
                    cutPath = gBntData{trialNum}.sessions{s};
                end
            else
                cutExt = 't*'; % must be without .
                cutPath = gBntData{trialNum}.sessions{s};
            end
            
            % check with information from input file
            if numCutFiles > 0
                cutShortName = sprintf('%s%u_%u.%s', cutName, tetrode, cells(c), cutExt);
                cutFileName = fullfile(cutPath, cutShortName);
                cutFiles = dir(cutShortName);
                if ~isempty(cutFiles)
                    cutFileName = fullfile(cutPath, cutFiles(1).name);
                    cutExists = true;
                end
            end
            
            if ~cutExists && numCutFiles > 0
                if i <= numCutFiles
                    namePattern = [gBntData{trialNum}.cuts{i} '.' cutExt];
                else
                    namePattern = [gBntData{trialNum}.cuts{1} '.' cutExt];
                end
                % there should be no escape sequences, so remove them
                namePattern = strrep(namePattern, '\', '\\');
                cutNameForSearch = sprintf(namePattern, tetrode, cells(c));
                cutFileName = fullfile(gBntData{trialNum}.path, cutNameForSearch);
                cutNames = dir(cutFileName);
                if ~isempty(cutFiles)
                    cutFileName = fullfile(gBntData{trialNum}.path, cutNames(1).name);
                    cutExists = true;
                end
            end
            
            if ~cutExists && exist('cutName', 'var') == 1
                % we probably have a complete file pattern (path + file name) in the input file
                
                cutShortName = sprintf(cutName, tetrode, cells(c));
                cutShortName = sprintf('%s.%s', cutShortName, cutExt);
                
                cutFileName = fullfile(cutPath, cutShortName);
                cutFiles = dir(cutFileName);
                if ~isempty(cutFiles)
                    cutFileName = fullfile(cutPath, cutFiles(1).name);
                    cutExists = true;
                end
            end
            %%% BRK
%             if ~cutExists
%                 warning('BNT:noCutFile', 'Failed to find cut file for T%dC%d, session %s. Tried several naming schemas. Last try was "%s"', tetrode, cells(c), sessionName, cutFileName);
%             end
            % parse filename and read MClust or SpikeSort data
            if strcmpi(cutFileName(end),'*')
                cutFileName = cutFileName(1:end-1); % remove star if necessary
            end
            switch clusterFormat
                case 'MClust'
                    slashInds = strfind(cutFileName,'\');
                    nameStart = cutFileName(1:slashInds(end));
                    split = regexp(cutFileName,'\','split');
                    split2 = regexp(split{end},'_','split');
                    try       % oregon
                        fullFileName = sprintf('%s%s',nameStart,split{end});   
                        spikeData = io.neuralynx.readMclustSpikeFile(fullFileName);
                    catch     % norway
                        if strcmpi(split2{1}(end),'1')
                            PP = 'PP4';
                        elseif strcmpi(split2{1}(end),'2')
                            PP = 'PP6';
                        elseif strcmpi(split2{1}(end),'3')
                            PP = 'PP7';
                        else
                            PP = 'PP3';
                        end
                        fullFileName = sprintf('%s%s_%s',nameStart,PP,split{end});  
                        spikeData = io.neuralynx.readMclustSpikeFile(fullFileName);
                    end
                case 'SS_t'
                    slashInds = strfind(cutFileName,'\');
                    nameStart = cutFileName(1:slashInds(end));
                    split = regexp(cutFileName,'\','split');
                    split2 = regexp(split{end},'_','split');
                    c_num = cellfun(@str2double,strtok(split2(end),'.'));
                    try       % oregon
                        if c_num < 10
                            fileEnding = [split2{1} '_SS_' '0' num2str(c_num) '.t'];
                        else
                            fileEnding = [split2{1} '_SS_' num2str(c_num) '.t'];
                        end
                        fullFileName = sprintf('%s%s',nameStart,fileEnding); 
                        spikeData = io.neuralynx.readMclustSpikeFile(fullFileName);
                    catch     % norway
                        if strcmpi(split2{1}(end),'1')
                            PP = 'PP4';
                        elseif strcmpi(split2{1}(end),'2')
                            PP = 'PP6';
                        elseif strcmpi(split2{1}(end),'3')
                            PP = 'PP7';
                        else
                            PP = 'PP3';
                        end
                        fullFileName = sprintf('%s%s_%s',nameStart,PP,fileEnding);  
                        spikeData = io.neuralynx.readMclustSpikeFile(fullFileName);
                    end
                case 'SS_ntt'
                    slashInds = strfind(cutFileName,'\');
                    nameStart = cutFileName(1:slashInds(end));
                    split = regexp(cutFileName,'\','split');
                    split2 = regexp(split{end},'_','split');
                    try       % oregon
                        fullFileName = sprintf('%s%s.ntt',nameStart,split2{1});   
                        [TetrodeTimeStamps,CellNums] = Nlx2MatSpike(fullFileName,[1 0 1 0 0],0,1); 
                        spikeData  = TetrodeTimeStamps(CellNums==cells(c))/1000000;  
                    catch     % norway
                        if strcmpi(split2{1}(end),'1')
                            PP = 'PP4';
                        elseif strcmpi(split2{1}(end),'2')
                            PP = 'PP6';
                        elseif strcmpi(split2{1}(end),'3')
                            PP = 'PP7';
                        else
                            PP = 'PP3';
                        end
                        fullFileName = sprintf('%s%s_%s.ntt',nameStart,PP,split2{1});
                        [TetrodeTimeStamps,CellNums] = Nlx2MatSpike(fullFileName,[1 0 1 0 0],0,1); 
                        spikeData  = TetrodeTimeStamps(CellNums==cells(c))/1000000; 
                    end
            end
            curNumSpikes = length(spikeData);
            gBntData{trialNum}.spikes(numSpikes+1:numSpikes+curNumSpikes, 1) = spikeData + timeOffset(s);
            gBntData{trialNum}.spikes(numSpikes+1:numSpikes+curNumSpikes, 2) = tetrode;
            gBntData{trialNum}.spikes(numSpikes+1:numSpikes+curNumSpikes, 3) = cells(c);
            numSpikes = numSpikes + curNumSpikes;
            %%%%% BRK
        end
    end
end % loop over sessions

if isempty(gBntData{trialNum}.spikes)
    [~, sessionName] = helpers.fileparts(gBntData{trialNum}.sessions{1});
    warning('BNT:noSpikes', 'There are no spikes for session %s', sessionName);
else
    [minSpike, ~] = nanmin(gBntData{trialNum}.spikes(:, 1));
    if ~isempty(minSpike)
        minTime = nanmin(gBntData{trialNum}.positions(:, bntConstants.PosT));
        if minSpike < minTime
            toRemove = gBntData{trialNum}.spikes(:, 1) < minTime;
            
            warning('BNT:earlySpike', 'Data contains %u spike times that are earlier than the first position timestamp. These spikes will be removed.', length(find(toRemove)));
            gBntData{trialNum}.spikes(toRemove, :) = [];
        end
    end
    
    maxSpike = nanmax(gBntData{trialNum}.spikes(:, 1));
    if ~isempty(maxSpike)
        maxTime = nanmax(gBntData{trialNum}.positions(:, bntConstants.PosT));
        if maxSpike > maxTime
            toRemove = gBntData{trialNum}.spikes(:, 1) > maxTime;
            
            warning('BNT:lateSpike', 'Data contains %u spike times that occur after the last position timestamp. These spikes will be removed.', length(find(toRemove)));
            gBntData{trialNum}.spikes(toRemove, :) = [];
        end
    end
end
end
