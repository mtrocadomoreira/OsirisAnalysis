
%
%  GUI :: Track Density
% *************************
%

function uiTrackDensity(oData)

    %
    %  Data Struct
    % *************
    %
    
    X.Size  = 30.0;              % Main window width in mm
    X.Lim   = [0.0 30.0];        % Initial window limits in mm
    X.Range = [0 1];             % Xi range of dataset
    X.Field = struct();          % Container for field data
    X.Name  = oData.Config.Name; % Name of dataset

    X.Sets.E1 = {};              % Container for tracking data for EField 1
    X.Sets.E2 = {};              % Container for tracking data for EField 2
    X.Sets.WB = {};              % Container for tracking data for witness beam
    X.Sets.DB = {};              % Container for tracking data for drive beam
    
    % Time Limits
    X.Limits(1) = oData.StringToDump('Start');  % Start of simulation
    X.Limits(2) = oData.StringToDump('PStart'); % Start of plasma
    X.Limits(3) = oData.StringToDump('PEnd');   % End of plasma
    X.Limits(4) = oData.StringToDump('End');    % End of simulation
    X.Dump      = X.Limits(2);
    
    % Tracking Parameters
    X.Track.Width  = 0.5;             % Width of window for polyfit
    X.Track.Pos    = X.Track.Width/2; % Initial position for tracking
    
    X.Track.Time     = [X.Limits(2) X.Limits(3)];
    X.Track.Data     = [];
    X.Track.Tracking = 0;
    
    % Tracking Settings
    X.Values.Point   = {'Zero','Minimum','Maximum'};
    X.Values.PolyFit = {'PolyFit 1','PolyFit 2','PolyFit 3','PolyFit 4','PolyFit 5'};
    X.Values.Source  = {'EField 1','EField 2','Witness Beam','Drive Beam'};

    X.Track.Point   = 3; % Default to maximum
    X.Track.PolyFit = 3; % Default to PolyFit3
    X.Track.Source  = 1; % Default to EField 1

    % Get Time Axis
    iDumps  = oData.Elements.FLD.e1.Info.Files-1;
    dPStart = oData.Config.Simulation.PlasmaStart;
    dTFac   = oData.Config.Convert.SI.TimeFac;
    dLFac   = oData.Config.Convert.SI.LengthFac;
    X.TAxis = (linspace(0.0, dTFac*iDumps, iDumps+1)-dPStart)*dLFac;
    

    %
    %  Figure
    % ********
    %
    
    fMain = gcf; clf;
    aFPos = get(fMain, 'Position');
    iH    = 770;
    
    % Set Figure Properties
    set(fMain, 'Units', 'Pixels');
    set(fMain, 'MenuBar', 'None');
    set(fMain, 'Position', [aFPos(1:2) 915 iH]);
    set(fMain, 'Name', 'Track Density');
    
    % Field and Density Classes
    oFieldE1 = [];
    oFieldE2 = [];
    oDensEB  = [];
    oDensPB  = [];
    
    % Load Initial Field
    fLoadField();

    X.Range = oFieldE1.AxisRange(1:2);
    if X.Size > X.Range(2)
        X.Size = X.Range(2);
        X.Lim(2) = X.Size;
    end % if


    %
    %  Controls
    % **********
    %
    
    % Axes
    axMain   = axes('Units','Pixels','Position',[340 iH-290 550 230]);
    axTrack  = axes('Units','Pixels','Position',[ 70 iH-700 300 250]);
    axResult = axes('Units','Pixels','Position',[450 iH-700 400 250]);
    
    uicontrol('Style','Text','String','Track Density','FontSize',20,'Position',[20 iH-50 200 35],'HorizontalAlignment','Left');

    % Main Controls

    bgCtrl = uibuttongroup('Title','Controls','Units','Pixels','Position',[20 iH-380 250 330]);
    
    uicontrol(bgCtrl,'Style','Text','String',X.Name,'FontSize',18,'Position',[10 285 225 25],'ForegroundColor',[1.00 1.00 0.00],'BackgroundColor',[0.80 0.80 0.80]); 

    uicontrol(bgCtrl,'Style','Text','String','Track Start','Position',[10 255 100 20],'HorizontalAlignment','Left');
    uicontrol(bgCtrl,'Style','Text','String','Track Stop', 'Position',[10 230 100 20],'HorizontalAlignment','Left');
    uicontrol(bgCtrl,'Style','Text','String','Source Data','Position',[10 205 100 20],'HorizontalAlignment','Left');
    uicontrol(bgCtrl,'Style','Text','String','Fit Method', 'Position',[10 180 100 20],'HorizontalAlignment','Left');
    uicontrol(bgCtrl,'Style','Text','String','Track Point','Position',[10 155 100 20],'HorizontalAlignment','Left');
    uicontrol(bgCtrl,'Style','Text','String','Track Width','Position',[10 130 100 20],'HorizontalAlignment','Left');

    uicontrol(bgCtrl,'Style','PushButton','String','<S','Position',[175 260 30 20],'Callback',{@fJump, 1});
    uicontrol(bgCtrl,'Style','PushButton','String','<P','Position',[205 260 30 20],'Callback',{@fJump, 2});
    uicontrol(bgCtrl,'Style','PushButton','String','P>','Position',[175 235 30 20],'Callback',{@fJump, 3});
    uicontrol(bgCtrl,'Style','PushButton','String','S>','Position',[205 235 30 20],'Callback',{@fJump, 4});
    uicontrol(bgCtrl,'Style','Text',      'String','mm','Position',[175 130 50 20],'HorizontalAlignment','Left');

    edtStart   = uicontrol(bgCtrl,'Style','Edit',     'String',X.Track.Time(1), 'Position',[115 260  55 20],'Callback',{@fSetStart});
    edtStop    = uicontrol(bgCtrl,'Style','Edit',     'String',X.Track.Time(2), 'Position',[115 235  55 20],'Callback',{@fSetStop});
    pumSource  = uicontrol(bgCtrl,'Style','PopupMenu','String',X.Values.Source, 'Position',[115 210 120 20],'Callback',{@fSetSource});
    pumPolyFit = uicontrol(bgCtrl,'Style','PopupMenu','String',X.Values.PolyFit,'Position',[115 185 120 20],'Callback',{@fTrackPolyFit});
    pumPoint   = uicontrol(bgCtrl,'Style','PopupMenu','String',X.Values.Point,  'Position',[115 160 120 20],'Callback',{@fTrackPoint});
    edtWidth   = uicontrol(bgCtrl,'Style','Edit',     'String',X.Track.Width,   'Position',[115 135  55 20],'Callback',{@fSetWidth});
    
    % Default Values
    pumSource.Value  = X.Track.Source;
    pumPolyFit.Value = X.Track.PolyFit;
    pumPoint.Value   = X.Track.Point;

    % Control Buttons
    btnTrack   = uicontrol(bgCtrl,'Style','PushButton','String','Start Tracking','Position',[ 10 80 225 25],'Callback',{@fStartTrack});
    btnSave    = uicontrol(bgCtrl,'Style','PushButton','String','Save Data',     'Position',[ 10 50 110 25],'Callback',{@fSaveData});
    btnPlot    = uicontrol(bgCtrl,'Style','PushButton','String','Large Plot',    'Position',[125 50 110 25],'Callback',{@fLargePlot});
    btnReset   = uicontrol(bgCtrl,'Style','PushButton','String','Reset All Data','Position',[ 10 10 225 25],'Callback',{@fResetTrack});

    % Sliders
    lblMain  = uicontrol('Style','Text','String','Window','Position',[280 iH-365 60 20],'HorizontalAlignment','Left');
    sldMain  = uicontrol('Style','Slider','Position',[340 iH-360 550 15],'Callback',{@fMainPos});
               sldMain.Min        = 0.0;
               sldMain.Max        = X.Range(2)-X.Size;
               sldMain.Value      = 0.0;
               sldMain.SliderStep = [0.02 0.2];

    lblTrack = uicontrol('Style','Text','String','Tracking','Position',[280 iH-385 60 20],'HorizontalAlignment','Left');
    sldTrack = uicontrol('Style','Slider','Position',[340 iH-380 550 15],'Callback',{@fTrackPos});
               sldTrack.Min        = X.Lim(1);
               sldTrack.Max        = X.Lim(2);
               sldTrack.Value      = X.Lim(1);
               sldTrack.SliderStep = [0.002 0.02];
    
    iWidth   = X.Track.Time(2)-X.Track.Time(1);
    lblTime  = uicontrol('Style','Text','String','Time','Position',[20 iH-415 60 20],'HorizontalAlignment','Left');
    sldTime  = uicontrol('Style','Slider','Position',[80 iH-410 810 15],'Callback',{@fTrackTime});
               sldTime.Min        = X.Track.Time(1);
               sldTime.Max        = X.Track.Time(2);
               sldTime.Value      = X.Track.Time(1);
               sldTime.SliderStep = [1/iWidth 1/iWidth];
    
    % Init

    fRefreshMain();
    fRefreshTrack();
    
    
    %
    %  Callback Functions
    % ********************
    %

    function fMainPos(uiSrc,~)
        
        dPos = uiSrc.Value;
        X.Lim = [dPos dPos+X.Size];
        
        sldTrack.Min = X.Lim(1);
        sldTrack.Max = X.Lim(2);

        % Check Values
        if sldTrack.Value < sldTrack.Min
            sldTrack.Value = sldTrack.Min;
            fTrackPos(sldTrack,0);
        end % if
        if sldTrack.Value > sldTrack.Max
            sldTrack.Value = sldTrack.Max;
            fTrackPos(sldTrack,0);
        end % if

        xlim(axMain,X.Lim);
        
    end % function

    function fTrackPos(uiSrc,~)
        
        dTrack = uiSrc.Value;
        X.Track.Pos = dTrack;
        fRefreshTrack();
        fRefreshMain();
        
    end % function

    function fStartTrack(~,~)
        
        X.Track.Data = [];
        X.Track.Tracking = 1;
        X.Track.Name = X.Values.Source{X.Track.Source};
        
        for t=X.Track.Time(1):X.Track.Time(2)
            X.Dump = t;
            oField.Time = t;
            sldTime.Value = t;
            fLoadField();
            X.Track.Pos = X.Track.Anchor;
            fRefreshMain();
            fRefreshTrack();
            drawnow;
        end % for
        
        switch(X.Track.Source)
            case 1
                X.Sets.E1 = X.Track;
            case 2
                X.Sets.E2 = X.Track;
            case 3
                X.Sets.WB = X.Track;
            case 4
                X.Sets.DB = X.Track;
        end % Switch
        
        fRefreshResult(0);
        
    end % function

    function fLargePlot(~,~)
        
        fRefreshResult(1);
        
    end % function

    function fResetTrack(~,~)
        
        X.Track.Data = [];
        X.Track.Tracking = 0;
        X.Track.Width = 0.5;
        X.Track.Pos = X.Track.Width/2;
        X.Track.Anchor = X.Track.Pos;

        X.Dump = X.Track.Time(1);
        
        sldMain.Value  = sldMain.Min;
        sldTrack.Value = sldTrack.Min;
        sldTime.Value  = X.Track.Time(1);

        X.Sets.E1 = {};
        X.Sets.E2 = {};
        X.Sets.WB = {};
        X.Sets.DB = {};

        fLoadField();
        fRefreshMain();
        fRefreshTrack();
        drawnow;

    end % function

    function fTrackTime(uiSrc,~)
        
        iTime = round(uiSrc.Value);
        X.Dump = iTime;
        fLoadField();
        if X.Track.Tracking
            X.Track.Pos = X.Track.Data(iTime);
        end % if
        fRefreshMain();
        fRefreshTrack();
        drawnow;

    end % function

    % Options
    
    function fTrackPoint(uiSrc,~)

        X.Track.Point = uiSrc.Value;
        fRefreshMain();
        fRefreshTrack();
        drawnow;
    
    end % function

    function fTrackPolyFit(uiSrc,~)

        X.Track.PolyFit = uiSrc.Value;
        fRefreshMain();
        fRefreshTrack();

    end % function

    function fSetStart(uiSrc,~)
        
        iTime = round(str2num(uiSrc.String));
        if iTime < X.Limits(1)
            iTime = X.Limits(1);
        end % if
        uiSrc.String = iTime;

        X.Track.Time(1) = iTime;
        sldTime.Min     = iTime;
        if sldTime.Value < sldTime.Min
            sldTime.Value = sldTime.Min;
        end % if
        
        fTrackTime(sldTime,0);
        
    end % function

    function fSetStop(uiSrc,~)

        iTime = round(str2num(uiSrc.String));
        if iTime > X.Limits(4)
            iTime = X.Limits(4);
        end % if
        uiSrc.String = iTime;

        X.Track.Time(2) = iTime;
        sldTime.Max     = iTime;
        if sldTime.Value > sldTime.Max
            sldTime.Value = sldTime.Max;
        end % if

        fTrackTime(sldTime,0);

    end % function

    function fSetSource(uiSrc,~)

        X.Track.Source = uiSrc.Value;
        X.Track.Tracking = 0;
        sldTime.Value = sldTime.Min;
        fTrackTime(sldTime,0);

    end % function

    function fJump(~,~,iJump)
        
        iTime = X.Limits(iJump);

        switch(iJump)
            case 1
                edtStart.String = iTime;
                fSetStart(edtStart,0);
            case 2
                edtStart.String = iTime;
                fSetStart(edtStart,0);
            case 3
                edtStop.String = iTime;
                fSetStop(edtStop,0);
            case 4
                edtStop.String = iTime;
                fSetStop(edtStop,0);
        end % switch
        
    end % function

    function fSetWidth(uiSrc,~)
        
        dWidth = abs(str2double(uiSrc.String));
        if dWidth == 0
            dWidth = X.Track.Width;
        end % if
        uiSrc.Value = dWidth;
        X.Track.Width = dWidth;
        
        fRefreshMain();
        fRefreshTrack();
        
    end % function


    %
    %  Data Functions
    % ****************
    %
    
    function fLoadField()
        
        oFieldE1 = Field(oData, 'e1', 'Units', 'SI', 'X1Scale', 'mm');
        oFieldE1.Time = X.Dump;
        X.Field.E1 = oFieldE1.Lineout(3,3);

        oFieldE2 = Field(oData, 'e2', 'Units', 'SI', 'X1Scale', 'mm');
        oFieldE2.Time = X.Dump;
        X.Field.E2 = oFieldE2.Lineout(3,3);
        
        oDensEB = Density(oData, 'EB', 'Units', 'SI', 'X1Scale', 'mm');
        oDensEB.Time = X.Dump;
        X.Field.EB = oDensEB.Lineout(3,3);

        oDensPB = Density(oData, 'PB', 'Units', 'SI', 'X1Scale', 'mm');
        oDensPB.Time = X.Dump;
        X.Field.PB = oDensPB.Lineout(3,3);

    end % function

    
    %
    %  Refresh Functions
    % *******************
    %

    function fRefreshMain()

        % EField

        switch(X.Track.Source)
            case 2
                aLine = X.Field.E2.Data;
                aAxis = X.Field.E2.X1Axis;
                aCol  = [0.7 0.7 0.0];
            otherwise
                aLine = X.Field.E1.Data;
                aAxis = X.Field.E1.X1Axis;
                aCol  = [0.0 0.7 0.0];
        end % switch
        
        dMax = max(abs(aLine));
        [dValue, sUnit] = fAutoScale(dMax, 'eV');
        dFac = dValue/dMax;
        
        dYMax = 1.1*dMax*dFac;
        dYMin = -dYMax;
        dXMin = X.Track.Pos - X.Track.Width/2;
        
        % Beams
        
        aWBeam = abs(X.Field.EB.Data);
        aDBeam = abs(X.Field.PB.Data);
        
        aWBeam = dYMax*aWBeam/max(aWBeam)+dYMin;
        aDBeam = dYMax*aDBeam/max(aDBeam)+dYMin;
        
        
        axes(axMain); cla;
        hold on;

        rectangle('Position',[dXMin dYMin X.Track.Width dYMax-dYMin], ...
                  'FaceColor',[0.9 0.9 0.9], ...
                  'EdgeColor',[0.5 0.5 0.5]);
        
        plot(aAxis, aLine*dFac, 'Color', aCol);
        plot(aAxis, aWBeam,     'Color', [0.7 0.0 0.0]);
        plot(aAxis, aDBeam,     'Color', [0.0 0.0 0.7]);

        hold off;

        xlim(X.Lim);
        ylim([dYMin dYMax]);
        
        title('Current Data Set');
        xlabel('\xi [mm]');
        ylabel(sprintf('E (%s)',sUnit));

    end % function

    function fRefreshTrack()
        
        switch(X.Track.Source)
            case 1
                aLine = X.Field.E1.Data;
                aAxis = X.Field.E1.X1Axis;
            case 2
                aLine = X.Field.E2.Data;
                aAxis = X.Field.E2.X1Axis;
            case 3
                aLine = X.Field.EB.Data;
                aAxis = X.Field.EB.X1Axis;
            case 4
                aLine = X.Field.PB.Data;
                aAxis = X.Field.PB.X1Axis;
        end % switch
        
        if X.Track.Source < 3
            dMax = max(abs(aLine));
            [dValue, sUnit] = fAutoScale(dMax, 'eV');
            dFac = dValue/dMax;
            aLine = aLine*dFac;
        else
            aLine = abs(aLine);
            aLine = aLine/max(aLine);
        end % if

        dXMin = X.Track.Pos - X.Track.Width;
        dXMax = X.Track.Pos + X.Track.Width;
        iXMin = fGetIndex(aAxis, dXMin);
        iXMax = fGetIndex(aAxis, dXMax);
        
        if X.Track.Source < 3
            dYMax = 1.1*max(abs(aLine(iXMin:iXMax)));
            dYMin = -dYMax;
        else
            dYMax =  1.05;
            dYMin = -0.05;
        end % if
        
        dFMin = X.Track.Pos - X.Track.Width/2;
        dFMax = X.Track.Pos + X.Track.Width/2;
        iFMin = fGetIndex(aAxis, dFMin);
        iFMax = fGetIndex(aAxis, dFMax);
        
        [dP,~,dMu] = polyfit(aAxis(iFMin:iFMax),aLine(iFMin:iFMax),X.Track.PolyFit);
        
        aFit = polyval(dP,(aAxis(iXMin:iXMax)-dMu(1))/dMu(2));
        aFitT = polyval(dP,(aAxis(iFMin:iFMax)-dMu(1))/dMu(2));
        
        switch(X.Track.Point)
            case 1
                [~,iTMin] = min(abs(aFitT));
                dTrack = aAxis(iFMin+iTMin-1);
            case 2
                [~,iTMin] = min(aFitT);
                dTrack = aAxis(iFMin+iTMin-1);
            case 3
                [~,iTMax] = max(aFitT);
                dTrack = aAxis(iFMin+iTMax-1);
        end % Switch
        X.Track.Anchor = dTrack;
        
        if X.Track.Tracking
            X.Track.Data(end+1) = dTrack;
        end % if
        
        axes(axTrack); cla;
        hold on;

        rectangle('Position',[dFMin dYMin dFMax-dFMin dYMax-dYMin], ...
                  'FaceColor',[0.9 0.9 0.9], ...
                  'EdgeColor',[0.5 0.5 0.5]);
        
        plot(aAxis, aLine, 'Color', [0.0 0.0 1.0]);
        plot(aAxis(iXMin:iXMax), aFit, 'Color', [1.0 0.0 0.0]);

        line([dTrack dTrack],[dYMin dYMax],'Color',[0.2 0.2 0.2]);
        
        hold off;
        
        xlim([dXMin dXMax]);
        ylim([dYMin dYMax]);

        title(sprintf('Tracking: Dump %d',X.Dump));
        xlabel('\xi [mm]');
        if X.Track.Source < 3
            ylabel(sprintf('E (%s)',sUnit));
        else
            ylabel('Q/max(Q)');
        end % if
        
    end % function

    function fRefreshResult(iNewFig)
        
        aAxis = X.TAxis(X.Track.Time(1):X.Track.Time(2));
        
        dTMax = 0.0;
        if ~isempty(X.Sets.E1)
            aDataE1 = (X.Sets.E1.Data - X.Sets.E1.Data(1))*1e-3;
            dMax = max(abs(aDataE1));
            if dMax > dTMax
                dTMax = dMax;
            end % if
        end % if
        if ~isempty(X.Sets.E2)
            aDataE2 = (X.Sets.E2.Data - X.Sets.E2.Data(1))*1e-3;
            dMax = max(abs(aDataE2));
            if dMax > dTMax
                dTMax = dMax;
            end % if
        end % if
        if ~isempty(X.Sets.WB)
            aDataWB = (X.Sets.WB.Data - X.Sets.WB.Data(1))*1e-3;
            dMax = max(abs(aDataWB));
            if dMax > dTMax
                dTMax = dMax;
            end % if
        end % if
        if ~isempty(X.Sets.DB)
            aDataDB = (X.Sets.DB.Data - X.Sets.DB.Data(1))*1e-3;
            dMax = max(abs(aDataDB));
            if dMax > dTMax
                dTMax = dMax;
            end % if
        end % if
        [dValue, sUnit] = fAutoScale(dTMax, 'm');
        dFac = dValue/dTMax;
        
        if iNewFig == 0
            axes(axResult);
            cla;
        else
            figure('IntegerHandle','Off');
        end % if;
        
        stLegend = {};
        iPlot = 1;

        hold on;
        if ~isempty(X.Sets.E1)
            plot(aAxis,aDataE1*dFac,'Color',[0.0 0.7 0.0]);
            if iNewFig == 0
                stLegend{iPlot} = 'E_{z}';
            else
                stLegend{iPlot} = 'Longitudinal EField';
            end % if
            iPlot = iPlot+1;
        end % for
        if ~isempty(X.Sets.E2)
            plot(aAxis,aDataE2*dFac,'Color',[0.7 0.7 0.0]);
            if iNewFig == 0
                stLegend{iPlot} = 'E_{r}';
            else
                stLegend{iPlot} = 'Radial EField';
            end % if
            iPlot = iPlot+1;
        end % for
        if ~isempty(X.Sets.WB)
            plot(aAxis,aDataWB*dFac,'Color',[0.7 0.0 0.0]);
            if iNewFig == 0
                stLegend{iPlot} = 'WBeam';
            else
                stLegend{iPlot} = 'Witness Beam';
            end % if
            iPlot = iPlot+1;
        end % for
        if ~isempty(X.Sets.DB)
            plot(aAxis,aDataDB*dFac,'Color',[0.0 0.0 0.7]);
            if iNewFig == 0
                stLegend{iPlot} = 'DBeam';
            else
                stLegend{iPlot} = 'Drive Beam';
            end % if
            iPlot = iPlot+1;
        end % for
        hold off;
        
        xlim([aAxis(1) aAxis(end)]);
        legend(stLegend);

        if iNewFig == 0
            title('Tracking Result');
        else
            title(sprintf('Tracking Result for %s',X.Name));
        end % if
        xlabel('z [m]');
        ylabel(sprintf('\\Delta\\xi [%s]',sUnit));
        
    end % function

end % function
