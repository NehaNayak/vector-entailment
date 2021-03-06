% Want to distribute this code? Have other questions? -> sbowman@stanford.edu
function TrainModel(dataflag, pretrainingFilename, expName, mbs, dim, penult, lr, lambda, tot, transDepth, loadwords, dsp, fold)
% The main training and testing script. The first arguments to the function
% have been tweaked quite a few times depending on what is being tuned.

% If the fold number is grater than one, the train/test split on split data will 
% be offset accordingly.
hyperParams.foldNumber = fold;

% The name assigned to the current full run. Used in checkpoint naming, and must
% match the directory created above.
hyperParams.name = [expName,  '-fold', num2str(hyperParams.foldNumber)];

% Set up an experimental directory.
if nargin > 4
    mkdir(hyperParams.name); 
else
    expName = '.';
end
hyperParams.statlog = fopen([hyperParams.name '/stat_log'], 'a');
hyperParams.examplelog = fopen([hyperParams.name '/example_log'], 'a');

% Load the vocabulary.
if strcmp(dataflag, 'and-or') ||  strcmp(dataflag, 'and-or-deep') ||  strcmp(dataflag, 'and-or-deep-unlim')
    [wordMap, relationMap, relations] = ...
        LoadTrainingData('./RC/train1');
    % The name assigned to the current vocabulary. Used in deciding whether to load a 
    % preparsed MAT form of an examples file.
    hyperParams.vocabName = 'RC'; 
elseif findstr(dataflag, 'G-')
    [wordMap, relationMap, relations] = ...
        InitializeMaps('./grammars/wordlist.tsv', dataflag); 
    hyperParams.vocabName = 'G'
elseif strcmp(dataflag, 'gradcheck')
    [wordMap, relationMap, relations] = ...
        InitializeMaps('./grammars/wordlist.tsv', dataflag); 
    hyperParams.vocabName = 'G'
elseif findstr(dataflag, 'sick-only')
    [wordMap, relationMap, relations] = ...
        InitializeMaps('sick_data/sick_words_t4.txt', dataflag);
    hyperParams.vocabName = 'sot4'; 
elseif findstr(dataflag, 'sick-') or findstr(dataflag, 'imageflickr') 
    [wordMap, relationMap, relations] = ...
        InitializeMaps('sick_data/flickr_words_t4.txt', dataflag);
    hyperParams.vocabName = 'spt4'; 
elseif findstr(dataflag, 'word-relations')
    [wordMap, relationMap, relations] = ...
        InitializeMaps('word-relations/google-10000-english.txt', dataflag);
    hyperParams.vocabName = 'g10000'; 
elseif findstr(dataflag, 'synset-relations')
    [wordMap, relationMap, relations] = ...
        InitializeMaps('synset-relations/longer_wordlist.txt', dataflag);
    hyperParams.vocabName = 'synset'; 
else
    [wordMap, relationMap, relations] = ...
        LoadTrainingData('./wordpairs-v2.tsv');
    hyperParams.vocabName = 'quantv2'; 
end

%%% Set up the model configuration:
% The dimensionality of the word/phrase vectors.
hyperParams.dim = dim;

% The number of embedding transform layers. topDepth > 0 means NN layers will be
% added above the embedding matrix. This is likely to only be useful when
% learnWords is false, and so the embeddings do not exist in the same space
% the rest of the constituents do.
hyperParams.embeddingTransformDepth = transDepth;

% Don't keep the whole training data in memory, rather keep it in the form of
% a set of MAT files to load as needed.
hyperParams.fragmentData = false;

if findstr(dataflag, 'sick-')
    % The number of relations.
    hyperParams.numRelations = [3 2]; 

    % Initialize word vectors from disk.
    hyperParams.loadWords = true;
    hyperParams.trainWords = loadwords;
elseif findstr(dataflag, 'word-relations')
    hyperParams.numRelations = [4]; 

    % Initialize word vectors from disk.
    hyperParams.loadWords = true;
    hyperParams.trainWords = false;

    % Don't keep the whole training data in memory, rather keep it in the form of
    % a set of MAT files to load as needed.
    hyperParams.fragmentData = false;
