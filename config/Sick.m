function [ hyperParams, options, wordMap, relationMap ] = Sick(dataflag, transDepth, topDepth, penult, lambda, tot, summing, mbs, lr, trainwords, loadwords, scale, dropout,pairInit)
% Configuration for experiments involving the SemEval SICK challenge and ImageFlickr 30k. 

[hyperParams, options] = Defaults();

% The dimensionality of the word/phrase vectors. Currently fixed at 25 to match
% the GloVe vectors.
%hyperParams.dim = 50;
hyperParams.dim = 25;

% The number of embedding transform layers. topDepth > 0 means NN layers will be
% added above the embedding matrix. This is likely to only be useful when
% learnWords is false, and so the embeddings do not exist in the same space
% the rest of the constituents do.
hyperParams.embeddingTransformDepth = transDepth;


% The number of comparison layers. topDepth > 1 means NN layers will be
% added between the RNTN composition layer and the softmax layer.
hyperParams.topDepth = topDepth;

% If set, store embedding matrix gradients as spare matrices, and only apply regularization
% to the parameters that are in use at each step.
hyperParams.fastEmbed = trainwords; % If we train words, go ahead and use it.

% Most parameters will be initialized within the range (-initScale, initScale).
hyperParams.initScale = 0.05;
hyperParams.eyeScale = scale;


% The dimensionality of the comparison layer(s).
hyperParams.penultDim = penult;

% Regularization coefficient.
hyperParams.lambda = lambda; % 0.002 works?;

% Apply dropout to the top feature vector of each tree, preserving activations
% with this probability. If this is set to 1, dropout is effectively not used.
hyperParams.dropoutPresProb = 1;

% Use NTN layers in place of NN layers.
hyperParams.useThirdOrder = tot;
hyperParams.useThirdOrderComparison = tot;

hyperParams.useSumming = summing;

hyperParams.loadWords = loadwords;
hyperParams.trainWords = trainwords;

% Whether to intialise trees in pairs
hyperParams.pairInit=pairInit
hyperParams.fragmentData = false;

% How many examples to run before taking a parameter update step on the accumulated gradients.
options.miniBatchSize = mbs;

options.lr = lr;
if findstr(dataflag, 'sick-sa')
    wordMap = ...
        InitializeMaps('sick_data/sick_words_t4.txt');
    hyperParams.vocabName = 'sot4'; 

    hyperParams.numRelations = 3;
   	hyperParams.relations = {{'ENTAILMENT', 'CONTRADICTION', 'NEUTRAL'}};
	relationMap = cell(2, 1);
	relationMap{1} = containers.Map(hyperParams.relations{1}, 1:length(hyperParams.relations{1}));

    hyperParams.bootstrapFile = '/u/nayakne/NLP-HOME/scr/vector-entailment/Sick_EA-0.0005-ed0-tr1-pen75-lr0.001/ckpt-best-tr141106191441@6700.mat';

    hyperParams.trainFilenames = {'./sick_data/SICK_train_parsed_searchAlign.txt'};    
    hyperParams.testFilenames = {'./sick_data/SICK_trial_parsed_searchAlign.txt', ...
    				 './sick_data/SICK_trial_parsed_justneg_searchAlign.txt', ...
    				 './sick_data/SICK_trial_parsed_noneg_searchAlign.txt', ...
    				 './sick_data/SICK_trial_parsed_18plusparens_searchAlign.txt', ...
    				 './sick_data/SICK_trial_parsed_lt18_parens_searchAlign.txt'};
    hyperParams.splitFilenames = {};
