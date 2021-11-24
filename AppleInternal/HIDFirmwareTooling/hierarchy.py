#!/usr/bin/env python2.7


class Hierarchy:

    def __init__(self, label):
        self._rootNode = [label, []]
        self._nodeStack = [self._rootNode]

    def mkdir(self, label, descend=False):
        newNode = [label, []]
        self._nodeStack[-1][1].append(newNode)
        if descend:
            self._nodeStack.append(newNode)

    def ascend(self):
        if len(self._nodeStack) is 1:
            raise Exception('Cannot ascend above the root node.')
        self._nodeStack.pop()

    def prettyPrint(self):
        def printTree(tree, level=0, isLastChild=True, indentString=''):
            (description, children) = tree
            if level is 0:
                print(description)
            elif isLastChild:
                print((indentString + u'\u2514\u2500\u2500 ' + description).encode('utf-8'))
                indentString += '    '
            else:
                print((indentString + u'\u251c\u2500\u2500 ' + description).encode('utf-8'))
                indentString += u'\u2502   '
            i = len(children)
            for subtree in children:
                i -= 1
                printTree(subtree, level + 1, i == 0, indentString)
        printTree(self._rootNode)


if __name__ == '__main__':
    pass