elseif findstr(dataflag, 'synset-relations')
    hyperParams.numRelations = [3]; 

    % Initialize word vectors from disk.
    hyperParams.loadWords = loadwords;
    hyperParams.trainWords = true;

    % Don't keep the whole training data in memory, rather keep it in the form of
    % a set of MAT files to load as needed.
    hyperParams.fragmentData = false;
else
    hyperParams.numRelations = [7]; 
    hyperParams.loadWords = false;
    hyperParams.trainWords = true;
    hyperParams.fragmentData = false;
end

% The number of comparison layers. topDepth > 1 means NN layers will be
% added between the RNTN composition layer and the softmax layer.
hyperParams.topDepth = 1;

% The dimensionality of the comparison layer(s).
hyperParams.penultDim = penult;

% Regularization coefficient.
hyperParams.lambda = lambda; %0.002;

% A vector of text relation labels.
hyperParams.relations = relations;

% Turn off to pretrain on the word pair dataset.
hyperParams.noPretraining = true;

% Use minFunc instead of SGD. Must be separately downloaded.
hyperParams.minFunc = false;

% L1 v. L2 regularization. If no regularization is needed, set
% lambda to 0 and ignore this parameter.
hyperParams.norm = 2;

% Use the syntactically untied composition layer params.
hyperParams.untied = false; 

% Use only the specified fraction of the training datasets
hyperParams.datasetsPortion = 1;
if nargin > 11
    hyperParams.dataPortion = dsp;
else
    hyperParams.dataPortion = 1;
end
    

% Use NTN layers in place of NN layers.
hyperParams.useThirdOrder = tot;
hyperParams.useThirdOrderComparison = tot;

% Nonlinearities.
hyperParams.compNL = @Sigmoid;
hyperParams.compNLDeriv = @SigmoidDeriv; 
nl = 'M';
if strcmp(nl, 'S')
    hyperParams.classNL = @Sigmoid;
    hyperParams.classNLDeriv = @SigmoidDeriv;
elseif strcmp(nl, 'M')
    hyperParams.classNL = @LReLU;
    hyperParams.classNLDeriv = @LReLUDeriv;
end

% Ignore: modified every few iters.
hyperParams.showExamples = false; 
hyperParams.showConfusions = false;

Log(hyperParams.statlog, ['Model config: ' evalc('disp(hyperParams)')])

%%% minFunc options:
global options
options.Method = 'lbfgs';
options.MaxFunEvals = 1000;
options.DerivativeCheck = 'on';
options.Display = 'full';
options.numDiff = 0;
options.LS_init = '2'; % Attempt to minimize evaluations per step...
options.PlotFcns = [];
% options.OutputFcn = @Display;  % Custom error reporting for minFunc

%%% AdaGradSGD learning options
% Rarely does anything interesting happen past 
% ~iteration ~200.
options.numPasses = 32;
options.miniBatchSize = mbs;

%%% Generic learning options
% LR
options.lr = lr;    % 0.2;

% How often (in steps) to report cost.
options.costFreq = 500;

% How often (in steps) to run on test data.
options.testFreq = 100;

% How often to report confusion matrices. 
% Should be a multiple of testFreq.
options.confusionFreq = 500;

% How often to display which items are misclassified.
% Should be a multiple of testFreq.
options.examplesFreq = 1000; 

% How often (in steps) to save parameters to disk.
options.checkpointFreq = 32000; 

% The name assigned to the current full run. Used in checkpoint naming, and must
% match the directory created above.
options.name = hyperParams.name; 

% The name assigned to the current call to AdaGradSGD. This can be used to
% distinguish multiple phases of training in the same experiment.
options.runName = 'pre';

% Reset the sum of squared gradients after this many iterations.
% WARNING: The countdown to a reset will be restarted if the model dies
% and is reloaded from a checkpoint.
options.resetSumSqFreq = 500000; % Don't bother.

