% Want to distribute this code? Have other questions? -> sbowman@stanford.edu
function [ data ] = LoadConstitData(filename, wordMap, relationMap, hyperParams, fragment, relationIndex, theta, decoder, wordFeatures)
% Load one file of constituent-pair data.

% Append a default prefix if we don't have a full path
if isempty(strfind(filename, '/'))
    if strfind(filename, 'quant_')
        filename = ['grammars/data/', filename];
    else   
        filename = ['data-5/', filename];
    end
end

% Check whether we already loaded this file
if fragment
    [pathname, filenamePart, ext] = fileparts(filename);
    listing = dir([pathname, '/pp-', filenamePart, ext, '-final-', hyperParams.vocabName, '*']);
    if length(listing) > 0
        Log(hyperParams.statlog, ['File ', filename, ' was already processed.']);
        return
    end
end

fid = fopen(filename);
C = textscan(fid,'%s','delimiter',sprintf('\n'));
fclose(fid);

% Initialize the data array
rawData = repmat(struct('relation', 0, 'leftText', '', 'rightText', ''), ...
    length(10000), 1);

% Parse the file

nextItemNo = 1;
maxLine = length(C{1});

% Which nextItemNo was the last to be included in the last MAT file.
lastSave = 0;

% Turn on to speed up gradient checks:
% maxLine = 5;

if matlabpool('size') == 0 % checking to see if my pool is already open
    matlabpool;
end

% Iterate over examples
for line = (lastSave + 1):maxLine
    if ~isempty(C{1}{line}) 
        splitLine = textscan(C{1}{line}, '%s', 'delimiter', '\t');
        splitLine = splitLine{1};
        
        if ~(splitLine{1} == '%')
            % Skip commented lines
            if nargin > 5
                rawData(nextItemNo - lastSave).relation = zeros(length(hyperParams.numRelations), 1);
                rawData(nextItemNo - lastSave).relation(relationIndex) = ...
                    relationMap{relationIndex}(splitLine{1});
            else
                rawData(nextItemNo - lastSave).relation = relationMap(splitLine{1});
            end
            rawData(nextItemNo - lastSave).leftText = splitLine{2};
            rawData(nextItemNo - lastSave).rightText = splitLine{3};
            nextItemNo = nextItemNo + 1;
        end
    end
    if (mod(nextItemNo, 10000) == 0 && fragment)
        message = ['Lines loaded: ', num2str(nextItemNo), '/~', num2str(maxLine)];
        Log(hyperParams.statlog, message);
        data = ProcessAndSave(rawData, wordMap, lastSave, nextItemNo, filename, hyperParams, theta, decoder, wordFeatures);
        lastSave = nextItemNo - 1;
    end
end

data = ProcessAndSave(rawData, wordMap, lastSave, nextItemNo, [filename, '-final'], hyperParams, theta, decoder, wordFeatures);

end

function [ data ] = ProcessAndSave(rawData, wordMap, lastSave, nextItemNo, filename, hyperParams, theta, decoder, wordFeatures)
    numElements = nextItemNo - (lastSave + 1);

    data = repmat(struct('relation', 0, 'leftTree', Tree(), 'rightTree', Tree()), numElements, 1);

    if (hyperParams.pairInit)
        parfor dataInd = 1:numElements
          
	    [pT,hT,weights] = TreePair.makeTreePair(rawData(dataInd).leftText,rawData(dataInd).rightText,wordMap, theta, decoder, wordFeatures, hyperParams);
	    disp(weights)
	    disp(rawData(dataInd).leftText)
	    disp(rawData(dataInd).rightText)
	    data(dataInd).leftTree = pT;
            data(dataInd).rightTree = hT;
            data(dataInd).relation = rawData(dataInd).relation;
    	end
    else
        parfor dataInd = 1:numElements
            data(dataInd).leftTree = Tree.makeTree(rawData(dataInd).leftText, wordMap);
            data(dataInd).rightTree = Tree.makeTree(rawData(dataInd).rightText, wordMap);
            data(dataInd).relation = rawData(dataInd).relation;
    	end
    end


    % Turn on if further debugging is needed. Slow.
    % for i = 1:length(data)
    %     assert(~isempty(data(i).leftTree.getText()), ['Did not finish processing trees.' num2str(i)]);
    %     assert(~isempty(data(i).rightTree.getText()), ['Did not finish processing trees.' num2str(i)]);       
    % end

    [pathname, filenamePart, ext] = fileparts(filename);
    save([pathname, '/pp-', filenamePart, ext, '-', hyperParams.vocabName, '-', num2str(nextItemNo), '.mat'], 'data');
end
