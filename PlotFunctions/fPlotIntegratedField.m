
%
%  Function: fPlotIntegratedField
% ********************************
%  Plots the integrated field from OsirisData
%
%  Inputs:
% =========
%  oData  :: OsirisData object
%  sTime  :: Time dump
%  sField :: Which field to look at
%
%  Options:
% ==========
%  VLim        :: Vertical axis limits
%  FigureSize  :: Default [900 500]
%  HideDump    :: Default No
%  IsSubplot   :: Default No
%  AutoResize  :: Default On
%  CAxis       :: Color axis limits
%  ShowOverlay :: Default Yes
%

function stReturn = fPlotIntegratedField(oData, sField, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
        fprintf('\n');
        fprintf('  Function: fPlotIntegratedField\n');
        fprintf(' ********************************\n');
        fprintf('  Plots the integrated field from OsirisData\n');
        fprintf('\n');
        fprintf('  Inputs:\n');
        fprintf(' =========\n');
        fprintf('  oData  :: OsirisData object\n');
        fprintf('  sTime  :: Time dump\n');
        fprintf('  sField :: Which field to look at\n');
        fprintf('\n');
        fprintf('  Options:\n');
        fprintf(' ==========\n');
        fprintf('  VLim        :: Vertical axis limits\n');
        fprintf('  FigureSize  :: Default [900 500]\n');
        fprintf('  HideDump    :: Default No\n');
        fprintf('  IsSubplot   :: Default No\n');
        fprintf('  AutoResize  :: Default On\n');
        fprintf('  CAxis       :: Color axis limits\n');
        fprintf('  ShowOverlay :: Default Yes\n');
        fprintf('  Start       :: Default Plasma Start\n');
        fprintf('  End         :: Default Plasma End\n');
        fprintf('\n');
        return;
    end % if

    vField = oData.Translate.Lookup(sField,'Field');

    oOpt = inputParser;
    addParameter(oOpt, 'VLim',        []);
    addParameter(oOpt, 'FigureSize',  [900 500]);
    addParameter(oOpt, 'HideDump',    'No');
    addParameter(oOpt, 'IsSubPlot',   'No');
    addParameter(oOpt, 'AutoResize',  'On');
    addParameter(oOpt, 'CAxis',       []);
    addParameter(oOpt, 'ShowOverlay', 'Yes');
    addParameter(oOpt, 'Start',       'PStart');
    addParameter(oOpt, 'End',         'PEnd');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    if ~isempty(stOpt.VLim) && length(stOpt.VLim) ~= 2
        fprintf(2, 'Error: Limits specified, but must be of dimension 2.\n');
        return;
    end % if
    
    if ~vField.isField
        fprintf(2, 'Error: Non-existent field specified.\n');
        return;
    end % if
    
    % Prepare Data

    if vField.isField
        oFLD = Field(oData, vField.Name, 'Units', 'SI', 'X1Scale', 'mm', 'X2Scale', 'mm');
    else
        fprintf(2, 'Error: Only E-fields are supported.\n');
        return;
    end % if

    switch(vField.Name)
        case 'e1'
            if ~isempty(stOpt.VLim)
                oFLD.X1Lim = stOpt.VLim;
            end % if
        case 'e2'
            if ~isempty(stOpt.VLim)
                oFLD.X2Lim = stOpt.VLim;
            end % if
        case 'e3'
            fprintf(2, 'Error: Only 2D fields are supported.\n');
            return;
    end % switch
    
    stData = oFLD.Integral(stOpt.Start, stOpt.End);

    aData  = stData.Integral;
    aVAxis = stData.VAxis;
    aTAxis = stData.TAxis;
    
    dPeak  = max(abs(aData(:)));
    [dTemp, sFUnit] = fAutoScale(dPeak, 'eV');
    dScale = dTemp/dPeak;

    stReturn.HAxis     = stData.TAxis;
    stReturn.VAxis     = stData.VAxis;
    stReturn.AxisFac   = stData.AxisFac;
    stReturn.AxisRange = stData.AxisRange;
    
    % Plot
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Integrated Field (%s)',oData.Config.Name))
    else
        cla;
    end % if

    imagesc(aTAxis, aVAxis, aData*dScale);
    set(gca,'YDir','Normal');
    polarmap(jet,0.5);
    hCol = colorbar();
    if ~isempty(stOpt.CAxis)
        caxis(stOpt.CAxis);
    end % if

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('Integrated %s (%s)',vField.Full,oData.Config.Name);
    else
        sTitle = sprintf('Integrated %s',vField.Full);
    end % if

    title(sTitle);
    xlabel('z [m]');
    ylabel('\xi [mm]');
    title(hCol,sprintf('%s',sFUnit));
    
    
    % Return

    stReturn.Field = vField.Name;
    stReturn.XLim  = xlim;
    stReturn.YLim  = ylim;
    stReturn.CLim  = caxis;

end % function
