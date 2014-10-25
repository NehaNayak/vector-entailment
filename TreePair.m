% Want to distribute this code? Have other questions? -> sbowman@stanford.edu
classdef TreePair < handle
    % Represents a pair of binary branching syntactic tree with three 
    % representations at each node:
    % - The index with which the feature vector can be looked up - if leaf
    % - The text with which the tree can be displayed.
    % - The features at the node.
    
	methods(Static)
	
	function [p,h] = makeTreePair(iTextp,iTexth,wordMap,theta,decoder, wordFeatures, hyperParams)
		p = Tree.makeTree(iTextp,wordMap);
		h = Tree.makeTree(iTexth,wordMap);
		
		pSubtreesLength = int32(size(strfind(iTextp,'('),2));
		hSubtreesLength = int32(size(strfind(iTexth,'('),2));

		weights = zeros(pSubtreesLength,hSubtreesLength);
		weights = comparePtoH(p,h,1,theta,decoder, wordFeatures, hyperParams, weights)
		disp(this.weights)
	end

	function [newInd, weights] = comparePtoH(p,h,n,theta,decoder, wordFeatures, hyperParams, weights)
		this.compareH(p,h,n,1,theta,decoder, wordFeatures, hyperParams)
		if isLeaf(p)
			newInd = n+1;
			return
		else
			nextInd = this.comparePtoH(p.daughters(1),h,n+1,theta,decoder, wordFeatures, hyperParams, weights);
			nextInd = this.comparePtoH(p.daughters(2),h,nextInd,theta,decoder, wordFeatures, hyperParams, weights);
			newInd = nextInd+1;
		end
	end

	function [newInd, weights] = compareH(p,h,n,i,theta,decoder, wordFeatures, hyperParams, weights)
		data = struct('relation', 1, 'leftTree', p.copy(), 'rightTree', h.copy(), 'id', 0, 'score', 0);
		probsForward=ComputeRelationProbs(theta, decoder, data, wordFeatures, hyperParams);
		data = struct('relation', 1, 'leftTree', h.copy(), 'rightTree', p.copy(), 'id', 0, 'score', 0);
		probsReverse=ComputeRelationProbs(theta, decoder, data, wordFeatures, hyperParams);
		%weights(n,i) = 1-0.5*(probsReverse(1)*probsForward(1));
		weights(n,i) = n+i;
	
		if isLeaf(h)
			newInd =  n+1;
			return
		else
			nextInd = this.compareH(p,h.daughters(1),n,i+1,theta,decoder, wordFeatures, hyperParams, weights);
			nextInd = this.compareH(p,h.daughters(2),n,nextInd,theta,decoder, wordFeatures, hyperParams,weights);
			newInd =  nextInd+1;
		end
		
	end

    end
end