elseif findstr(dataflag, 'sick-ea')
    wordMap = ...
        InitializeMaps('sick_data/sick_words_t4.txt');
    hyperParams.vocabName = 'sot4'; 

    hyperParams.numRelations = 3;
   	hyperParams.relations = {{'ENTAILMENT', 'CONTRADICTION', 'NEUTRAL'}};
	relationMap = cell(2, 1);
	relationMap{1} = containers.Map(hyperParams.relations{1}, 1:length(hyperParams.relations{1}));

    hyperParams.bootstrapFile = '/u/nayakne/NLP-HOME/scr/vector-entailment/Sick_EA-0.0005-ed0-tr1-pen75-lr0.001/ckpt-best-tr141106191441@6700.mat';

    hyperParams.trainFilenames = {'./sick_data/SICK_train_parsed_exactAlign.txt'};    
    hyperParams.testFilenames = {'./sick_data/SICK_trial_parsed_exactAlign.txt', ...
    				 './sick_data/SICK_trial_parsed_justneg_exactAlign.txt', ...
    				 './sick_data/SICK_trial_parsed_noneg_exactAlign.txt', ...
    				 './sick_data/SICK_trial_parsed_18plusparens_exactAlign.txt', ...
    				 './sick_data/SICK_trial_parsed_lt18_parens_exactAlign.txt'};
    hyperParams.splitFilenames = {};
elseif findstr(dataflag, 'sick-only')
    wordMap = ...
        InitializeMaps('sick_data/combined_words.txt');
    hyperParams.vocabName = 'sick_all'; 

    hyperParams.numRelations = 3;
   	hyperParams.relations = {{'ENTAILMENT', 'CONTRADICTION', 'NEUTRAL'}};
	relationMap = cell(1, 1);
	relationMap{1} = containers.Map(hyperParams.relations{1}, 1:length(hyperParams.relations{1}));
    
	hyperParams.bootstrapFile = '/u/nayakne/scr/vector-entailment/Sick_Only-0.0005-ed0-tr1-pen75-lr0.001/ckpt-best-tr141106191634@5900.mat';

    hyperParams.trainFilenames = {'./sick_data/SICK_train_parsed.txt'};    
    hyperParams.testFilenames = {'./sick_data/SICK_trial_parsed.txt', ...
    				 './sick_data/SICK_trial_parsed_justneg.txt', ...
    				 './sick_data/SICK_trial_parsed_noneg.txt', ...
    				 './sick_data/SICK_trial_parsed_18plusparens.txt', ...
    				 './sick_data/SICK_trial_parsed_lt18_parens.txt'};
    hyperParams.splitFilenames = {};
elseif strcmp(dataflag, 'sick-plus-10k')
    % The number of relations.
    hyperParams.numRelations = [3 2];

    hyperParams.relations = {{'ENTAILMENT', 'CONTRADICTION', 'NEUTRAL'}, {'ENTAILMENT', 'NONENTAILMENT'}};
    relationMap = cell(2, 1);
    relationMap{1} = containers.Map(hyperParams.relations{1}, 1:length(hyperParams.relations{1}));
    relationMap{2} = containers.Map(hyperParams.relations{2}, 1:length(hyperParams.relations{2}));

    wordMap = ...
        InitializeMaps('sick_data/sick_plus_words_flickr_t4.txt');
    hyperParams.vocabName = 'comt4';

    hyperParams.trainFilenames = {'./sick_data/SICK_train_parsed.txt', ...
                      '/scr/nlp/data/ImageFlickrEntailments/shuffled_clean_parsed_entailment_pairs_10k.tsv'};
    hyperParams.testFilenames = {'./sick_data/SICK_trial_parsed.txt', ...
                     './sick_data/SICK_trial_parsed_justneg.txt', ...
                     './sick_data/SICK_trial_parsed_noneg.txt', ...
                     './sick_data/SICK_trial_parsed_18plusparens.txt', ...
                     './sick_data/SICK_trial_parsed_lt18_parens.txt', ...
                     './sick_data/denotation_graph_training_subsample.tsv'};
    hyperParams.splitFilenames = {};
    % Use different classifiers for the different data sources.
    hyperParams.relationIndices = [1, 2, 0, 0, 0, 0; 1, 1, 1, 1, 1, 2; 0, 0, 0, 0, 0, 0];
