%
%  Function: fAnimBeamDensity
% ****************************
%  Plots density plot as animation
%
%  Inputs:
% =========
%  oData  :: OsirisData object
%  sBeam1 :: Drive beam
%  sBeam2 :: Witness beam (optional)
%  iStart :: First dump (default = 0)
%  iEnd   :: Last dump (default = end)
%
%  Options:
% ==========
%  FigureSize  :: Default [900 500]
%  DriveCut    :: Drive beam limits
%  WitnessCut  :: Witness beam limits
%

function stReturn = fAnimBeamDensity(oData, sDrive, sWitness, varargin)

    % Input/Output

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fAnimBeamDensity\n');
       fprintf(' ****************************\n');
       fprintf('  Plots density plot as animation\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData  :: OsirisData object\n');
       fprintf('  sBeam1 :: Drive beam\n');
       fprintf('  sBeam2 :: Witness beam (optional)\n');
       fprintf('\n');
       fprintf('  Options:\n');
       fprintf(' ==========\n');
       fprintf('  FigureSize  :: Default [900 500]\n');
       fprintf('  DriveCut    :: Drive beam limits\n');
       fprintf('  WitnessCut  :: Witness beam limits\n');
       fprintf('  Start       :: First dump (default = 0)\n');
       fprintf('  End         :: Last dump (default = end)\n');
       fprintf('\n');
       return;
    end % if
    
    stReturn   = {};
    sDrive     = fTranslateSpecies(sDrive);
    sWitness   = fTranslateSpecies(sWitness);
    sMovieFile = 'AnimPBDensity';

    oOpt = inputParser;
    if strcmp(sWitness, '')
        addParameter(oOpt, 'FigureSize',  [900 500]);
    else
        addParameter(oOpt, 'FigureSize',  [1200 500]);
    end % if
    addParameter(oOpt, 'DriveCut',    [  0.0, 315.0, -2.0, 2.0]);
    addParameter(oOpt, 'WitnessCut',  [217.0, 220.0, -0.3, 0.3]);
    addParameter(oOpt, 'Start',       'Start');
    addParameter(oOpt, 'End',         'End');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    iStart = fStringToDump(oData, stOpt.Start);
    iEnd   = fStringToDump(oData, stOpt.End);
    aDim   = stOpt.FigureSize;
    aB1Cut = stOpt.DriveCut;
    aB2Cut = stOpt.WitnessCut;


    % Animation Loop

    figMain = figure;
    set(figMain, 'Position', [1800-aDim(1), 1000-aDim(2), aDim(1), aDim(2)]);

    for k=iStart:iEnd

        clf;
        i = k-iStart+1;

        % Beam 1
        if ~strcmpi(sWitness, '')
            subplot(1,3,[1:2]);
        end % if
        stB1Info = fPlotBeamDensity(oData, k, sDrive, 'Limits', aB1Cut, 'CAxis', [0.0 0.01], 'IsSubPlot', 'Yes');
        colorbar('off');

        % Beam 2
        if ~strcmpi(sWitness, '')
            subplot(1,3,3);
            stB2Info = fPlotBeamDensity(oData, k, sWitness, 'Limits', aB2Cut, 'IsSubPlot', 'Yes', 'Absolute', 'Yes');
            title(sprintf('%s Density', fTranslateSpeciesReadable(sWitness)), 'FontSize', 14);
            colorbar('off');
            sMovieFile = 'AnimPBEBDensity';
        end % if

        drawnow;

        set(figMain, 'PaperUnits', 'Inches', 'PaperPosition', [1 1 aDim(1)/96 aDim(2)/96]);
        set(figMain, 'InvertHardCopy', 'Off');
        print(figMain, '-dtiffnocompression', '-r96', '/tmp/osiris-print.tif');
        M(i).cdata    = imread('/tmp/osiris-print.tif');
        M(i).colormap = [];

    end % for

    movie2avi(M, '/tmp/osiris-temp.avi', 'fps', 6, 'Compression', 'None');
    [~,~] = system(sprintf('avconv -i /tmp/osiris-temp.avi -c:v libx264 -crf 1 -s %dx%d -b:v 50000k Movies/%s-%s.mp4', aDim(1), aDim(2), sMovieFile, fTimeStamp));
    [~,~] = system('rm Movies/Temp.avi');
    
    
    % Return values
    stReturn.Movie           = M;
    stReturn.DriveBeamInfo   = stB1Info;
    stReturn.WitnessBeamInfo = stB2Info;

end % function
