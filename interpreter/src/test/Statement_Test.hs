{-
Advanced Assembly Interpreter
Copyright (c) 2014 Joshua Brot

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
-}
-- This module provides tests for the Statement module
module Statement_Test where

import BitSeries
import qualified BitSeries_Test as B
import Control.Exception
import qualified Data.Map as M
import DataType
import qualified DataType_Test as D
import qualified Namespaces_Test as N
import Opcodes
import qualified Opcodes_Test as O
import Statement
import Test.HUnit
import TestException

instance (Eq a) => Eq (Stmt a) where
  (LS a)==(LS b)=a==b
  (AS a b)==(AS c d)=(a==c)&&(b==d)
  (RS a)==(RS b)=a==b
  (ET a b)==(ET c d)=(a==c)&&(b==d)
  (SQ a b)==(SQ c d)=(a==c)&&(b==d)
  (IF a b c)==(IF d e f)=(a==d)&&(b==e)&&(c==f)
  (DW a b)==(DW c d)=(a==c)&&(b==d)
  (MSA a b)==(MSA c d)=(a==c)&&(b==d)
  (MSB a b c)==(MSB d e f)=(a==d)&&(b==e)&&(c==f)
  (IOS a)==(IOS b)=(a==b)
  _==_=False

-- Literal Statement Tests
testLsS = TestLabel "Test loading literal string" $
  TestCase $ assertEqual "" ([],((p,BStatement),Free (LS (p1, BString s))))
    (loadLS p)
  where s=[T,T,F,F]
        p1=(o "CS")++s++(o "ES")
        p=(o "LT")++p1
        o t=opcodes M.! t

testLsSE = TestLabel "Test loading literal string with extra" $
  TestCase $ assertEqual "" (p2,((p,BStatement),Free (LS (p1, BString s))))
    (loadLS $ p++p2)
  where s=[T,T,F,F]
        p1=(o "CS")++s++(o "ES")
        p2=replicate 10 T
        p=(o "LT")++p1
        o t=opcodes M.! t

testLsI = TestLabel "Test loading literal integer" $
  TestCase $ assertEqual "" ([],((p,BStatement),Free (LS (p1, BInteger 9))))
    (loadLS p)
  where p1=[F]++(o "CS")++[T,F,F,T]++(o "ES")
        p=(o "LI")++p1
        o t=opcodes M.! t

testLsR = TestLabel "Test loading literal rational" $
  TestCase $ assertEqual "" ([],((p,BStatement),Free (LS (p1, BRational 2 3))))
    (loadLS p)
  where p1= [F]++(o "CS")++[F,F,T,F]++(o "ES")
          ++[F]++(o "CS")++[F,F,T,T]++(o "ES")
        p=(o "LR")++p1
        o t=opcodes M.! t

testLsN = TestLabel "Test loading literal namespace" $
  TestCase $ assertEqual "" ([],((p,BStatement),Free (LS (p1, BNmspId $ Left []))))
    (loadLS p)
  where p1=(o "AN")++(o "EN")
        p=(o "LN")++p1
        o t=opcodes M.! t

testLsM = TestLabel "Test loading literal statement" $
  TestCase $ assertEqual "" ([],((p,BStatement),Free (LS (p1, BStatement))))
    (loadLS p)
  where p1=(o "LS")++(o "LI")++[T]++(o "ES")
        p=(o "LM")++p1
        o t=opcodes M.! t

testLsME = TestLabel "Test loading literal statement with extra" $
  TestCase $ assertEqual "" (p2,((p,BStatement),Free (LS (p1, BStatement))))
    (loadLS $ p++p2)
  where p1=(o "LS")++(o "LI")++[T]++(o "ES")
        p2=[T,F,F,F,Terminate,Terminate,F,T,F]
        p=(o "LM")++p1
        o t=opcodes M.! t

-- Control Statement Test
testCtA = TestLabel "Test loading assign statement" $
  TestCase $ assertEqual "" ([],((p,BStatement),r)) (loadTS p)
  where r=Free (AS (Free (LS (q, BInteger (-4)))) (Free (LS (q2,BString s))))
        q=[T]++(o "CS")++[T,T,F,F]++(o "ES")
        s=[T,F,F,T]
        q2=(o "CS")++s++(o "ES")
        p=(o "AS")++(o "LS")++(o "LI")++q++(o "LS")++(o "LT")++q2
        o t=opcodes M.! t