elseif strcmp(dataflag, 'sick-plus-100k')
    % The number of relations.
    hyperParams.numRelations = [3 2];

    hyperParams.relations = {{'ENTAILMENT', 'CONTRADICTION', 'NEUTRAL'}, {'ENTAILMENT', 'NONENTAILMENT'}};
    relationMap = cell(2, 1);
    relationMap{1} = containers.Map(hyperParams.relations{1}, 1:length(hyperParams.relations{1}));
    relationMap{2} = containers.Map(hyperParams.relations{2}, 1:length(hyperParams.relations{2}));

    wordMap = ...
        InitializeMaps('sick_data/sick_plus_words_flickr_t4.txt');
    hyperParams.vocabName = 'comt4';

    hyperParams.trainFilenames = {'./sick_data/SICK_train_parsed.txt', ...
                      '/scr/nlp/data/ImageFlickrEntailments/shuffled_clean_parsed_entailment_pairs_100k.tsv'};
    hyperParams.testFilenames = {'./sick_data/SICK_trial_parsed.txt', ...
                     './sick_data/SICK_trial_parsed_justneg.txt', ...
                     './sick_data/SICK_trial_parsed_noneg.txt', ...
                     './sick_data/SICK_trial_parsed_18plusparens.txt', ...
                     './sick_data/SICK_trial_parsed_lt18_parens.txt', ...
                     './sick_data/denotation_graph_training_subsample.tsv'};
    hyperParams.splitFilenames = {};
    % Use different classifiers for the different data sources.
    hyperParams.relationIndices = [1, 2, 0, 0, 0, 0; 1, 1, 1, 1, 1, 2; 0, 0, 0, 0, 0, 0];
    hyperParams.fragmentData = false;
elseif strcmp(dataflag, 'sick-plus-600k')
    % The number of relations.
    hyperParams.numRelations = [3 2];

    hyperParams.relations = {{'ENTAILMENT', 'CONTRADICTION', 'NEUTRAL'}, {'ENTAILMENT', 'NONENTAILMENT'}};
    relationMap = cell(2, 1);
    relationMap{1} = containers.Map(hyperParams.relations{1}, 1:length(hyperParams.relations{1}));
    relationMap{2} = containers.Map(hyperParams.relations{2}, 1:length(hyperParams.relations{2}));

    wordMap = ...
        InitializeMaps('sick_data/sick_plus_words_flickr_t4.txt');
    hyperParams.vocabName = 'comt4';

    hyperParams.trainFilenames = {'./sick_data/SICK_train_parsed.txt', ...
                      '/scr/nlp/data/ImageFlickrEntailments/shuffled_clean_parsed_entailment_pairs_600k.tsv'};
    hyperParams.testFilenames = {'./sick_data/SICK_trial_parsed.txt', ...
                     './sick_data/SICK_trial_parsed_justneg.txt', ...
                     './sick_data/SICK_trial_parsed_noneg.txt', ...
                     './sick_data/SICK_trial_parsed_18plusparens.txt', ...
                     './sick_data/SICK_trial_parsed_lt18_parens.txt', ...
                     './sick_data/denotation_graph_training_subsample.tsv'};
    hyperParams.splitFilenames = {};
    % Use different classifiers for the different data sources.
    hyperParams.relationIndices = [1, 2, 0, 0, 0, 0; 1, 1, 1, 1, 1, 2; 0, 0, 0, 0, 0, 0];
