% Want to distribute this code? Have other questions? -> sbowman@stanford.edu
function relationProbs = ComputeRelationProbs(theta, decoder, dataPoint, constWordFeatures, hyperParams)
% Compute cost, gradient, and predicted label for one example.

% Unpack theta
[classifierMatrices, classifierMatrix, classifierBias, ...
    classifierParameters, trainedWordFeatures, compositionMatrices,...
    compositionMatrix, compositionBias, classifierExtraMatrix, ...
    classifierExtraBias, embeddingTransformMatrix, embeddingTransformBias] ...
    = stack2param(theta, decoder);

if hyperParams.trainWords
    wordFeatures = trainedWordFeatures;
else
    wordFeatures = constWordFeatures;
end

DIM = hyperParams.dim;

% Set the number of composition functions
if ~hyperParams.untied
    NUMCOMP = 1;
else
    NUMCOMP = 3;
end

NUMTRANS = size(embeddingTransformMatrix, 3);

leftTree = dataPoint.leftTree;
rightTree = dataPoint.rightTree;
trueRelation = dataPoint.relation;

relationRange = ComputeRelationRange(hyperParams, trueRelation);

% Make sure word features are current
leftTree.updateFeatures(wordFeatures, compositionMatrices, ...
        compositionMatrix, compositionBias, embeddingTransformMatrix, embeddingTransformBias, hyperParams.compNL);
rightTree.updateFeatures(wordFeatures, compositionMatrices, ...
        compositionMatrix, compositionBias, embeddingTransformMatrix, embeddingTransformBias, hyperParams.compNL);

leftFeatures = leftTree.getFeatures();
rightFeatures = rightTree.getFeatures();

% Compute classification tensor layer
if hyperParams.useThirdOrderComparison
    tensorInnerOutput = ComputeInnerTensorLayer(leftFeatures, ...
        rightFeatures, classifierMatrices, classifierMatrix, classifierBias);
    classTensorOutput = hyperParams.classNL(tensorInnerOutput);
else
    innerOutput = classifierMatrix * [leftFeatures; rightFeatures]...
          + classifierBias;
    classTensorOutput = hyperParams.classNL(innerOutput);  
end
       
% Run layers forward
extraInputs = zeros(hyperParams.penultDim, hyperParams.topDepth);
extraInnerOutputs = zeros(hyperParams.penultDim, hyperParams.topDepth - 1);
extraInputs(:,1) = classTensorOutput;
for layer = 1:(hyperParams.topDepth - 1) 
    extraInnerOutputs(:,layer) = (classifierExtraMatrix(:,:,layer) ...
                                    * extraInputs(:,layer)) + ...
                                    classifierExtraBias(:,layer);
    extraInputs(:,layer + 1) = hyperParams.classNL(extraInnerOutputs(:,layer));
end
relationProbs = ComputeSoftmaxProbabilities( ...
                    extraInputs(:,hyperParams.topDepth), classifierParameters, relationRange);
