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
-- This module contains tests for the DataType module's String, Integer, and
-- Rational sections.
module DataType_Test where

import BitSeries
import qualified BitSeries_Test as B
import Control.DeepSeq
import Control.Exception
import qualified Data.Map as M
import Opcodes
import qualified Opcodes_Test as P
import DataType
import Test.HUnit
import TestException

instance NFData RNmspS
instance Eq RNmspS where
  (Child a)==(Child b)=a==b
  Parent==Parent=True
  _==_=False

instance NFData Primitive
instance Eq Primitive where
  (BString a)==(BString b)=a==b
  (BInteger a)==(BInteger b)=a==b
  (BRational a b)==(BRational c d)=(a==c) && (b==d)
  (BNmspId a)==(BNmspId b)=a==b
  (BStatement)==(BStatement)=True

-- DataType Terminate Truncator
tD :: DataType -> DataType
tD (b,p) = (B.tT b,p)

-- String Tests
strError = ErrorCall "lstring: Reached program end"

testEmptyP = TestLabel "Test Empty Program"  $
  TestCase $ assertException strError (pstring [])
testIncomplete = TestLabel "Test Incomplete" $
  TestCase $ assertException strError (pstring p)
  where p=(opcodes M.! "CS") ++ (replicate 3 T)
testUnfinished = TestLabel "Test Unfinished" $
  TestCase $ assertException strError (pstring p)
  where p=(opcodes M.! "CS") ++ (replicate 4 T)

testEmpty = TestLabel "Test Empty String" $
  TestCase $ assertEqual "" ([],(p,BString [])) (pstring p)
  where p=opcodes M.! "ES"
testL4 = TestLabel "Test String Length 4" $
  TestCase $ assertEqual "" ([],(p,BString str)) (pstring p)
  where str=[F,T,T,F]
        p=(opcodes M.! "CS") ++ str ++ (opcodes M.! "ES")
testL8 = TestLabel "Test String Length 8" $
  TestCase $ assertEqual "" ([],(p,BString $ s1++s2)) (pstring p)
  where s1=replicate 4 F
        s2=[F,T,F,T]
        p=(opcodes M.! "CS")++s1++(opcodes M.! "CS")++s2++(opcodes M.! "ES")
testExtra = TestLabel "Test Program Deletion" $
  TestCase $ assertEqual "" (p2,(p1,BString str)) $ pstring (p1++p2)
  where str=replicate 4 T
        p1=(opcodes M.! "CS")++str++(opcodes M.! "ES")
        p2=replicate 23 F

strTests = TestLabel "String" $
  TestList[ testEmptyP, testIncomplete, testUnfinished, testEmpty, testL4, testL8
          , testExtra ]

-- Integer Tests
intError = ErrorCall "linteger: Reached program end"

testIEmptyP = TestLabel "Test Empty Program" $
  TestCase $ assertException intError (pinteger [])
testIIncomplete1 = TestLabel "Test Incomplete Program 1" $
  TestCase $ assertException strError (pinteger [F])
testIIncomplete2 = TestLabel "Test Incomplete Program 2" $
  TestCase $ assertException strError (pinteger p)
  where p=[F]++(opcodes M.! "CS")
testIUnfinished = TestLabel "Test Unfinished Program" $
  TestCase $ assertException strError (pinteger p)
  where p = [F]++(opcodes M.! "CS")++(replicate 4 F)

testIEmpty1 = TestLabel "Test Positive Empty Integer" $
  TestCase $ assertEqual "" ([],(p,BInteger 0)) (pinteger p)
  where p = [F]++(opcodes M.! "ES")
testIEmpty2 = TestLabel "Test Negative Empty Integer" $
  TestCase $ assertEqual "" ([],(p,BInteger (-1))) (pinteger p)
  where p = [T]++(opcodes M.! "ES")

