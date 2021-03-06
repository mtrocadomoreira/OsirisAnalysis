
%
%  Class Object :: Momentum
% **************************
%  SubClass of OsirisType
%
%  Description:
%    A class to analyse and handle Osiris data related to the momentum and
%    energy of particles.
%
%  Constructor:
%    oData    : OsirisDara object
%    sSpecies : What species to study
%    Parameter pairs:
%      Units   : 'N', 'SI' or 'CGS'
%      X1Scale : Unit scale on x1 axis. 'Auto', or specify metric unit
%      X2Scale : Unit scale on x2 axis. 'Auto', or specify metric unit
%      X3Scale : Unit scale on x3 axis. 'Auto', or specify metric unit
%      Scale   : Unit scale on all axes. 'Auto', or specify metric unit
%
%  Set Methods:
%    Time      : Set time dump for dataset. Default is 0.
%    X1Lim     : 2D array of limits for x1 axis. Default is full box.
%    X2Lim     : 2D array of limits for x2 axis. Default is full box.
%    X3Lim     : 2D array of limits for x3 axis. Default is full box.
%    SliceAxis : 2D slice axis for 3D data
%    Slice     : 2D slice coordinate for 3D data
%
%  Public Methods:
%    SigmaEToEMean    : Returns a dataset with mean energy and spread.
%    Evolution        : Returns a dataset of momentum along an axis as a
%                       function of time (plasma length).
%    BeamSlip         : Returns a dataset of information on beam slipping.
%    PhaseSpace       : Returns a dataset with information on beam emittance
%                       or emittance-like properties.
%