Log(hyperParams.statlog, ['Model training options: ' evalc('disp(options)')])

% Get a full listing of the data files for this experiment
listing = dir('data-4/*.tsv');
listing5 = dir('data-5/*.tsv');
listingG = dir('grammars/data/quant*');

% Choose which files to train on
splitFilenames = {listing.name};
trainFilenames = {};
testFilenames = {};

if strcmp(dataflag, 'sub-tn')
    testFilenames = {'MQ-three-no-bark.tsv', 'MQ-three-no-European.tsv', ...
        'MQ-three-no-mobile.tsv'};
    splitFilenames = {listing5.name};
elseif strcmp(dataflag, 'pair-tn')
    listing = [dir('data-5/*three-no*'); dir('data-5/*no-three*')];
    testFilenames = {'MQ-three-no-bark.tsv', listing.name};
    splitFilenames = {listing5.name};
elseif strcmp(dataflag, 'sub-nmn')
    testFilenames = {'NEG-MQ-R2-most-no-bark.tsv'};
    splitFilenames = {listing5.name};
elseif strcmp(dataflag, 'pair-nmn')
    listing = [dir('data-5/*most-no*'); dir('data-5/*no-most*')];
    testFilenames = {'NEG-MQ-R2-most-no-bark.tsv', listing.name};
    splitFilenames = {listing5.name};
elseif strcmp(dataflag, 'sub-ts')
    testFilenames = {'MT-MQ-two-some-2-French-Parisian-rev.tsv'};
    splitFilenames = {listing5.name};
elseif strcmp(dataflag, 'pair-ts')
    listing = [dir('data-5/*two-some*'); dir('data-5/*some-two*')];
    testFilenames = {'MT-MQ-two-some-2-French-Parisian-rev.tsv', listing.name};
    splitFilenames = {listing5.name};

elseif strcmp(dataflag, 'G-two_lt_two')
    testFilenames = {'grammars/data/quant_two_lt_two'};
    splitFilenames = {listingG.name};
elseif strcmp(dataflag, 'G-no_no')
    testFilenames = {'grammars/data/quant_no_no'};
    splitFilenames = {listingG.name};
elseif strcmp(dataflag, 'G-not_all_not_most')
    testFilenames = {'grammars/data/quant_not_all_not_most'};
    splitFilenames = {listingG.name};
elseif strcmp(dataflag, 'G-all_some')
    testFilenames = {'grammars/data/quant_all_some'};
    splitFilenames = {listingG.name};
elseif strcmp(dataflag, 'G-splitall')
    splitFilenames = {listingG.name};
elseif strcmp(dataflag, 'splitall-5')
    splitFilenames = {listing5.name};
elseif strcmp(dataflag, 'one-mn')
    testFilenames = {'MQ-most-no-bark.tsv'};
elseif strcmp(dataflag, 'sub-mn')
    testFilenames = {'MQ-most-no-bark.tsv', 'MQ-most-no-European.tsv', ...
        'MQ-most-no-mobile.tsv'};
elseif strcmp(dataflag, 'pair-mn')
    listing = [dir('data-4/*no-most*'); dir('data-4/*most-no*')];
    testFilenames = {listing.name};
elseif strcmp(dataflag, 'one-sn')
    testFilenames = {'BQ-some-no-bark.tsv'};
elseif strcmp(dataflag, 'sub-sn') 
    testFilenames = {'BQ-some-no-bark.tsv', 'BQ-some-no-European.tsv', ...
        'BQ-some-no-mobile.tsv'};
elseif strcmp(dataflag, 'pair-sn')
    listing = [dir('data-4/*some-no*'); dir('data-4/*no-some*')];
    testFilenames = {listing.name};
elseif strcmp(dataflag, 'one-2a')
    testFilenames = {'MQ-two-all-bark.tsv'};
elseif strcmp(dataflag, 'sub-2a') 
    testFilenames = {'MQ-two-all-bark.tsv', 'MQ-two-all-European.tsv', ...
        'MQ-two-all-mobile.tsv'};