testCtAE = TestLabel "Test loading assign statement with extra" $
  TestCase $ assertEqual "" (p2,((p,BStatement),r)) (loadTS $ p++p2)
  where r=Free (AS (Free (LS (q,BNmspId $ Left [[T,T,T,T]])))
                   (Free (LS (q2, BString [T,F,T,F]))))
        q=(o "AN")++(o "CN")++(o "CS")++[T,T,T,T]++(o "ES")++(o "EN")
        q2=(o "CS")++[T,F,T,F]++(o "ES")
        p=(o "AS")++(o "LS")++(o "LN")++q++(o "LS")++(o "LT")++q2
        p2=[T,F,F,F,T,F,T,F,T,F,F,Terminate]
        o t=opcodes M.! t

testCtR = TestLabel "Test loading retrieve statement" $
  TestCase $ assertEqual "" ([],((p,BStatement),r)) (loadTS p)
  where r=Free (RS (Free (LS (q,BString s))))
        s=[T,T,T,T]
        q=(o "CS")++s++(o "ES")
        p=(o "RS")++(o "LS")++(o "LT")++q
        o t=opcodes M.! t

testCtRE = TestLabel "Test loading retrieve statement with extra" $
  TestCase $ assertEqual "" (p2,((p,BStatement),r)) (loadTS $ p++p2)
  where r=Free (RS (Free (LS (q,BNmspId $ Right [Parent,Child [T,F,F,F]]))))
        q=(o "RN")++(o "PN")++(o "CN")++(o "CS")++[T,F,F,F]++(o "ES")++(o "ERN")
        p=(o "RS")++(o "LS")++(o "LN")++q
        p2=replicate 52 F
        o t=opcodes M.! t

testCtS = TestLabel "Test loading sequence statement" $
  TestCase $ assertEqual "" ([],((p,BStatement),r)) (loadTS p)
  where r=Free (SQ (Free (LS (q, BRational 4 (-3)))) (Free (LS (q2,BStatement))))
        q=[F]++(o "CS")++[F,T,F,F]++(o "ES")++[T]++(o "CS")++[T,T,F,T]++(o "ES")
        q2=(o "LS")++(o "LS")++(o "CS")++[T,T,T,F]++(o "ES")
        p=(o "SQ")++(o "LS")++(o "LR")++q++(o "LS")++(o "LM")++q2
        o t=opcodes M.! t

testCtSE = TestLabel "Test loading sequence statement with extra" $
  TestCase $ assertEqual "" (p2,((p,BStatement),r)) (loadTS $ p++p2)
  where r=Free (SQ (Free (LS (q,BNmspId $ Left [])))
                   (Free (LS (q2, BString [T,F,T,T]))))
        q=(o "AN")++(o "EN")
        q2=(o "CS")++[T,F,T,T]++(o "ES")
        p=(o "SQ")++(o "LS")++(o "LN")++q++(o "LS")++(o "LT")++q2
        p2=[T,F,F,F,T,F,T,F,T,F,T,Terminate,Terminate]
        o t=opcodes M.! t

-- Math Statement Test
testMA = TestLabel "Test loading 1-var mathematical statement" $
  TestCase $ assertEqual "" ([],((p,BStatement),r)) (loadMS p)
  where r=Free (MSA "BN" (Free (LS (q, BInteger (-4)))))
        q=[T]++(o "CS")++[T,T,F,F]++(o "ES")
        p=(o "BN")++(o "LS")++(o "LI")++q
        o t=opcodes M.! t

testMAE = TestLabel "Test loading 1-var mathematical statement with extra" $
  TestCase $ assertEqual "" (p2,((p,BStatement),r)) (loadMS $ p++p2)
  where r=Free (MSA "TN" (Free (LS (q, BString [T,T,T,F]))))
        q=(o "CS")++[T,T,T,F]++(o "ES")
        p=(o "TN")++(o "LS")++(o "LT")++q
        p2=[T,F,T,F,T,T,T,T,T,F,F,Terminate]
        o t=opcodes M.! t

testMB = TestLabel "Test loading 2-var mathematical statement" $
  TestCase $ assertEqual "" ([],((p,BStatement),r)) (loadMS p)
  where r=Free (MSB "BGE" (Free (LS (q, BInteger 12))) 
                         (Free (LS (q2, BString []))))
        q=[F]++(o "CS")++[T,T,F,F]++(o "ES")
        q2=(o "ES")
        p=(o "BGE")++(o "LS")++(o "LI")++q++(o "LS")++(o "LT")++q2
        o t=opcodes M.! t

testMBE = TestLabel "Test loading 2-var mathematical statement with extra" $
  TestCase $ assertEqual "" ([],((p,BStatement),r)) (loadMS p)
  where r=Free (MSB "TR" (Free (LS (q, BStatement))) 
                         (Free (LS (q2, BNmspId $ Left $ [[F,F,T,F]]))))
        q=(o "LS")++(o "LT")++(o "ES")
        q2=(o "AN")++(o "CN")++(o "CS")++[F,F,T,F]++(o "ES")++(o "EN")
        p=(o "TR")++(o "LS")++(o "LM")++q++(o "LS")++(o "LN")++q2
        o t=opcodes M.! t

