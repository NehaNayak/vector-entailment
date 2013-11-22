function [ cost, grad, pred ] = ComputeCostAndGrad( theta, decoder, dataPoint, hyperParams )
%function [ cost, grad ] = ComputeCostAndGrad( theta, decoder, dataPoint, hyperParams )
%   Detailed explanation goes here

% Unpack theta.
[classifierMatrices, classifierMatrix, classifierBias, ...
    classifierParameters, wordFeatures, compositionMatrices,...
    compositionMatrix, compositionBias] ...
    = stack2param(theta, decoder);

% Unpack hyperparams.
NUM_RELATIONS = hyperParams.numRelations;
PENULT_DIM = hyperParams.penultDim;
DIM = hyperParams.dim;

leftTree = dataPoint.leftTree;
rightTree = dataPoint.rightTree;
trueRelation = dataPoint.relation;

% Make sure word features are current.
leftTree.updateFeatures(wordFeatures, compositionMatrices, ...
        compositionMatrix, compositionBias);
rightTree.updateFeatures(wordFeatures, compositionMatrices, ...
        compositionMatrix, compositionBias);

leftFeatures = leftTree.getFeatures();
rightFeatures = rightTree.getFeatures();

% Use the tensor layer to build classifier input:
tensorInnerOutput = ComputeInnerTensorLayer(leftFeatures, ...
    rightFeatures, classifierMatrices, classifierMatrix, classifierBias);
tensorOutput = Sigmoid(tensorInnerOutput);

relationProbs = ComputeSoftmaxProbabilities(tensorOutput, classifierParameters);

% Increment local error
cost = Objective(trueRelation, relationProbs);

if nargout > 1
    % Initialize the gradients.
    localSoftmaxGradient = zeros(NUM_RELATIONS, PENULT_DIM + 1);
    localWordFeatureGradients = sparse([], [], [], ...
        size(wordFeatures, 1), size(wordFeatures, 2), 10);
    
    localCompositionMatricesGradients = zeros(DIM , DIM * DIM);
    localCompositionMatrixGradients = zeros(DIM, 2 * DIM);
    localCompositionBiasGradients = zeros(DIM, 1);
    
    % Compute node softmax error, mid-left of p6 of tensor paper
    targetRelationProbs = zeros(length(relationProbs), 1);
    targetRelationProbs(trueRelation) = 1;
    softmaxDeltaFirstHalf = classifierParameters' * ...
                            (relationProbs - targetRelationProbs);
    softmaxDeltaSecondHalf = SigmoidDeriv([1; tensorOutput]); % Intercept
    softmaxDelta = (softmaxDeltaFirstHalf .* softmaxDeltaSecondHalf);
    
    for relEval = 1:NUM_RELATIONS
        % Del from ufldl wiki on softmax
        localSoftmaxGradient(relEval, :) = -([1; tensorOutput] .* ...
            ((trueRelation == relEval) - relationProbs(relEval)))';
    end
    
    softmaxDelta = softmaxDelta(2:PENULT_DIM+1);

    [localClassificationMatricesGradients, ...
        localClassificationMatrixGradients, ...
        localClassificationBiasGradients, classifierDeltaLeft, ...
        classifierDeltaRight] = ...
      ComputeTensorLayerGradients(leftFeatures, rightFeatures, ...
          classifierMatrices, classifierMatrix, classifierBias, ...
          softmaxDelta);
          
    [ upwardWordGradients, ...
      upwardCompositionMatricesGradients, ...
      upwardCompositionMatrixGradients, ...
      upwardCompositionBiasGradients ] = ...
       leftTree.getGradient(classifierDeltaLeft, wordFeatures, ...
                            compositionMatrices, compositionMatrix, ...
                            compositionBias);
                        
    localWordFeatureGradients = localWordFeatureGradients ...
        + upwardWordGradients;
    localCompositionMatricesGradients = localCompositionMatricesGradients...
        + upwardCompositionMatricesGradients;
    localCompositionMatrixGradients = localCompositionMatrixGradients...
        + upwardCompositionMatrixGradients;
    localCompositionBiasGradients = localCompositionBiasGradients...
        + upwardCompositionBiasGradients;
                         
    [ upwardWordGradients, ...
      upwardCompositionMatricesGradients, ...
      upwardCompositionMatrixGradients, ...
      upwardCompositionBiasGradients ] = ...
       leftTree.getGradient(classifierDeltaRight, wordFeatures, ...
                            compositionMatrices, compositionMatrix, ...
                            compositionBias);
    localWordFeatureGradients = localWordFeatureGradients ...
        + upwardWordGradients;
    localCompositionMatricesGradients = localCompositionMatricesGradients...
        + upwardCompositionMatricesGradients;
    localCompositionMatrixGradients = localCompositionMatrixGradients...
        + upwardCompositionMatrixGradients;
    localCompositionBiasGradients = localCompositionBiasGradients...
        + upwardCompositionBiasGradients;
    
    % Pack up gradients.
    grad = param2stack(localClassificationMatricesGradients, ...
        localClassificationMatrixGradients, ...
        localClassificationBiasGradients, localSoftmaxGradient, ...
        localWordFeatureGradients, localCompositionMatricesGradients, ...
        localCompositionMatrixGradients, localCompositionBiasGradients);
end

% Compute prediction if requested.
if nargout > 2
    [~, pred] = max(relationProbs);
end

end

