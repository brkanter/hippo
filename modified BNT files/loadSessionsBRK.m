%%% BRK modifications to data.loadSessions
% add option for SpikeSort cuts
% point to readGeneralInputBRK
%%%

% Load all data for a given recording session
%
% System independent function to set current session. Session file,
% which is pointed by filename, should contain information about
% recorded data. It doesn't matter if recorded data is in Axon or
% Neuralynx format. This function will convert the data in system
% independent format and store it alongside the original files.
%
%  USAGE
%    data.loadSessions(filename, dataToUse, replaceOriginal)
%
%    filename           Name of the input file that describes data to load.
%    dataToUse          Optional string, that governs the data load. Possible values:
%                       'last' Use the last loaded data.
%                       All other values (including omitted string) are treated as we should
%                       load data in a regular manner.
%    replaceOriginal    Boolean. If TRUE then function will replace
%                       original input file (if this is necessary). Default
%                       is TRUE. Normally you should not use this argument.
%                       It was added mostly to run unit tests.
%
function loadSessionsBRK(filename, clusterFormat, dataToUse, replaceOriginal)
    global gBntData; % global structure to store data
    global gCurrentTrial;
    global gBntInit;

    if nargin < 3
        dataToUse = '';
    end

    if nargin < 4
        replaceOriginal = true;
    end

    if isempty(gBntInit)
        InitBNT;
    end

    if strcmpi(dataToUse, 'last') && ~isempty(gBntData)
        gCurrentTrial = 1;
        return;
    end

    % clear old data
    gBntData = {};

    [inPath, inFile, inExt] = helpers.fileparts(filename);

    fid = data.safefopen(filename, 'r');
    str = fgets(fid);
    
    if feof(fid)
        error('Your input file is empty!');
    end

    if isempty(strtrim(str))
        % Try to get first non-blank line
        while ~feof(fid)
            str = strtrim(fgets(fid));
            if ~isempty(str)
                break;
            end
        end
    end

    if feof(fid)
        error('Your input file is empty!');
    end

    % make another check that it is indeed Raymond's file
    if ~isempty(strfind(str, 'Session'))
        trials = io.readRaymondInputFileMeta(fid);
        fclose(fid);

        backupFile = fullfile(inPath, sprintf('%s%s.bak', inFile, inExt));
        saveBackup();

    elseif ~isempty(strfind(lower(str), 'name'))
        header = textscan(str, '%s', 'Delimiter', ';'); % str is 'name: <name>; version: <version>'
        header = header{1};
        if length(header) < 2
            error('Unknown format of input file');
        end
        headerNameInfo = textscan(header{1}, '%s', 'Delimiter', ':');
        headerNameInfo = headerNameInfo{1};
        if ~strcmpi(headerNameInfo{1}, 'name')
            error('Input file ''%s'' is of unknown format', filename);
        end
        versionInfo = textscan(header{2}, '%s', 'Delimiter', ':');
        versionInfo = versionInfo{1};
        [verMajor, verMinor] = helpers.parseVersion(strtrim(versionInfo{2}));

        switch headerNameInfo{2}
            case 'linear track tale'
                io.readLinearInputFile(fid, header{2});
                gCurrentTrial = 1;
                return;

            case 'general'
                specificParser = sprintf('io.parseGeneral_%u_%u', verMajor, verMinor);
                if ~isempty(which(specificParser))
                    parserHandle = str2func(specificParser);
                    trials = parserHandle(fid);

                    fclose(fid);
                    backupFile = fullfile(inPath, sprintf('%s_%u_%u%s', inFile, verMajor, verMinor, inExt));
                    saveBackup();
                end

            otherwise
                error('Input file ''%s'' is of unknown format', filename);
        end

        fclose(fid);
    else
        error('Input file ''%s'' is of unknown format', filename);
    end

    % clear old data
    gBntData = {};

    %%% BRK
%     io.readGeneralInput(filename);
    readGeneralInputBRK(filename,clusterFormat);
    %%%
    
    if ~isempty(gBntData)
        gCurrentTrial = 1;
    end
    
    %%
    % Nested function which uses variables from the parent.
    % Set variable 'bakcupFile' in caller!
    function saveBackup()
        if replaceOriginal
    %         bakFile = fullfile(inPath, sprintf('%s%s.bak', inFile, inExt));
            fileWasMoved = movefile(filename, backupFile);
            if ~fileWasMoved
                % we've failed. Let's try again
                fileWasMoved = movefile(filename, backupFile);
            end
            saveName = filename;
        else
            saveName = fullfile(inPath, sprintf('%s.cfg', inFile));
            fileWasMoved = true;
        end

        if fileWasMoved
            io.saveGeneralInput(saveName, trials);
            filename = saveName;
        end
    end
end