elseif strcmp(dataflag, 'sick-plus')
    % The number of relations.
    hyperParams.numRelations = [3 2];

	hyperParams.relations = {{'ENTAILMENT', 'CONTRADICTION', 'NEUTRAL'}, {'ENTAILMENT', 'NONENTAILMENT'}};
	relationMap = cell(2, 1);
	relationMap{1} = containers.Map(hyperParams.relations{1}, 1:length(hyperParams.relations{1}));
	relationMap{2} = containers.Map(hyperParams.relations{2}, 1:length(hyperParams.relations{2}));

    wordMap = ...
        InitializeMaps('sick_data/sick_plus_words_flickr_t4.txt');
    hyperParams.vocabName = 'comt4';

    hyperParams.trainFilenames = {'./sick_data/SICK_train_parsed.txt', ...
     				  '/scr/nlp/data/ImageFlickrEntailments/clean_parsed_entailment_pairs.tsv'};
    hyperParams.testFilenames = {'./sick_data/SICK_trial_parsed.txt', ...
    				 './sick_data/SICK_trial_parsed_justneg.txt', ...
    				 './sick_data/SICK_trial_parsed_noneg.txt', ...
    				 './sick_data/SICK_trial_parsed_18plusparens.txt', ...
    				 './sick_data/SICK_trial_parsed_lt18_parens.txt', ...
    				 './sick_data/denotation_graph_training_subsample.tsv'};
    hyperParams.splitFilenames = {};
    % Use different classifiers for the different data sources.
    hyperParams.relationIndices = [1, 2, 0, 0, 0, 0; 1, 1, 1, 1, 1, 2; 0, 0, 0, 0, 0, 0];
    hyperParams.fragmentData = true;
elseif strcmp(dataflag, 'imageflickr')
    % The number of relations.
    hyperParams.numRelations = 4; 

    hyperParams.relations = {{'ENTAILMENT', 'na', 'na2', 'NONENTAILMENT'}};
	relationMap = cell(1, 1);
	relationMap{1} = containers.Map(hyperParams.relations{1}, 1:length(hyperParams.relations{1}));

    wordMap = InitializeMaps('sick_data/flickr_words_t4.txt');
    hyperParams.vocabName = 'spt4b';

    hyperParams.trainFilenames = {'/scr/nlp/data/ImageFlickrEntailments/clean_parsed_entailment_pairs.tsv'};
    hyperParams.testFilenames = {'/scr/nlp/data/ImageFlickrEntailments/clean_parsed_entailment_pairs_first500.tsv', ...
    				 './sick_data/clean_parsed_entailment_pairs_second10k_first500.tsv'};
    hyperParams.splitFilenames = {};
    hyperParams.fragmentData = true;
elseif strcmp(dataflag, 'imageflickrshort')
    % The number of relations.
    hyperParams.numRelations = 2; 

    hyperParams.relations = {{'ENTAILMENT', 'NONENTAILMENT'}};
	relationMap = cell(1, 1);
	relationMap{1} = containers.Map(hyperParams.relations{1}, 1:length(hyperParams.relations{1}));

    wordMap = InitializeMaps('sick_data/flickr_words_t4.txt');
    hyperParams.vocabName = 'spt4-2cl';

    hyperParams.splitFilenames = {'/scr/nlp/data/ImageFlickrEntailments/shuffled_clean_parsed_entailment_pairs_10k.tsv'};
    hyperParams.testFilenames = {'/scr/nlp/data/ImageFlickrEntailments/clean_parsed_entailment_pairs_first500.tsv', ...
    				 './sick_data/clean_parsed_entailment_pairs_second10k_first500.tsv'};
    hyperParams.trainFilenames = {};
elseif strcmp(dataflag, 'imageflickrshort100')
    % The number of relations.
    hyperParams.numRelations = 2; 

    hyperParams.relations = {{'ENTAILMENT', 'NONENTAILMENT'}};
    relationMap = cell(1, 1);
    relationMap{1} = containers.Map(hyperParams.relations{1}, 1:length(hyperParams.relations{1}));

    wordMap = InitializeMaps('sick_data/flickr_words_t4.txt');
    hyperParams.vocabName = 'spt4-2cl';

    hyperParams.splitFilenames = {'/scr/nlp/data/ImageFlickrEntailments/shuffled_clean_parsed_entailment_pairs_100k.tsv'};
    hyperParams.testFilenames = {'/scr/nlp/data/ImageFlickrEntailments/clean_parsed_entailment_pairs_first500.tsv', ...
                     './sick_data/clean_parsed_entailment_pairs_second10k_first500.tsv'};
    hyperParams.trainFilenames = {};
end

end
