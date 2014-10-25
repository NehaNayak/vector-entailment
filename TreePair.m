% Want to distribute this code? Have other questions? -> sbowman@stanford.edu
classdef TreePair < handle
    % Represents a pair of binary branching syntactic tree with three 
    % representations at each node:
    % - The index with which the feature vector can be looked up - if leaf
    % - The text with which the tree can be displayed.
    % - The features at the node.
    
    properties (Hidden) %TODO: Make all private.
	weights = [];
    end
    
	methods
	
	function newInd = comparePtoH(p,h,n,theta,decoder, wordFeatures, hyperParams)
		this.compareH(p,h,n,1,theta,decoder, wordFeatures, hyperParams)
		if isLeaf(p)
			newInd = n+1;
			return
		else
			nextInd = this.comparePtoH(p.daughters(1),h,n+1,theta,decoder, wordFeatures, hyperParams);
			nextInd = this.comparePtoH(p.daughters(2),h,nextInd,theta,decoder, wordFeatures, hyperParams);
			newInd = nextInd+1;
		end
	end

	function newInd = compareH(p,h,n,i,theta,decoder, wordFeatures, hyperParams)
		data = struct('relation', 1, 'leftTree', p.copy(), 'rightTree', h.copy(), 'id', 0, 'score', 0);
		probsForward=ComputeRelationProbs(theta, decoder, data, wordFeatures, hyperParams);
		data = struct('relation', 1, 'leftTree', h.copy(), 'rightTree', p.copy(), 'id', 0, 'score', 0);
		probsReverse=ComputeRelationProbs(theta, decoder, data, wordFeatures, hyperParams);
		%weights(n,i) = 1-0.5*(probsReverse(1)*probsForward(1));
		this.weights(n,i) = n+i;
	
		if isLeaf(h)
			newInd =  n+1;
			return
		else
			nextInd = this.compareH(p,h.daughters(1),n,i+1,theta,decoder, wordFeatures, hyperParams);
			nextInd = this.compareH(p,h.daughters(2),n,nextInd,theta,decoder, wordFeatures, hyperParams);
			newInd =  nextInd+1;
		end
		
	end

	function [p,h] = makeTreePair(iTextp,iTexth,wordMap,theta,decoder, wordFeatures, hyperParams)
		p = Tree.makeTree(iTextp,wordMap);
		h = Tree.makeTree(iTexth,wordMap);
		
		pSubtreesLength = int32(size(strfind(iTextp,'('),2));
		hSubtreesLength = int32(size(strfind(iTexth,'('),2));

		this.weights = zeros(pSubtreesLength,hSubtreesLength);
		this.comparePtoH(p,h,1,theta,decoder, wordFeatures, hyperParams)
		disp(this.weights)
	end
    end
end
