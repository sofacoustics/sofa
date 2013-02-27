function results = SOFAload(filename,varargin)
%SOFALOAD 
%   results = SOFAload(filename,ReturnType) reads all data from a SOFA file.
%   filename specifies the SOFA file from which the data is read.
%
%   ReturnType is optional and specifies whether the function returns the
%   lodaded values as a struct or as a cell array. Default value is 'struct'.
%   If ReturnType is 'struct', the function returns a struct which contains
%   one field called 'Data' for the data and additional fields for each
%   metadata value. The name of these fields are identical to the names of the metadata.
%   If ReturnType is 'cell', the function returns a cell array with
%   the following structure:
%   results{x}{y}
%   x ... number of variable
%   y = 1: variable name; y = 2: value

% SOFA API - function SOFAload
% Copyright (C) 2012 Acoustics Research Institute - Austrian Academy of Sciences
% Licensed under the EUPL, Version 1.1 or � as soon they will be approved by the European Commission - subsequent versions of the EUPL (the "Licence")
% You may not use this work except in compliance with the Licence.
% You may obtain a copy of the Licence at: http://www.osor.eu/eupl
% Unless required by applicable law or agreed to in writing, software distributed under the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the Licence for the specific language governing  permissions and limitations under the Licence. 

%% --------------------- check and prepare variables ----------------------
filename=SOFAcheckFilename(filename);

ReturnType = 'struct'; % set default value for ReturnType
if size(varargin,2)==1
	varargin = cellstr(varargin);
	ReturnType = varargin{1};
end
if ~ischar(ReturnType)
	error('ReturnType must be a string.');
end
switch ReturnType
    case 'struct'
        results = struct; % initialize struct variable
    case 'cell'
        
    otherwise
        error('ReturnType must be either ''struct'' or ''cell''.');
end

%% --------------------------- N E T C D F load ---------------------------
[varName,varContent]=NETCDFload(filename,'meta');
for ii=1:length(varName)
    if strcmp(ReturnType,'struct')
        results.(varName{ii})=varContent{ii};
    elseif strcmp(ReturnType,'cell')
        result{1}=varName{ii};
        result{2}=varContent{ii};
        results{ii}=result;
    end
end

[varName,varContent]=NETCDFload(filename,'data');
for ii=1:length(varName)
    if strcmp(ReturnType,'struct')
        results.Data.(varName{ii}(6:end))=varContent{ii};
    elseif strcmp(ReturnType,'cell')
        result{1}=['Data' varName{ii}(6:end)];
        result{2}=varContent{ii};
        results{length(results)+1}=result;
    end
end

end %of function