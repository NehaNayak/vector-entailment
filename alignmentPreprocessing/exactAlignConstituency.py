import sys
import re

class Tree(object):
	def __init__(self, left, right):
		self.left = left
		self.right = right
		self.canGo = False

	def enumerateSubtrees(self):
		subtrees = []
		if not isinstance(self.left,Leaf):
			subtrees.append(self.left)
			subtrees+=self.left.enumerateSubtrees()
		if not isinstance(self.right,Leaf):
			subtrees.append(self.right)
			subtrees+=self.right.enumerateSubtrees()
		return subtrees

	def printInorder(self):
		traversal = ""
		if isinstance(self.left,Leaf):
			traversal+=self.left.word+"_"
		else:
			traversal+=self.left.printInorder()
		if isinstance(self.right,Leaf):
			traversal+=self.right.word+"_"
		else:
			traversal+=self.right.printInorder()
		return traversal

	def treeEquality(self,other):
		selfLeftTree = isinstance(self.left,Tree)	
		selfRightTree = isinstance(self.right,Tree)	
		otherLeftTree = isinstance(other.left,Tree)	
		otherRightTree = isinstance(other.right,Tree)

		if not selfLeftTree==otherLeftTree or not selfRightTree==otherRightTree:
			return False 
	
		if not selfLeftTree:
			if not self.left.word == other.left.word:
				return False

		if not selfRightTree:
			if not self.right.word == other.right.word:
				return False

		isEqual = True
		if selfLeftTree:
			isEqual = isEqual and Tree.treeEquality(self.left, other.left)
		if selfRightTree:
			isEqual = isEqual and Tree.treeEquality(self.right, other.right)
		return isEqual
	
	def shrink(self):
		if self.canGo:
			return Leaf(self.printInorder()[:-1])
		if not isinstance(self.left,Leaf):
			self.left = self.left.shrink()
		if not isinstance(self.right,Leaf):
			self.right = self.right.shrink()
		return self

	def reconstruct(self):
		parse = " ( "
		if isinstance(self.left,Leaf):
			parse+= self.left.word+" "
		else:
			parse = parse + self.left.reconstruct()
		if isinstance(self.right,Leaf):
			parse+= self.right.word+" "
		else:
			parse = parse + self.right.reconstruct()
		parse += " ) "
		return parse

	
class Leaf(object):
	def __init__(self, word):
		self.word = word

def makeTree(parse):
	parts = parse.split()
	stack = [None]*len(parts)
	stackTop = 0
	for part in parts:
		if part==')':
			r = stack[stackTop]
			l = stack[stackTop-1]
			stackTop-=1
			stack[stackTop] = Tree(l,r)
		elif not part == '(':
			stack[stackTop+1]=Leaf(part)
			stackTop+=1
	return stack[stackTop]

for line in sys.stdin:
	(label, parse1, parse2, score1, score2) = line.split("\t")
	
	pTree = makeTree(parse1)
	hTree = makeTree(parse2)

	for pSub in pTree.enumerateSubtrees():
		for hSub in hTree.enumerateSubtrees():
			if pSub.treeEquality(hSub):
				pSub.canGo=True
				hSub.canGo=True

	pTree = pTree.shrink()
	hTree = hTree.shrink()

	sys.stdout.write("\t".join([label, pTree.reconstruct(), hTree.reconstruct(), score1, score2]))
