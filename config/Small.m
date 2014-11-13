function [ hyperParams, options, wordMap, relationMap ] = Small(dataflag, transDepth, penult, lambda, tot, mbs, lr, trainwords, frag, pairInit)
% Configuration for experiments involving the SemEval SICK challenge and ImageFlickr 30k. 

[hyperParams, options] = Defaults();

% The dimensionality of the word/phrase vectors. Currently fixed at 25 to match
% the GloVe vectors.
hyperParams.dim = 25;

% The number of embedding transform layers. topDepth > 0 means NN layers will be
% added above the embedding matrix. This is likely to only be useful when
% learnWords is false, and so the embeddings do not exist in the same space
% the rest of the constituents do.
hyperParams.embeddingTransformDepth = transDepth;

% The dimensionality of the comparison layer(s).
hyperParams.penultDim = penult;

% Regularization coefficient.
hyperParams.lambda = lambda; % 0.002 works?;

% Use NTN layers in place of NN layers.
hyperParams.useThirdOrder = tot;
hyperParams.useThirdOrderComparison = tot;

hyperParams.loadWords = true;
hyperParams.trainWords = trainwords;

% Whether to intialise trees in pairs
hyperParams.pairInit=pairInit

% How many examples to run before taking a parameter update step on the accumulated gradients.
options.miniBatchSize = mbs;

options.lr = lr;

if findstr(dataflag, 'small')
    wordMap = ...
        InitializeMaps('sick_data/sick_words_t4.txt');
    hyperParams.vocabName = 'sot4'; 

    hyperParams.numRelations = 3;
   	hyperParams.relations = {{'ENTAILMENT', 'CONTRADICTION', 'NEUTRAL'}};
	relationMap = cell(2, 1);
	relationMap{1} = containers.Map(hyperParams.relations{1}, 1:length(hyperParams.relations{1}));

    hyperParams.trainFilenames = {'./small_data/small_train_parsed.txt'};    
    hyperParams.testFilenames = {'./small_data/small_trial_parsed.txt'};
    hyperParams.splitFilenames = {};
end

end