testIL4 = TestLabel "Test Integer Length 4" $
  TestCase $ assertEqual "" ([],(p,BInteger 10)) (pinteger p)
  where p = [F]++(opcodes M.! "CS")++([T,F,T,F])
          ++(opcodes M.! "ES")
testIL8 = TestLabel "Test Integer Length 8" $
  TestCase $ assertEqual "" ([],(p,BInteger 49)) (pinteger p)
  where p = [F]++(opcodes M.! "CS")++([F,F,F,T])
          ++(opcodes M.! "CS")++([F,F,T,T])++(opcodes M.! "ES")
testINeg = TestLabel "Test Negative Integer" $
  TestCase $ assertEqual "" ([],(p,BInteger (-76))) (pinteger p)
  where p = [T]++(opcodes M.! "CS")++([F,T,F,F])
          ++(opcodes M.! "CS")++([T,F,T,T])++(opcodes M.! "ES")
testIExtra = TestLabel "Test Program Deletion" $
  TestCase $ assertEqual "" (p2,(p1,BInteger (-3))) (pinteger (p1++p2))
  where p1 = [T]++(opcodes M.! "CS")++[T,T,F,T]
          ++(opcodes M.! "ES")
        p2 = replicate 100 T

intTests = TestLabel "Integer" $
  TestList [ testIEmptyP, testIIncomplete1, testIIncomplete2, testIUnfinished
           , testIEmpty1, testIEmpty2, testIL4, testIL8, testINeg, testIExtra ]

-- Rational Tests
rationalError = ErrorCall "lrational: Reached program end"

testREmptyP = TestLabel "Test Empty Program" $
  TestCase $ assertException rationalError (prational [])
testRIncomplete1 = TestLabel "Test Incomplete Program 1" $
  TestCase $ assertException strError (prational [F])
testRIncomplete2 = TestLabel "Test Incomplete Program 2" $
  TestCase $ assertException strError (prational p)
  where p=[F]++(opcodes M.! "CS")
testRUnfinished = TestLabel "Test Unfinished Program" $
  TestCase $ assertException intError (prational p)
  where p = [F]++(opcodes M.! "CS")++(replicate 4 F)++(opcodes M.! "ES")

testREDiv0 = TestLabel "Test Empty Division By 0" $
  TestCase $ assertEqual "" ([],(p,BRational 0 0)) (prational p)
  where p = [F]++(opcodes M.! "ES")++[F]++(opcodes M.! "ES")
testRDiv0 = TestLabel "Test Division By 0" $
  TestCase $ assertEqual "" ([],(p,BRational 0 0)) (prational p)
  where p = [F]++(opcodes M.! "CS")++([T,T,T,T])++(opcodes M.! "ES")
          ++[F]++(opcodes M.! "ES")
testREmpty1 = TestLabel "Test Empty 0" $
  TestCase $ assertEqual "" ([],(p,BRational 0 (-1))) (prational p)
  where p = [F]++(opcodes M.! "ES")++[T]++(opcodes M.! "ES")
testREmpty2 = TestLabel "Test Empty 1" $
  TestCase $ assertEqual "" ([],(p,BRational (-1) (-1))) (prational p)
  where p = [T]++(opcodes M.! "ES")++[T]++(opcodes M.! "ES")

testRL44 = TestLabel "Test Rational Length 4/4" $
  TestCase $ assertEqual "" ([],(p,BRational 6 1)) (prational p)
  where p = [F]++(opcodes M.! "CS")++([F,T,T,F])
          ++(opcodes M.! "ES")++[F]++(opcodes M.! "CS")
          ++([F,F,F,T])++(opcodes M.! "ES")
testRL84 = TestLabel "Test Rational Length 8/4" $
  TestCase $ assertEqual "" ([],(p,BRational 50 3)) (prational p)
  where p = [F]++(opcodes M.! "CS")++([F,F,T,F])
          ++(opcodes M.! "CS")++([F,F,T,T])++(opcodes M.! "ES")
          ++[F]++(opcodes M.! "CS")++([F,F,T,T])++(opcodes M.! "ES")
