% GUI to check BNT positions for errors, and exclude extra points if
% necessary. Works with BNT mat file ending in 'posClean' and overwrites
% the same file when points are excluded.
%
%   USAGE
%       minions.trackerChecker
%
%   SEE ALSO
%       data.getPositions
%
% Written by BRK 2017

function trackerCheckerReplace

%% create GUI
h.fig = figure('name','Position tracker checker','color',[0.85 0.85 0.85],'unit','norm');
set(h.fig,'position',[0 0 1 1])

% select masterMat file to extract folder names
h.butt_chooseMaster = uicontrol(h.fig,'style','pushbutton', ...
    'string','Select masterMat', ...
    'fontsize',15, ...
    'units','normalized', ...
    'position',[0.01 0.87 0.2 0.1], ...
    'callback',@populateListbox);

% select single folder
h.butt_chooseFolder = uicontrol(h.fig,'style','pushbutton', ...
    'string','Select folder(s)', ...
    'fontsize',15, ...
    'units','normalized', ...
    'position',[0.25 0.87 0.2 0.1], ...
    'callback',@populateListbox);

% list of available folders
h.listbox = uicontrol(h.fig,'style','listbox', ...
    'units','normalized', ...
    'position',[0.01 0.01 0.45 0.85], ...
    'min',0,'max',1, ... % allow one selection only
    'value',1, ...
    'callback',@sessionSelect);

% cut out bad position samples
h.butt_drawROI = uicontrol(h.fig,'style','pushbutton', ...
    'string','Exclude bad points', ...
    'fontsize',15, ...
    'units','normalized', ...
    'position',[0.55 0.87 0.3 0.1], ...
    'callback',@drawROI);
h.text = uicontrol(h.fig,'style','text', ...
    'units','normalized', ...
    'position',[0.55 0.805 0.3 0.05], ...
    'fontsize',12, ...
    'backgroundcolor',h.fig.Color, ...
    'string',sprintf('You can zoom or pan even during ROI selection\nby toggling on/off the buttons on the toolbar.'));

% show tracking data
h.axes = axes('position',[0.5 0.25 0.40 0.55],'xticklabels','','yticklabels','');

%% fill listbox with folder(s)
    function populateListbox(hObject,eventData)
        
        if strcmpi(eventData.Source.String,'Select masterMat')
            [name,path] = uigetfile('*.mat','Choose masterMat','multiselect','off');
            if name == 0; return; end;
            
            L = load(fullfile(path,name));
            raw = L.dataOutput;
            labels = L.labels;
            h.folders = unique(extract.cols(raw,labels,'folder'),'stable');
        else % not masterMat
            h.folders = uipickfilesBRK();
            if isnumeric(h.folders); return; end;
        end
        set(h.listbox,'value',1)
        set(h.listbox,'string',h.folders)
        sessionSelect();
        
    end

%% when you click on a folder
    function sessionSelect(varargin)
        
        msg = msgbox('Loading position data...');
        selected = get(h.listbox,'value');
        h.currFolder = h.folders{selected};
        [h.TimeStamps,h.ExtractedX,h.ExtractedY,h.ExtractedAngle,h.Targets,h.Points,h.Header] = io.neuralynx.Nlx2MatVT(fullfile(h.currFolder,'VT1.nvt'),[1 1 1 1 1 1],1,1);
        positions = [h.TimeStamps',h.ExtractedX',h.ExtractedY'];
        [dTargets, trackingColour] = io.neuralynx.decodeTargets(h.Targets);
        [frontX, frontY, backX, backY] = io.neuralynx.extractPosition(dTargets, trackingColour);
        if length(frontX) ~= 1
            ind = find(frontX == 0 & frontY == 0);
            frontX(ind) = NaN;
            frontY(ind) = NaN;
            ind = find(backX == 0 & backY == 0);
            backX(ind) = NaN;
            backY(ind) = NaN;
            positions(:, 2) = frontX';
            positions(:, 3) = frontY';
            positions(:, 4) = backX';
            positions(:, 5) = backY';
        end
        
        close(msg);
        plot(h.axes,positions(:,2),positions(:,3),'ro-','markers',3)
        hold on
        plot(h.axes,positions(:,4),positions(:,5),'go-','markers',3)
        hold off
        set(gca,'ydir','reverse')
        h.positions = positions;
               
    end

%% draw polygon to exclude some points
    function drawROI(varargin)
        
        try
            axes(h.axes);
            h1 = impoly;
            nodes = wait(h1);
            if isempty(nodes); return; end;
            try
                delete(h1)
            end
            positions = h.positions;
            toKeep = inpolygon(positions(:,2),positions(:,3),nodes(:,1),nodes(:,2));
            toKeep2 = inpolygon(positions(:,4),positions(:,5),nodes(:,1),nodes(:,2));
            positions(~toKeep | ~toKeep2,2:end) = nan;
                        
            plot(h.axes,positions(:,2),positions(:,3),'ro-','markers',3)
            hold on
            plot(h.axes,positions(:,4),positions(:,5),'go-','markers',3)
            hold off
            set(gca,'ydir','reverse')
            drawnow
            h.positions = positions;
            
            msg = msgbox('Writing position data...');
            % backup of original data
            copyfile(fullfile(h.currFolder,'VT1.nvt'),fullfile(h.currFolder,sprintf('VT1 copy %s.nvt',datestr(clock,30))))
            % write new data
%             h.ExtractedX(~toKeep | ~toKeep2) = nan;
%             h.ExtractedY(~toKeep | ~toKeep2) = nan;
%             h.ExtractedAngle(~toKeep | ~toKeep2) = nan;
            h.Targets(:,~toKeep | ~toKeep2) = 0;
            h.Points(:,~toKeep | ~toKeep2) = 0;
            io.neuralynx.Mat2NlxVT(fullfile(h.currFolder,'VT1.nvt'),0,1,1,[1 1 1 1 1 1 1],h.TimeStamps,h.ExtractedX,h.ExtractedY,h.ExtractedAngle,h.Targets,h.Points,h.Header)
            close(msg);
            
        catch MSG
            cla(h.axes)
            warning('Positions not saved!')
            rethrow(MSG)
        end
    end

end