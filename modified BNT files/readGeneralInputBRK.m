%%% BRK modifications to readGeneralInput
% add option for SpikeSort cuts
% force neuralynx tetrode naming format
% skip loading of old .mat files since they may have been incorrect
% point to loadDataBRK
%%%

function readGeneralInputBRK(filename,clusterFormat)
global gBntData;

%     if nargin < 2
%         p.loadEEG = 'yes';
%     end

%if ~helpers.isstring(p.loadEEG, 'yes', 'no')
%    error('Incorrect value for parameter loadEEG');
%end

trials = io.parseGeneralFile(filename);

gBntData = cell(1, 1);

for i = 1:length(trials)
    trial = trials{i};
    
    oldMatFiles = false;
    
    fprintf('Reading trial #%u out of %u\n', i, length(trials));
    
    gBntData{i} = helpers.initTrial();
    
    gBntData{i}.extraInfo = trial.extraInfo;
    gBntData{i}.sessions = trial.sessions;
    gBntData{i}.cuts = trial.cuts;
    gBntData{i}.units = trial.units;
    
    %% do the inheritance check
    % units
    if isempty(trial.units)
        if i > 1
            gBntData{i}.units = gBntData{i-1}.units;
        else
            error('BNT:noUnits', 'There are no units assigned with trial %u (first session ''%s'').\nCheck your input file!', i, gBntData{i}.sessions{1});
        end
    end
    % shape info
    if ~isfield(gBntData{i}.extraInfo, 'shape')
        if i > 1 && isfield(gBntData{i-1}.extraInfo, 'shape')
            gBntData{i}.extraInfo.shape = gBntData{i-1}.extraInfo.shape;
        end
    end
    
    %% continue loading
    [baseFolder, firstName] = helpers.fileparts(gBntData{i}.sessions{1});
    gBntData{i}.basename = firstName;
    gBntData{i}.path = baseFolder;
    
    if length(gBntData{i}.sessions) > 1
        if length(gBntData{i}.sessions) > size(gBntData{i}.cuts, 2)
            [~, lastName] = helpers.fileparts(gBntData{i}.sessions{end});
            gBntData{i}.basename = strcat(firstName, '+', lastName(end-1:end));
        end
    end
    
    if exist(baseFolder, 'dir') == 0
        error('BNT:noDataFolder', 'Can not find specified data folder. Check that it is written correctly. Your input:\n\t%s', baseFolder);
    end
    
    % Find out if this is Axona or NeuraLynx data
    % In case of multiple sessions, assume that combined sessions have been recorded using the same system.
    % Thus, check only the first session.
    if size(dir(fullfile(baseFolder, '*.set')), 1) > 0 || size(dir(fullfile(baseFolder, '*.pos')), 1) > 0
        gBntData{i}.system = bntConstants.RecSystem.Axona;
        gBntData{i}.sampleTime = 0.02; % 50 Hz
        gBntData{i}.videoSamplingRate = 50;
    end
    
    if size(dir(fullfile(baseFolder, '*.nev')), 1) > 0 || size(dir(fullfile(baseFolder, '*.nvt')), 1) > 0 ...
            || size(dir(fullfile(gBntData{i}.sessions{1}, '*.nev')), 1) > 0 || size(dir(fullfile(gBntData{i}.sessions{1}, '*.nvt')), 1) > 0
        
        gBntData{i}.system = bntConstants.RecSystem.Neuralynx;
        gBntData{i}.sampleTime = 0.04; % 25 Hz
        gBntData{i}.videoSamplingRate = 25;
        if exist(gBntData{i}.sessions{1}, 'dir') ~= 0
            % this is a directory, assign it to path
            gBntData{i}.path = gBntData{i}.sessions{1};
        end
    end
    
    if isnan(gBntData{i}.system)
        % handle already converted data
        matFile = fullfile(baseFolder, sprintf('%s_pos.mat', gBntData{i}.basename));
        if exist(matFile, 'file') ~= 0
            tmp = load(matFile);
            if isfield(tmp, 'recSystem')
                oldMatFiles = true;
                switch lower(tmp.recSystem)
                    case 'axona'
                        gBntData{i}.system = bntConstants.RecSystem.Axona;
                        gBntData{i}.sampleTime = 0.02; % 50 Hz
                        gBntData{i}.videoSamplingRate = 50;
                        
                    case 'neuralynx'
                        gBntData{i}.system = bntConstants.RecSystem.Neuralynx;
                        gBntData{i}.sampleTime = 0.04; % 25 Hz
                        gBntData{i}.videoSamplingRate = 25;
                        gBntData{i}.path = gBntData{i}.sessions{1};
                end
            end
        end
        
        if isnan(gBntData{i}.system)
            error('Failed to identify recording system. Please fix your input file.');
        end
    end
    
    %% search for a cut file if needed
    numCutFiles = size(gBntData{i}.cuts, 1);
    if numCutFiles == 0
        allTFiles = dir(fullfile(gBntData{i}.path, '*.t'));
        for e = 1:length(bntConstants.MClustExtensions)
                curExt = bntConstants.MClustExtensions{e};
                allTFiles = cat(1, allTFiles, dir(fullfile(gBntData{i}.path, sprintf('*.%s', curExt))));
        end
        isMClustCuts = size(allTFiles, 1) > 0;
        isAxonaCuts = size(dir(sprintf('%s_*.cut', gBntData{i}.sessions{1})), 1) > 0;
        
        if isMClustCuts && isAxonaCuts
            error('BNT:io:uncertainty', 'Detected cut files from different systems (MClust, Axona) in the data folder. Unsure which to load. Please specify explicitly which one to use or delete those that should not be used');
        end
        
        if isAxonaCuts
            gBntData{i}.cuts = io.axona.detectAxonaCuts(gBntData{i});
        end
        
        if isMClustCuts
            gBntData{i}.cuts = io.detectMClustCuts(gBntData{i});
        end
    end
    
    %%
    
    %     [loaded, sessionData] = io.checkAndLoad(gBntData{i});
    %     if loaded
    %         gBntData{i} = sessionData;
    %         continue;
    %     end
    %
    
    if strcmpi(gBntData{i}.system, bntConstants.RecSystem.Axona)
        io.axona.loadData(i);
    elseif strcmpi(gBntData{i}.system, bntConstants.RecSystem.Neuralynx)
        %%% BRK
%         io.neuralynx.loadData(i);
        gBntData{i}.cuts = {'TT%u_%u'};
        loadDataBRK(i,clusterFormat);
        %%%
    else
        error('Unknown recording system %s. Not implemented', gBntData{i}.system);
    end
    
    if ~oldMatFiles
        data.saveTrial(i);
    end
end
end