elseif strcmp(dataflag, 'pair-2a')
    listing = [dir('data-4/*two-all*'); dir('data-4/*all-two*')];
    testFilenames = {listing.name};
elseif strcmp(dataflag, 'splitall')
    splitFilenames = {listing.name};
elseif strcmp(dataflag, 'testall')
    trainFilenames = splitFilenames;
    splitFilenames = {};
elseif strcmp(dataflag, 'gradcheck')
    splitFilenames = {'./grammars/test_file.tsv'};
    hyperParams.dim = 2;
    hyperParams.penultDim = 2;
    hyperParams.minFunc = 1; %%%
elseif strcmp(dataflag, 'test')
    splitFilenames = {'MQ-two-all-bark.tsv'};
elseif strcmp(dataflag, 'and-or') 
    trainFilenames = {'./RC/train0', './RC/train1', './RC/train2', './RC/train3', './RC/train4'};
    testFilenames = {'./RC/test0', './RC/test1', './RC/test2', './RC/test3', './RC/test4', './RC/test5', './RC/test6'};
    splitFilenames = {};
    options.numPasses = 15000;
    if ~isempty(pretrainingFilename)
        hyperParams.penultDim = 45;
    end
elseif strcmp(dataflag, 'and-or-deep') 
    trainFilenames = {'./RC/longer2/train0', './RC/longer2/train1', './RC/longer2/train2', './RC/longer2/train3', './RC/longer2/train4'};
    testFilenames = {'./RC/longer2/test0', './RC/longer2/test1', './RC/longer2/test2', './RC/longer2/test3', './RC/longer2/test4', './RC/longer2/test5', './RC/longer2/test6', './RC/longer2/test7', './RC/longer2/test8', './RC/longer2/test9', './RC/longer2/test10', './RC/longer2/test11', './RC/longer2/test12'};
    splitFilenames = {};
    options.numPasses = 15000;
    if ~isempty(pretrainingFilename)
        hyperParams.penultDim = 45;
    end
elseif strcmp(dataflag, 'and-or-deep-unlim') 
    trainFilenames = {'./RC/longer2/train0', './RC/longer2/train1', './RC/longer2/train2', './RC/longer2/train3', './RC/longer2/train4', './RC/longer2/train5', './RC/longer2/train6', './RC/longer2/train7', './RC/longer2/train8', './RC/longer2/train9', './RC/longer2/train10', './RC/longer2/train11', './RC/longer2/train12'}; 
    testFilenames = {'./RC/longer2/test0', './RC/longer2/test1', './RC/longer2/test2', './RC/longer2/test3', './RC/longer2/test4', './RC/longer2/test5', './RC/longer2/test6', './RC/longer2/test7', './RC/longer2/test8', './RC/longer2/test9', './RC/longer2/test10', './RC/longer2/test11', './RC/longer2/test12'};
    splitFilenames = {};
    options.numPasses = 15000;
    if ~isempty(pretrainingFilename)
        hyperParams.penultDim = 45;
    end
elseif strcmp(dataflag, 'sick-only') 
    trainFilenames = {'./sick_data/SICK_train_parsed.txt'};    
    testFilenames = {'./sick_data/SICK_trial_parsed.txt', './sick_data/SICK_trial_parsed_justneg.txt', './sick_data/SICK_trial_parsed_noneg.txt', './sick_data/SICK_trial_parsed_18plusparens.txt', './sick_data/SICK_trial_parsed_lt18_parens.txt'};
    splitFilenames = {};
