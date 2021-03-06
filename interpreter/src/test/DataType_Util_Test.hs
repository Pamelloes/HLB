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
-- This module contains tests for the DataType.Util module
module DataType_Util_Test where

import qualified BitSeries_Test as B
import qualified Data.Map as M
import Data.Ratio
import qualified DataType_Test as D
import Language.AA.BitSeries
import Language.AA.DataType
import Language.AA.DataType.Util
import Language.AA.Opcodes
import qualified Opcodes_Test as P
import Test.HUnit

tD = id

-- String Tests
testLstring = TestLabel "Test lstring" $
  TestCase $ assertEqual "" (BString [T,T,T,T]) (lstring p)
  where p=(opcodes M.! "CS")++[T,T,T,T]++(opcodes M.! "ES")

testCs1 = TestLabel "Test cstring from BStatement" $
  TestCase $ assertEqual "" (p,BString s) (cstring (p,BStatement))
  where s=[T,T,T,T]
        p=(opcodes M.! "CS")++s++(opcodes M.! "ES")
testCs2 = TestLabel "Test cstring from BString" $
  TestCase $ assertEqual "" (p,BString s) (cstring (p,BString s))
  where s=[T,T,T,T]
        p=(opcodes M.! "CS")++[F,T,F,T]++(opcodes M.! "ES")

testBtS = TestLabel "Test inserting BString opcodes into BitSeries" $
  TestCase $ assertEqual "" p (bsToString s)
  where s=[T,T,F,F]++[T,T,F,F]
        p=(o "CS")++[T,T,F,F]++(o "CS")++[T,T,F,F]++(o "ES")
        o t = opcodes M.! t
testBtS2 = TestLabel "Test inserting BString opcodes into uneven BitSeries" $
  TestCase $ assertEqual "" p (bsToString s)
  where s=[T,T,F,F]++[T,T,F,F]++[T]
        p= (o "CS")++[T,T,F,F]++(o "CS")++[T,T,F,F]++(o "CS")++[T,F,F,F]
         ++(o "ES")
        o t = opcodes M.! t