testRL48 = TestLabel "Test Rational Length 4/8" $
  TestCase $ assertEqual "" ([],(p,BRational 7 106)) (prational p)
  where p = [F]++(opcodes M.! "CS")++([F,T,T,T])
          ++(opcodes M.! "ES")++[F]++(opcodes M.! "CS")
          ++([T,F,T,F])++(opcodes M.! "CS")++([F,T,T,F])
          ++(opcodes M.! "ES")
testRL88 = TestLabel "Test Rational Length 8/8" $
  TestCase $ assertEqual "" ([],(p,BRational 249 16)) (prational p)
  where p = [F]++(opcodes M.! "CS")++([T,F,F,T])
          ++(opcodes M.! "CS")++([T,T,T,T])++(opcodes M.! "ES")
          ++[F]++(opcodes M.! "CS")++([F,F,F,F])++(opcodes M.! "CS")
          ++([F,F,F,T])++(opcodes M.! "ES")
testRExtra = TestLabel "Test Program Deletion" $
  TestCase $ assertEqual "" (p2,(p1,BRational (-3) (1))) (prational (p1++p2))
  where p1 = [T]++(opcodes M.! "CS")++[T,T,F,T]
          ++(opcodes M.! "ES")++[F]++(opcodes M.! "CS")
          ++[F,F,F,T]++(opcodes M.! "ES")
        p2 = replicate 100 T

rationalTests = TestLabel "Rational" $
  TestList [ testREmptyP, testRIncomplete1, testRIncomplete2, testRUnfinished
           , testREDiv0, testRDiv0, testREmpty1, testREmpty2, testRL44, testRL84
           , testRL48, testRL88, testRExtra ]

-- Namespace Tests
maid :: ANmsp -> DataType
maid x = ([],BNmspId $ Left x)

mrid :: RNmsp -> DataType
mrid x = ([],BNmspId $ Right x)

testPNmspA = TestLabel "Test loading absolute namespace" $
  TestCase $ assertEqual "" ([],(p,snd $ maid id)) (pnmsp p)
  where id=[[T,F,T,F],replicate 4 F,replicate 4 T]
        p=(o "AN")++(o "CN")++(o "CS")++id!!0++(o "ES")++(o "CN")
          ++(o "CS")++id!!1++(o "ES")++(o "CN")++(o "CS")++id!!2
          ++(o "ES")++(o "EN")
        o s=opcodes M.! s

testPNmspR = TestLabel "Test loading relative namespace" $
  TestCase $ assertEqual "" ([],(p,snd $ mrid id)) (pnmsp p)
  where id=[Parent,Child [F,F,F,F], Child [T,T,T,T]]
        p=(o "RN")++(o "PN")++(o "CN")++(o "CS")++[F,F,F,F]++(o "ES")
          ++(o "CN")++(o "CS")++[T,T,T,T]++(o "ES")++(o "ERN")
        o s=opcodes M.! s

testPNmspExtra = TestLabel "Test loading namespace with extra program" $
  TestCase $ assertEqual "" (e,(p,snd $ maid id)) (pnmsp (p++e))
    where id=[]
          p=(o "AN")++(o "EN")
          e=replicate 103 F 
          o s=opcodes M.! s

testPNmspF = TestLabel "Test loading short namespace" $
  TestCase $ assertException P.opError (pnmsp [])

testPNmspF2 = TestLabel "Test loading short namespace 2" $
  TestCase $ assertException strError (pnmsp p)
  where p=(o "AN")++(o "CN")++(o "CS")
        o s=opcodes M.! s

nmspTests = TestLabel "Namespace" $
  TestList [ testPNmspA, testPNmspR, testPNmspExtra, testPNmspF, testPNmspF2 ]

mainList = TestLabel "Primitives" $ 
  TestList [ strTests, intTests, rationalTests, nmspTests ]
main = runTestTT $ TestList [ B.mainList, P.mainList, mainList]
