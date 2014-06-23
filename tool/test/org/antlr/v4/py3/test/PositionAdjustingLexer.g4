/*
 * [The "BSD license"]
 *  Copyright (c) 2012 Terence Parr
 *  Copyright (c) 2012 Sam Harwell
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 *  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 *  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 *  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 *  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
lexer grammar PositionAdjustingLexer;

@members {

def resetAcceptPosition(self, index:int, line:int, column:int):
	self._input.seek(index)
	self.line = line
	self.column = column
	self._interp.consume(self._input)

def nextToken(self):
	if self._interp.__dict__.get("resetAcceptPosition", None) is None:
		self._interp.__dict__["resetAcceptPosition"] = self.resetAcceptPosition
	return super(type(self),self).nextToken()

def emit(self):
	if self._type==self.TOKENS:
		self.handleAcceptPositionForKeyword("tokens")
	elif self._type==self.LABEL:
		self.handleAcceptPositionForIdentifier()
	return super(type(self),self).emit()

def handleAcceptPositionForIdentifier(self):
	tokenText = self.text
	identifierLength = 0
	while identifierLength < len(tokenText) and self.isIdentifierChar(tokenText[identifierLength]):
		identifierLength += 1

	if self._input.index > self._tokenStartCharIndex + identifierLength:
		offset = identifierLength - 1
		self._interp.resetAcceptPosition(self._tokenStartCharIndex + offset, 
				self._tokenStartLine, self._tokenStartColumn + offset)
		return True
	else:
		return False


def handleAcceptPositionForKeyword(self, keyword:str):
	if self._input.index > self._tokenStartCharIndex + len(keyword):
		offset = len(keyword) - 1
		self._interp.resetAcceptPosition(self._tokenStartCharIndex + offset, 
			self._tokenStartLine, self._tokenStartColumn + offset)
		return True
	else:
		return False

@staticmethod
def isIdentifierChar(c:str):
	return c.isalnum() or c == '_'


}

ASSIGN : '=' ;
PLUS_ASSIGN : '+=' ;
LCURLY:	'{';

// 'tokens' followed by '{'
TOKENS : 'tokens' IGNORED '{';

// IDENTIFIER followed by '+=' or '='
LABEL
	:	IDENTIFIER IGNORED '+'? '='
	;

IDENTIFIER
	:	[a-zA-Z_] [a-zA-Z0-9_]*
	;

fragment
IGNORED
	:	[ \t\r\n]*
	;

NEWLINE
	:	[\r\n]+ -> skip
	;

WS
	:	[ \t]+ -> skip
	;