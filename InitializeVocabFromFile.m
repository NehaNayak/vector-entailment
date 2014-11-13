function [ vocab, fullVocab, fullWordmap ] = InitializeVocabFromFile(wordMap, loc)

DIM = 25;
loadFromMat = false;
wordlist = wordMap.keys();

if loadFromMat
    % Load Collobert (?) vectors.
    % DEPRECATED

    DIM = 100;
    v = load('sick_data/vars.normalized.100.mat');
    words = v.words;
    fullVocab = v.We2';
else
    % The vocabulary that comes with the vector source.
    fid = fopen('/user/sbowman/quant/sick_data/words_25d.txt');
    words = textscan(fid,'%s','Delimiter','\n');
    words = words{1};
    fclose(fid);
    fullVocab = dlmread('/user/sbowman/quant/sick_data/vectors_25d.txt', ' ', 0, 1);
end

fullWordmap = containers.Map(words,2:length(words) + 1);

x = size(wordlist, 2);

SCALE = mean(abs(fullVocab(:)))
OFFSET = 2 * SCALE;

vocab = rand(x, DIM) .* OFFSET - SCALE;

for wordlistIndex = 1:length(wordlist)
    if fullWordmap.isKey(wordlist{wordlistIndex})
        loadedIndex = fullWordmap(wordlist{wordlistIndex});
    elseif fullWordmap.isKey(strrep(wordlist{wordlistIndex}, '_', '-'))
        disp(['Mapped ', wordlist{wordlistIndex}]);
        loadedIndex = fullWordmap(strrep(wordlist{wordlistIndex}, '_', '-'));
    elseif strcmp(wordlist{wordlistIndex}, 'n''t')
        loadedIndex = fullWordmap('not');
        disp('Mapped not.');
    else
        loadedIndex = 0;
        disp(['Word could not be loaded: ', wordlist{wordlistIndex}]);
    end
    if loadedIndex > 0
        % Copy in the loaded vector
        vocab(wordMap(wordlist{wordlistIndex}), :) = fullVocab(loadedIndex, :);
    end % Else: We keep the randomly initialized entry
end

end
