%
%  Function: fExtractEq
% **********************
%  Translates a string from Osiris config to matlab equation
%
%  Inputs:
% =========
%  sEquation   :: The equation as string
%  iDim        :: Number of dimensions
%  aLims       :: Vector of limits (must be length = 2*iDim)
%
%  Outputs:
% ==========
%  stEquations :: Struct of equations in 3D (for integration)
%  

function stReturn = fExtractEq(sEquation, iDim, aLims)

    stReturn = {};

    if strcmp(sEquation, '')
        return;
    end % if

    dX1Min = aLims(1);
    dX1Max = aLims(2);
    dX2Min = aLims(3);
    dX2Max = aLims(4);
    dX3Min = aLims(5);
    dX3Max = aLims(6);
    
    %fprintf('%s\n', sEquation);

    % Does the equation have an if-statement around it?
    if strcmpi(sEquation(1:3), 'if(')

        aSplit = strsplit(sEquation(4:end-1),',');

        % If so, it should have 3 parts
        if length(aSplit) == 3

            % First part dictates limits
            aLim = strsplit(aSplit{1},'&&');
            for i=1:length(aLim)
                switch(aLim{i}(1:3))
                    case 'x1>'
                        dX1Min = str2num(aLim{i}(4:end));
                    case 'x1<'
                        dX1Max = str2num(aLim{i}(4:end));
                    case 'x2>'
                        dX2Min = str2num(aLim{i}(4:end));
                    case 'x2<'
                        dX2Max = str2num(aLim{i}(4:end));
                end % switch
            end % for

            if iDim == 2
                dX3Min = dX2Min;
                dX3Max = dX2Max;
            end % if

            % Second part is the actual equation
            sEquation = aSplit{2};

        end % if

    end % if

    % Interpret equation
    %fprintf('%s\n', sEquation);

    sX1Eq = '';
    sX2Eq = '';
    sX3Eq = '';

    if iDim == 2

        aExp = strfind(sEquation,'exp');

        if length(aExp) == 1
            sX1Eq = sEquation(1:aExp(1)-2);
            sX2Eq = sEquation(aExp(1):end);
            sX3Eq = strrep(sX2Eq,'x2','x3');
        end % if

    end % if

    % Make vector compatible
    sEquation = strrep(sEquation,'*','.*');
    sEquation = strrep(sEquation,'/','./');
    sEquation = strrep(sEquation,'^','.^');

    stReturn.Equation = sEquation;
    stReturn.Lims     = [dX1Min,dX1Max,dX2Min,dX2Max,dX3Min,dX3Max];
    stReturn.Box      = aLims;

end