classdef Momentum < OsirisType

    %
    % Properties
    %

    properties(GetAccess='public', SetAccess='public')
        
        % None

    end % properties

    %
    % Constructor
    %

    methods
        
        function obj = Momentum(oData, sSpecies, varargin)
            
            % Call OsirisType constructor
            obj@OsirisType(oData, sSpecies, varargin{:});

        end % function
        
    end % methods

    %
    % Public Methods
    %
    
    methods(Access='public')
        
        function stReturn = SigmaEToEMean(obj, sStart, sEnd, varargin)

            % Input/Output
            stReturn = {};

            if nargin < 2
                sStart = 'Start';
            end % if

            if nargin < 3
                sEnd = 'End';
            end % if
            
            % Check that the object is initialised
            if obj.fError
                return;
            end % if

            % Calculate range
            iStart = obj.Data.StringToDump(sStart);
            iEnd   = obj.Data.StringToDump(sEnd);

            oOpt = inputParser;
            addParameter(oOpt, 'Relative', 'No');
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;

            % Calculate axes
            aTAxis = obj.fGetTimeAxis;
            aTAxis = aTAxis(iStart+1:iEnd+1);
            
            if strcmpi(stOpt.Relative, 'Yes')
                dEInit = obj.fMomentumToEnergy(obj.Data.Config.Particles.Species.(obj.Species.Name).Momentum(1));
            else
                dEInit = 0.0;
            end % if
            
            aMean  = zeros(1, length(aTAxis));
            aSigma = zeros(1, length(aTAxis));
            aData  = zeros(1, length(aTAxis));
            
            for i=iStart:iEnd
                
                k = i-iStart+1;
                
                aRaw = obj.Data.Data(i, 'RAW', '', obj.Species.Name);
                if isempty(aData)
                    return;
                end % if
                
                if length(aRaw(:,8)) == 1 && aRaw(1,8) == 0
                    aMean(k)  = 0.0;
                    aSigma(k) = 0.0;
                    aData(k)  = 0.0;
                else
                    aMean(k)  = obj.fMomentumToEnergy(wmean(aRaw(:,4), abs(aRaw(:,8))))-dEInit;
                    aSigma(k) = obj.fMomentumToEnergy(wstd(aRaw(:,4), abs(aRaw(:,8))));
                    aData(k)  = aSigma(k)/aMean(k);
                end % if
                
            end % for
            
            % Return data
            stReturn.TAxis = aTAxis;
            stReturn.Mean  = aMean;
            stReturn.Sigma = aSigma;
            stReturn.Data  = aData;

        end % function

        function stReturn = Evolution(obj, sAxis, sStart, sEnd, varargin)

            % Input/Output
            stReturn = {};
            
            if nargin < 3
                sStart = 'Start';
            end % if

            if nargin < 4
                sEnd = 'End';
            end % if
            
            % Check that the object is initialised
            if obj.fError
                return;
            end % if

            iStart = obj.Data.StringToDump(sStart);
            iEnd   = obj.Data.StringToDump(sEnd);

            oOpt = inputParser;
            addParameter(oOpt, 'Percentile', []);
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            
            % Read simulation data
            dEMass = obj.Data.Config.Constants.EV.ElectronMass;

            % Calculate axes
            aTAxis = obj.fGetTimeAxis;
            aTAxis = aTAxis(iStart+1:iEnd+1);

            stReturn.TAxis = aTAxis;

            switch(fMomentumAxis(sAxis))
                case 'p1'
                    iAxis = 4;
                case 'p2'
                    iAxis = 5;
                case 'p3'
                    iAxis = 6;
            end % switch
            
            for i=iStart:iEnd
                
                k = i-iStart+1;

                aRaw = obj.Data.Data(i, 'RAW', '', obj.Species.Name)*dEMass;
                if isempty(aRaw)
                    return;
                end % if

                stReturn.Average(k) = double(wmean(aRaw(:,iAxis),aRaw(:,8)));
                stReturn.Median(k)  = wprctile(aRaw(:,iAxis),50,abs(aRaw(:,8)));
                
                if ~isempty(stOpt.Percentile)
                    for p=1:length(stOpt.Percentile)
                        c = stOpt.Percentile(p);
                        if c < 1 || c > 100
                            continue;
                        end % if
                        sSet = sprintf('Percentile%d', c);
                        stReturn.(sSet)(k) = wprctile(aRaw(:,iAxis),c,abs(aRaw(:,8)));
                    end % for
                end % if

            end % for
    
        end % function

        function stReturn = BeamSlip(obj, sStart, sEnd, dAdd)

            % Input/Output
            stReturn = {};

            if nargin < 2
                sStart = 'Start';
            end % if

            if nargin < 3
                sEnd = 'End';
            end % if

            if nargin < 4
                dAdd = 0.0;
            end % if
            
            % Check that the object is initialised
            if obj.fError
                return;
            end % if

            iStart = obj.Data.StringToDump(sStart);
            iEnd   = obj.Data.StringToDump(sEnd);
            
            % Variables
            dLFac     = obj.AxisFac(1);
            dTimeStep = obj.Data.Config.Simulation.TimeStep;
            iNDump    = obj.Data.Config.Simulation.NDump;
            dDeltaZ   = dTimeStep*iNDump;
            
            for i=iStart:iEnd
                
                k = i-iStart+1;

                aRaw = obj.Data.Data(i, 'RAW', '', obj.Species.Name);
                if isempty(aRaw)
                    return;
                end % if

                stReturn.Slip.Average(k)           = (dDeltaZ - dDeltaZ*sqrt(1-1/wmean(aRaw(:,4),aRaw(:,8))^2))*dLFac;
                stReturn.Slip.Median(k)            = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRaw(:,4),50,abs(aRaw(:,8)))^2))*dLFac;
                stReturn.Slip.Percentile10(k)      = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRaw(:,4),10,abs(aRaw(:,8)))^2))*dLFac;
                stReturn.Slip.Percentile90(k)      = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRaw(:,4),90,abs(aRaw(:,8)))^2))*dLFac;
                stReturn.Slip.FirstQuartile(k)     = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRaw(:,4),25,abs(aRaw(:,8)))^2))*dLFac;
                stReturn.Slip.ThirdQuartile(k)     = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRaw(:,4),75,abs(aRaw(:,8)))^2))*dLFac;

                stReturn.Position.Average(k)       = (wmean(aRaw(:,1),aRaw(:,8))-(i*dDeltaZ))*dLFac;
                stReturn.Position.Median(k)        = (wprctile(aRaw(:,1),50,abs(aRaw(:,8)))-(i*dDeltaZ))*dLFac;
                stReturn.Position.Percentile10(k)  = (wprctile(aRaw(:,1),10,abs(aRaw(:,8)))-(i*dDeltaZ))*dLFac;
                stReturn.Position.Percentile90(k)  = (wprctile(aRaw(:,1),90,abs(aRaw(:,8)))-(i*dDeltaZ))*dLFac;
                stReturn.Position.FirstQuartile(k) = (wprctile(aRaw(:,1),25,abs(aRaw(:,8)))-(i*dDeltaZ))*dLFac;
                stReturn.Position.ThirdQuartile(k) = (wprctile(aRaw(:,1),75,abs(aRaw(:,8)))-(i*dDeltaZ))*dLFac;
                
                if k > 1
                    stReturn.ExpectedPos.Average(k)       = stReturn.Position.Average(1)       - sum(stReturn.Slip.Average(1:k-1));
                    stReturn.ExpectedPos.Median(k)        = stReturn.Position.Median(1)        - sum(stReturn.Slip.Median(1:k-1));
                    stReturn.ExpectedPos.Percentile10(k)  = stReturn.Position.Percentile10(1)  - sum(stReturn.Slip.Percentile10(1:k-1));
                    stReturn.ExpectedPos.Percentile90(k)  = stReturn.Position.Percentile90(1)  - sum(stReturn.Slip.Percentile90(1:k-1));
                    stReturn.ExpectedPos.FirstQuartile(k) = stReturn.Position.FirstQuartile(1) - sum(stReturn.Slip.FirstQuartile(1:k-1));
                    stReturn.ExpectedPos.ThirdQuartile(k) = stReturn.Position.ThirdQuartile(1) - sum(stReturn.Slip.ThirdQuartile(1:k-1));
                else
                    stReturn.ExpectedPos.Average(1)       = stReturn.Position.Average(1);
                    stReturn.ExpectedPos.Median(1)        = stReturn.Position.Median(1);
                    stReturn.ExpectedPos.Percentile10(1)  = stReturn.Position.Percentile10(1);
                    stReturn.ExpectedPos.Percentile90(1)  = stReturn.Position.Percentile90(1);
                    stReturn.ExpectedPos.FirstQuartile(1) = stReturn.Position.FirstQuartile(1);
                    stReturn.ExpectedPos.ThirdQuartile(1) = stReturn.Position.ThirdQuartile(1);
                end % if
                
                % Slip if added energy
                stReturn.Slip.AverageAdd(k) = (dDeltaZ - dDeltaZ*sqrt(1-1/(dAdd + wmean(aRaw(:,4),aRaw(:,8)))^2))*dLFac;
                stReturn.Slip.MedianAdd(k)  = (dDeltaZ - dDeltaZ*sqrt(1-1/(dAdd + wprctile(aRaw(:,4),50,abs(aRaw(:,8))))^2))*dLFac;
                if k > 1
                    stReturn.ExpectedAdd.Average(k) = stReturn.Position.Average(1) - sum(stReturn.Slip.AverageAdd(1:k-1));
                    stReturn.ExpectedAdd.Median(k)  = stReturn.Position.Median(1)  - sum(stReturn.Slip.MedianAdd(1:k-1));
                else
                    stReturn.ExpectedAdd.Average(1) = stReturn.Position.Average(1);
                    stReturn.ExpectedAdd.Median(1)  = stReturn.Position.Median(1);
                end % if
                
            end % for
            
            aTAxis = obj.fGetTimeAxis;
            
            stReturn.DeltaZ = dDeltaZ;
            stReturn.TAxis  = aTAxis(iStart+1:iEnd+1);
    
        end % function

        function stReturn = PhaseSpace(obj, varargin)
            %
            %  Function: Momentum.PhaseSpace
            % *******************************
            %
            %  Inputs:
            % =========
            %  Species and time defined by class settings.
            %
            %  Options:
            % ==========
            %  Samples [integer]
            %          How many times to sample each particle. Useful when one axis is monte carlo sampled. Default 1.
            %  MinParticles [integer]
            %          Minimum number of particles to use for statistics. If there is not enough particles, the
            %          particles are sampled several times w/monet carlo. Default 100000.
            %  Histogram [Yes/No]
            %          Whether to use fixed bins like in a histogram. Default behaviour is to deposit the charge on
            %          a sample grid. Default 'no'.
            %  Grid [2-vector, integer]
            %          The dimension of the hisorgram or deposit grid.
            %  Dimension [Rad/RadToX/X/Y]
            %          Which dimension to calculate the angle on.
            %          [Rad]    The radial axis alone.
            %          [RadToX] Projecting r and theta onto x by sampling theta.
            %          [X], [Y] The x or y axis alone.
            %          Defaults to RadToX for cylindrical and X for cartesian simulations.
            %  Slice [2-vector, float]
            %          Excludes all macro particles outside the defind limits. Units defined by class setting Units, and
            %          Scale parameter. Default is none, i.e. all particles.
            %  SliceAxis [1/2/3]
            %          Which axis to slice along. Setting is ignored if Slice is not defined. Defaults to 1.
            %
            %  Outputs:
            % ==========
            %  Raw        :: The macroparticles used in the calculation
            %  X          :: The x axis values
            %  XUnit      :: The unit of the x axis
            %  XPrime     :: The x prime axis (angle)
            %  XPrimeUnit :: The unit of the x prime axis
            %  Charge     :: The charge of the macroparticles used
            %  Weight     :: The aprticle weights
            %  Covariance :: The covariance matrix
            %  ERMS       :: The RMS emittance
            %  ERMSError  :: The standard error of the emittance
            %  ENorm      :: The normalised emittance
            %  ENormError :: The standard error of the normalised emittance
            %  GammaBeta  :: The mean gamma * beta of the particles
            %  Alpha      :: The alpha twiss parameter
            %  Beta       :: The beta twiss parameter
            %  Gamma      :: The gamma twiss parameter
            %

            % Input/Output
            stReturn       = {};
            stReturn.Error = '';

            % Check that the object is initialised
            if obj.fError
                return;
            end % if

            oOpt = inputParser;
            addParameter(oOpt, 'Samples',      1);
            addParameter(oOpt, 'MinParticles', 100000);
            addParameter(oOpt, 'Histogram',    'No');
            addParameter(oOpt, 'Grid',         [1000 1000]);
            addParameter(oOpt, 'Dimension',    '');
            addParameter(oOpt, 'Slice',        '');
            addParameter(oOpt, 'SliceAxis',    1);
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            
            if isempty(stOpt.Dimension)
                if obj.Cylindrical
                    iDim   = 2;
                else
                    iDim   = 3;
                end % if
            else
                if     strcmpi(stOpt.Dimension, 'Rad')
                    iDim   = 1;
                elseif strcmpi(stOpt.Dimension, 'RadToX')
                    iDim   = 2;
                elseif strcmpi(stOpt.Dimension, 'X')
                    iDim   = 3;
                elseif strcmpi(stOpt.Dimension, 'Y')
                    iDim   = 4;
                else
                    iDim   = 1;
                end % if
            end % if

            aRaw = obj.Data.Data(obj.Time,'RAW','',obj.Species.Name);
            if isempty(aRaw)
                stReturn.Error = 'No initial data.';
                return;
            end % if
            aRaw = obj.fRawToXi(aRaw);
            
            % Slice data if requested
            if ~isempty(stOpt.Slice)
                if stOpt.SliceAxis >= 1 && stOpt.SliceAxis <= 7 && numel(stOpt.Slice) == 2
                    if stOpt.SliceAxis <= 3
                        aSlice = stOpt.Slice/obj.AxisFac(stOpt.SliceAxis);
                    end % if
                    if stOpt.SliceAxis > 3 && stOpt.SliceAxis <= 7
                        dFac   = obj.Data.Config.Constants.EV.ElectronMass;
                        dFac   = dFac*abs(obj.Config.RQM);
                        aSlice = stOpt.Slice/dFac;
                    end % if
                    aRaw = obj.fPruneRaw(aRaw,stOpt.SliceAxis,aSlice(1),aSlice(2));
                end % if
            end % if

            if isempty(aRaw)
                stReturn.Error = 'No data after cut.';
                return;
            end % if

            aP   = sqrt(aRaw(:,4).^2 + aRaw(:,5).^2 + aRaw(:,6).^2);
            iLen = length(aP);
            
            aRX  = [];
            aRXP = [];
            aRQ  = [];

            iMin = ceil(stOpt.MinParticles/iLen);
            if stOpt.Samples < iMin
                iS = iMin;
            else
                iS = stOpt.Samples;
            end % if
            aERMS  = zeros(iS, 1);
            aENorm = zeros(iS, 1);
            aGamBe = zeros(iS, 1);
            
            for s=1:iS

                if obj.Dim == 2
                    aXth = rand(size(aRaw,1),1)*2*pi;
                else
                    aXth = aRaw(:,3);
                end % if

                if obj.Cylindrical
                    aPz = aRaw(:,4);
                    aPr = aRaw(:,5);
                    aPt = aRaw(:,6);
                    if iDim == 2
                        aPx = aPr.*cos(aXth) - aPt.*sin(aXth);
                    else
                        aPx = aPr;
                    end % if
                    aT  = aXth-pi;
                    aX  = aRaw(:,2).*(aT./abs(aT))*obj.AxisFac(2);
                    aQ  = aRaw(:,8)./aRaw(:,2)*obj.Data.Config.Convert.SI.ChargeFac;
                else
                    aPz = aRaw(:,4);
                    if iDim == 4
                        aPx = aRaw(:,6);
                        aX  = aRaw(:,3)*obj.AxisFac(3);
                    else
                        aPx = aRaw(:,5);
                        aX  = aRaw(:,2)*obj.AxisFac(2);
                    end % if
                    aQ  = aRaw(:,8)*obj.Data.Config.Convert.SI.ChargeFac;
                end % if
 
                aXPrime    = tan(aPx./aPz)*1e3;
                aCov       = wcov([aX, aXPrime], abs(aQ));
                dGammaBeta = wmean(aPz, abs(aQ));
                aERMS(s)   = sqrt(det(aCov));
                aENorm(s)  = sqrt(det(aCov))*dGammaBeta;
                aGamBe(s)  = dGammaBeta;
            
                % Preallocating these could speed up the function
                aRX  = [aRX;aX];
                aRXP = [aRXP;aXPrime];
                aRQ  = [aRQ;aQ];

            end % for
            
            iNE = length(aERMS) - 1;
            iNE = iNE + (iNE == 0);
            
            dERMS  = mean(aERMS);
            dENorm = mean(aENorm);
            
            stReturn.Raw        = aRaw;
            stReturn.X          = aRX;
            stReturn.XUnit      = obj.AxisUnits{1};
            stReturn.XPrime     = aRXP;
            stReturn.XPrimeUnit = 'mrad';
            stReturn.Charge     = aRQ;
            stReturn.Weight     = abs(aRQ)/max(abs(aRQ));
            stReturn.Covariance = aCov;
            stReturn.ERMS       = dERMS;
            stReturn.ERMSError  = 1.96*std(aERMS)/sqrt(iNE);
            stReturn.ENorm      = dENorm;
            stReturn.ENormError = 1.96*std(aENorm)/sqrt(iNE);
            stReturn.GammaBeta  = mean(aGamBe);
            stReturn.ZPos       = obj.fGetZPos();
            stReturn.Count      = length(aRX);
            stReturn.RawCount   = length(aRaw);

            % Twiss parameters
            stReturn.Alpha      = aCov(1,2)/dERMS;
            stReturn.Beta       = aCov(1,1)/dERMS;
            stReturn.Gamma      = aCov(2,2)/dERMS;

            if strcmpi(stOpt.Histogram, 'No')
                return;
            end % if
            
            aHist   = zeros(stOpt.Grid(1),stOpt.Grid(2));
            
            dXMax   = max(abs(aRX));
            dXPMax  = max(abs(aRXP));
            dXMin   = -dXMax;
            dXPMin  = -dXPMax;
            
            % Check if angle is 0 (no emittance)
            if dXPMax == 0

                stReturn.Error = 'Maximum particle angle is 0.';
                stReturn.Hist  = [];
                stReturn.HAxis = [];
                stReturn.VAxis = [];
                stReturn.Count = 0;
                
                return;

            end % if
                
            dDX     = dXMax/((stOpt.Grid(1)-2)/2);
            dDXP    = dXPMax/((stOpt.Grid(2)-2)/2);
            aM      = floor(aRX/dDX)+(stOpt.Grid(1)/2)+1;
            aN      = floor(aRXP/dDXP)+(stOpt.Grid(2)/2)+1;

            for i=1:length(aM)
                aHist(aM(i),aN(i)) = aHist(aM(i),aN(i)) + aRQ(i);
            end % for

            stReturn.Hist  = abs(transpose(aHist))*1e9;
            stReturn.HAxis = linspace(dXMin,dXMax,stOpt.Grid(1));
            stReturn.VAxis = linspace(dXPMin,dXPMax,stOpt.Grid(2));
            
        end % function
    
    end % methods

end % classdef