elseif strcmp(dataflag, 'sick-plus') 
    trainFilenames = {'./sick_data/SICK_train_parsed.txt', '/scr/nlp/data/ImageFlickrEntailments/clean_parsed_entailment_pairs.tsv'};
    testFilenames = {'./sick_data/SICK_trial_parsed.txt', './sick_data/SICK_trial_parsed_justneg.txt', './sick_data/SICK_trial_parsed_noneg.txt', './sick_data/SICK_trial_parsed_18plusparens.txt', './sick_data/SICK_trial_parsed_lt18_parens.txt', './sick_data/denotation_graph_training_subsample.tsv'};
    splitFilenames = {};
    % Use different classifiers for the different data sources.
    hyperParams.relationIndices = [1, 2, 0, 0, 0, 0; 1, 1, 1, 1, 1, 2; 0, 0, 0, 0, 0, 0];
    hyperParams.fragmentData = true;
elseif strcmp(dataflag, 'imageflickr') 
    trainFilenames = {'/scr/nlp/data/ImageFlickrEntailments/clean_parsed_entailment_pairs.tsv'};
    testFilenames = {'/scr/nlp/data/ImageFlickrEntailments/clean_parsed_entailment_pairs_first500.tsv', './sick_data/denotation_graph_training_subsample.tsv'};
    splitFilenames = {};
    % Use different classifiers for the different data sources.
    % hyperParams.relationIndices = [1, 2, 0, 0, 0, 0; 1, 1, 1, 1, 1, 2; 0, 0, 0, 0, 0, 0];
    hyperParams.fragmentData = true;
elseif strcmp(dataflag, 'word-relations') 
    trainFilenames = {};
    testFilenames = {};
    splitFilenames = {'./word-relations/shuffled_word_relations.tsv'};
elseif strcmp(dataflag, 'synset-relations') 
    trainFilenames = {};
    testFilenames = {};
    splitFilenames = {'./synset-relations/longer_shuffled_synset_relations.tsv'};
end

% Remove the test data from the split data
splitFilenames = setdiff(splitFilenames, testFilenames);

% TODO
hyperParams.firstSplit = 3;

% Trim out data files if needed
if hyperParams.datasetsPortion < 1
    p = randperm(length(splitFilenames));
    splitFilenames = splitFilenames(p(1:round(hyperParams.datasetsPortion * length(splitFilenames))));
end

% Load saved parameters if available
savedParams = '';
if ~isempty(pretrainingFilename)
    savedParams = pretrainingFilename;
else
    listing = dir([options.name, '/', 'ckpt-tr@*']);
    if ~isempty(listing)
        savedParams = [options.name, '/', listing(end).name];
    end
end
if ~isempty(savedParams)
    Log(hyperParams.statlog, ['Loading parameters: ' savedParams]);
    a = load(savedParams);
    modelState = a.modelState;
else
    modelState.step = 0;
    Log(hyperParams.statlog, ['Randomly initializing.']);
    [ modelState.theta, modelState.thetaDecoder, modelState.constWordFeatures ] = ...
       InitializeModel(wordMap, hyperParams);
end

% Load training/test data
[trainDataset, testDatasets] = ...
    LoadConstitDatasets(trainFilenames, splitFilenames, ...
    testFilenames, wordMap, relationMap, hyperParams);
% trainDataset = Symmetrize(trainDataset);

% Trim out individual examples if needed
if hyperParams.dataPortion < 1
    trainDataset = trainDataset(1:round(hyperParams.dataPortion * length(trainDataset)));
end

% Train
Log(hyperParams.statlog, 'Training')
options.MaxFunEvals = 1000;
options.DerivativeCheck = 'on';
options.runName = 'tr';

if hyperParams.minFunc
    % Set up minFunc
    addpath('minFunc/minFunc/')
    addpath('minFunc/minFunc/compiled/')
    addpath('minFunc/minFunc/mex/')
    addpath('minFunc/autoDif/')

    % Warning: L-BFGS won't save state across restarts
    modelState.theta = minFunc(@ComputeFullCostAndGrad, modelState.theta, options, ...
        modelState.thetaDecoder, trainDataset, modelState.constWordFeatures, hyperParams, testDatasets);
else
    modelState.theta = AdaGradSGD(@ComputeFullCostAndGrad, modelState, options, ...
        trainDataset, hyperParams, testDatasets);
end
    
end