-- I/O Statement Tests
testIO = TestLabel "Test loading i/o statement" $
  TestCase $ assertEqual "" ([],((p,BStatement),r)) (loadIO p)
  where r=Free (IOS (Free (LS (q, BInteger (-4)))))
        q=[T]++(o "CS")++[T,T,F,F]++(o "ES")
        p=(o "LS")++(o "LI")++q
        o t=opcodes M.! t

testIOE = TestLabel "Test loading i/o statement with extra" $
  TestCase $ assertEqual "" (p2,((p,BStatement),r)) (loadIO $ p++p2)
  where r=Free (IOS (Free (LS (q, BString s))))
        s=[T,T,F,F]
        q=(o "CS")++s++(o "ES")
        p=(o "LS")++(o "LT")++q
        p2=[F,F,F,T,T,T,F,T,F,F,T,Terminate]
        o t=opcodes M.! t


-- Load Statement Tests
testLtS = TestLabel "Test loading embedded literal string" $
  TestCase $ assertEqual "" ([],((p,BStatement),Free (LS (p1, BString s))))
    (loadStmt p)
  where s=[T,T,F,F]
        p1=(o "CS")++s++(o "ES")
        p=(o "LS")++(o "LT")++p1
        o t=opcodes M.! t

testLtRE = TestLabel "Test loading embedded literal rational with extra" $
  TestCase $ assertEqual "" (p2,((p,BStatement),Free (LS (p1, BRational 0 0))))
    (loadStmt $ p++p2)
  where p1=[T]++(o "CS")++[F,F,T,T]++(o "ES")++[F]++(o "ES")
        p2=replicate 10 T
        p=(o "LS")++(o "LR")++p1
        o t=opcodes M.! t

testLtI = TestLabel "Test loading embedded i/o statement" $
  TestCase $ assertEqual "" ([],((p,BStatement),r)) (loadStmt p)
  where r=Free (IOS (Free (LS (q, BRational 7 (-9)))))
        q=[F]++(o "CS")++[F,T,T,T]++(o "ES")++[T]++(o "CS")++[F,T,T,T]++(o "ES")
        p=(o "IO")++(o "LS")++(o "LR")++q
        o t=opcodes M.! t

testLtIE = TestLabel "Test loading embedded i/o statement with extra" $
  TestCase $ assertEqual "" (p2,((p,BStatement),r)) (loadStmt $ p++p2)
  where r=Free (IOS (Free (LS (q, BNmspId $ Right [Parent,Child [F,T,F,T]]))))
        q=(o "RN")++(o "PN")++(o "CN")++(o "CS")++[F,T,F,T]++(o "ES")++(o "ERN")
        p=(o "IO")++(o "LS")++(o "LN")++q
        p2=[F,F,F,T,T,T,F,T,F,F,T,Terminate]
        o t=opcodes M.! t

testLtM = TestLabel "Test loading embedded 2-var mathematical statement" $
  TestCase $ assertEqual "" ([],((p,BStatement),r)) (loadStmt p)
  where r=Free (MSB "OD" (Free (LS (q, BInteger 7))) 
                         (Free (LS (q2, BRational 5 9))))
        q=[F]++(o "CS")++[F,T,T,T]++(o "ES")
        q2= [F]++(o "CS")++[F,T,F,T]++(o "ES")
          ++[F]++(o "CS")++[T,F,F,T]++(o "ES")
        p=(o "FS")++(o "MS")++(o "OD")++(o "LS")++(o "LI")++q++(o "LS")++(o "LR")++q2
        o t=opcodes M.! t

testLtME = TestLabel "Test loading embedded 1-var mathematical statement with extra" $
  TestCase $ assertEqual "" (p2,((p,BStatement),r)) (loadStmt $ p++p2)
  where r=Free (MSA "TN" (Free (LS (q, BString [T,F,T,F]))))
        q=(o "CS")++[T,F,T,F]++(o "ES")
        p=(o "FS")++(o "MS")++(o "TN")++(o "LS")++(o "LT")++q
        p2=[T,F,T,F,F,F,T,T,Terminate]
        o t=opcodes M.! t

mainList = TestLabel "Statements" $
  TestList [ testLsS, testLsSE, testLsI, testLsR, testLsN, testLsM, testLsME
           , testCtA, testCtAE, testCtR, testCtRE, testCtS, testCtSE, testMA
           , testMAE, testMB, testMBE, testIO, testIOE, testLtS, testLtRE
           , testLtI, testLtIE, testLtM, testLtME
           ]

main = runTestTT $
  TestList [ B.mainList, O.mainList, D.mainList, N.mainList, mainList ]