testBtDT = TestLabel "Test converting BitSeries to BString DataType" $
  TestCase $ assertEqual "" (p',BString s) (tD $ bsToDT s)
  where s=[F,F,T,T]++[F,F,F,T]
        p=(o "CS")++[F,F,T,T]++(o "CS")++[F,F,F,T]++(o "ES")
        p'=p++[{-Terminate-}]
        o t = opcodes M.! t

strTests = TestLabel "String" $
  TestList[ testLstring, testCs1, testCs2, testBtS, testBtS2, testBtDT ]

-- Integer Tests
testLinteger = TestLabel "Test linteger " $
  TestCase $ assertEqual "" (BInteger 15) (linteger p)
  where p=[F]++(opcodes M.! "CS")++[T,T,T,T]++(opcodes M.! "ES")

testCi1 = TestLabel "Test cinteger from BStatement" $
  TestCase $ assertEqual "" (p,BInteger (-4)) (cinteger (p,BStatement))
  where p=[T]++(opcodes M.! "CS")++[T,T,F,F]++(opcodes M.! "ES")
testCi2 = TestLabel "Test cinteger from BInteger" $
  TestCase $ assertEqual "" (p,BInteger (-9)) (cinteger (p,BInteger (-9)))
  where p=[F]++(opcodes M.! "CS")++[F,T,F,T]++(opcodes M.! "ES")

testItBn = TestLabel "Test converting int to binary" $
  TestCase $ assertEqual "" p (intToBin 4132)
  where p=[F,T,F,F]++[F,F,T,F]++[F,F,F,F]++[F,F,F,T]
testItBn2 = TestLabel "Test converting negative int to binary" $
  TestCase $ assertEqual "" p (intToBin $ -976)
  where p=[F,F,F,F]++[F,F,T,T]++[T,T,F,F]
testItBn0 = TestLabel "Test converting 0 to binary" $
  TestCase $ assertEqual "" p (intToBin 0)
  where p=[]

testItB = TestLabel "Test converting int to BitSeries" $
  TestCase $ assertEqual "" p (intToBS 10)
  where p = [F]++(o "CS")++[T,F,T,F]++(o "ES")
        o t = opcodes M.! t
testItB2 = TestLabel "Test converting negative int to BitSeries" $
  TestCase $ assertEqual "" p (intToBS (-55))
  where p = [T]++(o "CS")++[T,F,F,T]++(o "CS")++[T,T,F,F]++(o "ES")
        o t = opcodes M.! t
testItB0 = TestLabel "Test converting -1 to BitSeries" $
  TestCase $ assertEqual "" p (intToBS (-1))
  where p = [T]++(o "ES")
        o t = opcodes M.! t

testItDT = TestLabel "Test converting integer to BInteger DataType" $
  TestCase $ assertEqual "" (p',BInteger i) (tD $ intToDT i)
  where i=256
        p= [F]++(o "CS")++[F,F,F,F]++(o "CS")++[F,F,F,F]++(o "CS")
         ++[F,F,F,T]++(o "ES")
        p'=p++[{-Terminate-}]
        o t = opcodes M.! t

intTests = TestLabel "Integer" $
  TestList [ testLinteger, testCi1, testCi2, testItBn, testItBn2, testItBn0
           , testItB, testItB2, testItB0, testItDT ]

-- Rational Tests
testLrational = TestLabel "Test lrational" $
  TestCase $ assertEqual "" (BRational 15 (-3)) (lrational p)
  where p= [F]++(opcodes M.! "CS")++[T,T,T,T]++(opcodes M.! "ES")
         ++[T]++(opcodes M.! "CS")++[T,T,F,T]++(opcodes M.! "ES")
testCr1 = TestLabel "Test crational from BStatement" $
  TestCase $ assertEqual "" (p,BRational (-4) 1) (crational (p,BStatement))
  where p= [T]++(opcodes M.! "CS")++[T,T,F,F]++(opcodes M.! "ES")
         ++[F]++(opcodes M.! "CS")++[F,F,F,T]++(opcodes M.! "ES")
testCr2 = TestLabel "Test crational from BRational" $
  TestCase $ assertEqual "" (p,BRational 7 1234) (crational (p,BRational 7 1234))
  where p= [F]++(opcodes M.! "CS")++[T,T,T,T]++(opcodes M.! "ES")
         ++[F]++(opcodes M.! "ES")

testIItB = TestLabel "Test converting two-integer rational into BitSeries" $
  TestCase $ assertEqual "" p (rtlToBS a b)
  where a=(-127)
        b=0
        p=[T]++(o "CS")++[F,F,F,T]++(o "CS")++[T,F,F,F]++(o "ES")++[F]++(o "ES")
        o t = opcodes M.! t
testRtB = TestLabel "Test converting rational into BitSeries" $
  TestCase $ assertEqual "" p (rtlToBS' a)
  where a=(-12)%(29)
        p= [T]++(o "CS")++[F,T,F,F]++(o "ES")++[F]++(o "CS")++[T,T,F,T]++(o "CS")
         ++[F,F,F,T]++(o "ES")
        o t = opcodes M.! t

testIItDT = TestLabel "Test converting two-integer rational into DataType" $
  TestCase $ assertEqual "" (p',BRational a b) (tD $ rtlToDT a b)
  where a=22
        b=(-1)
        p=[F]++(o "CS")++[F,T,T,F]++(o "CS")++[F,F,F,T]++(o "ES")++[T]++(o "ES")
        p'=p++[{-Terminate-}]
        o t = opcodes M.! t
testRtDT = TestLabel "Test converting rational into DataType" $
  TestCase $ assertEqual "" (p',BRational a b) (tD $ rtlToDT' c)
  where a=13
        b=9
        c=a%b
        p=[F]++(o "CS")++[T,T,F,T]++(o "ES")++[F]++(o "CS")++[T,F,F,T]++(o "ES")
        p'=p++[{-Terminate-}]
        o t = opcodes M.! t

rationalTests = TestLabel "Rational" $
  TestList [ testLrational, testCr1, testCr2, testIItB, testRtB, testIItDT
           , testRtDT ]

-- Namespace Tests
maid :: ANmsp -> DataType
maid x = ([],BNmspId $ Left x)

mrid :: RNmsp -> DataType
mrid x = ([],BNmspId $ Right x)

testLNmsp = TestLabel "Test lnmsp" $
  TestCase $ assertEqual "" (snd $ maid id) (lnmsp p)
  where id=[[T,T,T,T]]
        p=(o "AN")++(o "CN")++(o "CS")++[T,T,T,T]++(o "ES")++(o "EN")
        o s=opcodes M.! s

testCn1 = TestLabel "Test cnmsp 1" $
  TestCase $ assertEqual "" (maid id) (cnmsp $ maid id)
  where id=[[T,T,F,F]]

testCn2 = TestLabel "Test cnmsp 2" $
  TestCase $ assertEqual "" (p,snd $ maid id) (cnmsp (p,BStatement))
  where id=[[F,T,F,F],[T,F,F,F]]
        p=(o "AN")++(o "CN")++(o "CS")++id!!0++(o "ES")++(o "CN")
         ++(o "CS")++id!!1++(o "ES")++(o "EN")
        o s=opcodes M.! s

nmspTests = TestLabel "Namespace" $
  TestList [ testLNmsp, testCn1, testCn2 ]

-- Statement Tests
testCt1 = TestLabel "Test cstmt 1" $
  TestCase $ assertEqual "" (p,BStatement) (cstmt (p,BString [T,T,T,F,T]))
  where p=replicate 55 T++[F,T,F]
testCt2 = TestLabel "Test cstmt 2" $
  TestCase $ assertEqual "" (p,BStatement) (cstmt (p,BStatement))
  where p=replicate 23 F++[T,F,T]

stmtTests = TestLabel "Statement" $
  TestList [ testCt1, testCt2 ]

-- Comparison Tests
testCmpS1 = TestLabel "Test comparing strings 1" $
  TestCase $ assertEqual "" LT $ cmpdt (bsToDT [F,F,T,T]) (bsToDT [T,F,F,F]) []
testCmpS2 = TestLabel "Test comparing strings 2" $
  TestCase $ assertEqual "" GT $ cmpdt (bsToDT [F,F,T,T,F])
                                       (bsToDT [F,F,T,T]) []
testCmpS3 = TestLabel "Test comparing strings 3" $
  TestCase $ assertEqual "" EQ $ cmpdt (bsToDT [F,T,T,T,F]) 
                                       (bsToDT [F,T,T,T,F]) []

testCmpI1 = TestLabel "Test comparing integers 1" $
  TestCase $ assertEqual "" LT $ cmpdt (intToDT 22) (intToDT 9000) []
testCmpI2 = TestLabel "Test comparing integers 2" $
  TestCase $ assertEqual "" GT $ cmpdt (intToDT 0) (intToDT (-1)) []
testCmpI3 = TestLabel "Test comparing integers 3" $
  TestCase $ assertEqual "" EQ $ cmpdt (intToDT (-12345678910)) 
                                       (intToDT (-12345678910)) []

testCmpR1 = TestLabel "Test comparing rationals 1" $
  TestCase $ assertEqual "" LT $ cmpdt (rtlToDT 900 0) (rtlToDT 1 1) []
testCmpR2 = TestLabel "Test comparing rationals 2" $
  TestCase $ assertEqual "" GT $ cmpdt (rtlToDT 25 24) (rtlToDT 0 0) []
testCmpR3 = TestLabel "Test comparing rationals 3" $
  TestCase $ assertEqual "" EQ $ cmpdt (rtlToDT 95 0) (rtlToDT (-22) 0) []
testCmpR4 = TestLabel "Test comparing rationals 4" $
  TestCase $ assertEqual "" LT $ cmpdt (rtlToDT 90 (-1)) (rtlToDT 4 3) []
testCmpR5 = TestLabel "Test comparing rationals 5" $
  TestCase $ assertEqual "" GT $ cmpdt (rtlToDT 25 24) (rtlToDT 153 154) []
testCmpR6 = TestLabel "Test comparing rationals 6" $
  TestCase $ assertEqual "" EQ $ cmpdt (rtlToDT 95 5) (rtlToDT 38 2) []

testCmpN1 = TestLabel "Test comparing namepsaces 1" $
  TestCase $ assertEqual "" LT $ cmpdt n1 n2 []
  where n1=([],BNmspId $ Left [[T,T,T,T],[T,F,T,F]])
        n2=([],BNmspId $ Left [[T,T,T,T]])
testCmpN2 = TestLabel "Test comparing namespaces 2" $
  TestCase $ assertEqual "" GT $ cmpdt n1 n2 []
  where n1=([],BNmspId $ Left [[T,T,T,T],[T,F,T,F]])
        n2=([],BNmspId $ Left [[T,T,T,T],[T,F,F,F]])
testCmpN3 = TestLabel "Test comparing namespaces 3" $
  TestCase $ assertEqual "" EQ $ cmpdt n1 n2 [[T,T,T,T]]
  where n1=([],BNmspId $ Left [[T,T,T,T],[T,F,T,F]])
        n2=([],BNmspId $ Right [Child [T,F,T,F]])

testCmpT1 = TestLabel "Test comparing statements 1" $
  TestCase $ assertEqual "" LT $ cmpdt s1 s2 []
  where s1=([T,T,F,T],BStatement)
        s2=([T,T,T,F],BStatement)
testCmpT2 = TestLabel "Test comparing statements 2" $
  TestCase $ assertEqual "" GT $ cmpdt s1 s2 []
  where s1=([T,T,T,T,F,F],BStatement)
        s2=([T,T,T,T,F],BStatement)
testCmpT3 = TestLabel "Test comparing statements 3" $
  TestCase $ assertEqual "" EQ $ cmpdt s1 s2 []
  where s1=(replicate 22 F++[T,F],BStatement)
        s2=(replicate 22 F++[T,F],BStatement)

cmpTests = TestLabel "Comparisons" $
  TestList [ testCmpS1, testCmpS2, testCmpS3, testCmpI1, testCmpI2, testCmpI3
           , testCmpR1, testCmpR2, testCmpR3, testCmpR4, testCmpR5, testCmpR6
           , testCmpN1, testCmpN2, testCmpN3, testCmpT1, testCmpT2, testCmpT3
           ]

-- Boolean Tests
testBtSF = TestLabel "Test converting False to BString" $
  TestCase $ assertEqual "" (bsToDT []) (boolToDT (BString []) False)
testBtST = TestLabel "Test converting True to BString" $
  TestCase $ assertEqual "" (bsToDT [F,F,F,F]) (boolToDT (BString []) True)

testBtIF = TestLabel "Test converting False to BInteger" $
  TestCase $ assertEqual "" (intToDT 0) (boolToDT (BInteger 0) False)
testBtIT = TestLabel "Test converting True to BInteger" $
  TestCase $ assertEqual "" (intToDT 1) (boolToDT (BInteger 0) True)

testBtRF = TestLabel "Test converting False to BRational" $
  TestCase $ assertEqual "" (rtlToDT 0 1) (boolToDT (BRational 0 0) False)
testBtRT = TestLabel "Test converting True to BRational" $
  TestCase $ assertEqual "" (rtlToDT (-1) (-1)) (boolToDT (BRational 0 0) True)

testBtNF = TestLabel "Test converting False to BNmspID" $
  TestCase $ assertEqual "" dt (boolToDT (BNmspId $ Left []) False)
  where dt=((o "AN")++(o "EN"),BNmspId $ Left [])
        o t = opcodes M.! t
testBtNT = TestLabel "Test converting True to BNmspID" $
  TestCase $ assertEqual "" dt (boolToDT (BNmspId $ Left [])  True)
  where dt=((o "AN")++(o "CN")++(o "ES")++(o "EN"),BNmspId $ Left [[]])
        o t = opcodes M.! t

testBtTF = TestLabel "Test converting False to BStatement" $
  TestCase $ assertEqual "" st (boolToDT (BStatement) False)
  where st=((o "LS")++(o "LT")++(o "ES"),BStatement)
        o t = opcodes M.! t
testBtTT = TestLabel "Test converting True to BStatement" $
  TestCase $ assertEqual "" st (boolToDT (BStatement) True)
  where st=((o "LS")++(o "LT")++(o "CS")++[F,F,F,F]++(o "ES"),BStatement)
        o t = opcodes M.! t

testStF = TestLabel "Test converting BString to False" $
  TestCase $ assertEqual "" False (dtToBool $ bsToDT [])
testStT = TestLabel "Test converting BString to True" $
  TestCase $ assertEqual "" True (dtToBool $ bsToDT (replicate 100 F))

testItF = TestLabel "Test converting BInteger to False" $
  TestCase $ assertEqual "" False (dtToBool $ intToDT 0)
testItT = TestLabel "Test converting BInteger to True" $
  TestCase $ assertEqual "" True (dtToBool $ intToDT (-1356314))

testRtF = TestLabel "Test converting BRational to False" $
  TestCase $ assertEqual "" False (dtToBool $ rtlToDT 0 392587)
testRtT = TestLabel "Test converting BRational to True" $
  TestCase $ assertEqual "" True (dtToBool $ rtlToDT 12345 43210)

testNtF = TestLabel "Test converting BNmspId to False" $
  TestCase $ assertEqual "" False (dtToBool $ ns)
  where ns = ((o "AN")++(o "EN"),BNmspId $ Left [])
        o t = opcodes M.! t
testNtT = TestLabel "Test converting BNmspId to True" $
  TestCase $ assertEqual "" True (dtToBool $ ns)
  where ns = ((o "RN")++(o "ERN"),BNmspId $ Right [])
        o t = opcodes M.! t

testTtF = TestLabel "Test converting BStatement to False" $
  TestCase $ assertEqual "" False (dtToBool $ s)
  where s = ((o "LS")++(o "LT")++(o "ES"),BStatement)
        o t = opcodes M.! t
testTtT = TestLabel "Test converting BStatement to True" $
  TestCase $ assertEqual "" True (dtToBool $ s)
  where s = ((o "FS")++(o "TS")++(o "LS")++(o "LT")++(o "ES")++(o "LS")
           ++(o "LN")++(o "AN")++(o "EN"),BStatement)
        o t = opcodes M.! t

boolTests = TestLabel "Booleans" $
  TestList [ testBtSF, testBtST, testBtIF, testBtIT, testBtRF, testBtRT
           , testBtNF, testBtNT, testBtTF, testBtTT, testStF, testStT, testItF
           , testItT, testRtF, testRtT, testNtF, testNtT, testTtF, testTtT
           ]

mainList = TestLabel "DataType.Util" $ 
  TestList [ strTests, intTests, rationalTests, nmspTests, stmtTests, cmpTests ]
main = runTestTT $ TestList [ B.mainList, P.mainList, D.mainList, mainList]
