% Want to distribute this code? Have other questions? -> sbowman@stanford.edu
classdef TreePair < handle
    % Represents a pair of binary branching syntactic tree with three 
    % representations at each node:
    % - The index with which the feature vector can be looked up - if leaf
    % - The text with which the tree can be displayed.
    % - The features at the node.
    
	methods(Static)
	
	function [p,h,weights] = makeTreePair(iTextp,iTexth,wordMap, hyperParams)

		a = load(hyperParams.bootstrapFile);
    		modelState = a.modelState;
		theta=modelState.theta;
		decoder=modelState.thetaDecoder;
		wordFeatures=modelState.constWordFeatures;

		p = Tree.makeTree(iTextp,wordMap);
		h = Tree.makeTree(iTexth,wordMap);
		
		pSubtreesLength = int32(size(strfind(iTextp,'('),2));
		hSubtreesLength = int32(size(strfind(iTexth,'('),2));
		
		weights = zeros(pSubtreesLength,hSubtreesLength);
		[blank, weights] = TreePair.comparePtoH(p, h, 1, theta, decoder, wordFeatures, hyperParams, weights);
		blank = TreePair.assignPWeights(p,1,weights);
		blank = TreePair.assignHWeights(h,1,weights);
	end

	function [newInd, weights] = comparePtoH(p, h, n, theta, decoder, wordFeatures, hyperParams, weights)

		[newInd, weights] = TreePair.compareH(p, h, n, 1, ...
					theta,decoder, wordFeatures, hyperParams, weights);

		if isLeaf(p)
			newInd = n-1;
			return
		else
			[nextInd, weights] = TreePair.comparePtoH(p.daughters(1), h, n+1, ...
						theta,decoder, wordFeatures, hyperParams, weights);
			[nextInd, weights] = TreePair.comparePtoH(p.daughters(2), h, nextInd, ...
						theta,decoder, wordFeatures, hyperParams, weights);
			newInd = nextInd+1;
		end
	end

	function newInd = assignPWeights(p, n, weights)

		p.weight = max(weights(n,:));

		if isLeaf(p)
			newInd = n-1;
			return
		else
			nextInd = TreePair.assignPWeights(p.daughters(1), n+1, weights);
			nextInd = TreePair.assignPWeights(p.daughters(2), nextInd, weights);
			newInd = nextInd+1;
		end
	end

	function newInd = assignHWeights(h, i, weights)

		h.weight = max(weights(:,i));

		if isLeaf(h)
			newInd = i-1;
			return
		else
			nextInd = TreePair.assignHWeights(h.daughters(1), i+1, weights);
			nextInd = TreePair.assignHWeights(h.daughters(2), nextInd, weights);
			newInd = nextInd+1;
		end
	end

	function [newInd, weights] = compareH(p, h, n, i, theta, decoder, wordFeatures, hyperParams, weights)

		data = struct('relation', 1, 'leftTree', p.copy(), 'rightTree', h.copy(), 'id', 0, 'score', 0);
		probsForward=ComputeRelationProbs(theta, decoder, data, wordFeatures, hyperParams);
		data = struct('relation', 1, 'leftTree', h.copy(), 'rightTree', p.copy(), 'id', 0, 'score', 0);
		probsReverse=ComputeRelationProbs(theta, decoder, data, wordFeatures, hyperParams);
		k = 1-sqrt(probsReverse(1)*probsForward(1));
		weights(n,i) = k;
	
		if isLeaf(h)
			newInd =  i-1;
			return
		else
			[nextInd, weights] = TreePair.compareH(p,h.daughters(1),n,i+1,theta,decoder, wordFeatures, hyperParams, weights);
			[nextInd, weights] = TreePair.compareH(p,h.daughters(2),n,nextInd,theta,decoder, wordFeatures, hyperParams,weights);
			newInd =  nextInd+1;
		end
		
	end

    end
end
