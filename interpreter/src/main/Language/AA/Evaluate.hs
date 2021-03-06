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
-- This module evaluates a program's AST in accordance with Sections VI and VII
-- of the Advanced Assembly 0.5.2 specification.
module Language.AA.Evaluate where

import Control.Applicative
import Control.Arrow
import Control.Monad
import qualified Data.Data as D
import Data.Fixed
import Data.List
import qualified Data.Map as M
import Data.Maybe
import Data.Monoid
import Data.Ratio
import Language.AA.BitSeries
import Language.AA.DataType
import Language.AA.DataType.Util
import Language.AA.Opcodes
import Language.AA.Statement
import Text.Parsec.Combinator
import qualified Text.Parsec.Prim as P

type StateP m = (ANmsp,(Namespaces,(DataType -> m DataType)))
newtype State m = S {gs :: (ANmsp,
                            (Namespaces,
                             (DataType -> m DataType,
                              State m -> m (State m)))) }

-- Namespace definitions
type Namespaces = M.Map ANmsp DataType

defaultNamespace :: BitSeries -> Namespaces
defaultNamespace p = M.fromList [([],(p,BStatement))]

nmspValue :: ANmsp -> DataType -> Namespaces -> DataType
nmspValue a b =  M.findWithDefault (opcodes M.! "ES",BString []) (gnmsp a b)

nmspValue' :: Monad m=> State m -> DataType -> (State m,DataType)
nmspValue' a b = (a,nmspValue (fst $ gs a) b (fst $ snd $ gs a))

nmspValueSet :: ANmsp -> DataType -> DataType -> Namespaces -> Namespaces
nmspValueSet a b = M.insert $ gnmsp a b

nmspValueSet' :: Monad m=> State m -> DataType -> DataType ->(State m ,DataType)
nmspValueSet' a b c = (S$s$gs a,c)
  where s = second . first . const $ nmspValueSet (fst$gs a) b c (fst$snd$gs a)

-- Utilities
parseST :: P.Parsec BitSeries () DStmt -> BitSeries -> DStmt
parseST p b = case (P.runP p () "" (b++repeat F)) of
  Left e                    -> error $ show e
  Right ((bs,BStatement),s) -> ((b,BStatement),s)

sfilter :: Monad m => P.ParsecT BitSeries u m [Bool]
sfilter = do
  let cs = mopc "CS">>replicateM 4 anyToken>>return [False,True,True,True,True]
  bs <- P.many cs
  mopc "ES"
  return $ mconcat bs++[False]

ifilter :: Monad m => P.ParsecT BitSeries u m [Bool]
ifilter = (True:) <$> sfilter

rfilter :: Monad m => P.ParsecT BitSeries u m [Bool]
rfilter = (++) <$> ifilter <*> ifilter

anfilter :: Monad m => P.ParsecT BitSeries u m [Bool]
anfilter = do
  let cn = mopc "CN">>(False:) <$> sfilter
  cn <- P.many cn
  mopc "EN"
  return $ mconcat cn++[False]
rnfilter :: Monad m => P.ParsecT BitSeries u m [Bool]
rnfilter = do
  let cn = (P.try$mopc "CN")>>(False:) <$> sfilter
  let pn = (P.try$mopc "PN")>>return [False]
  cn <- P.many $ cn <|> pn
  mopc "ERN"
  return $ mconcat cn++[False]
nfilter :: Monad m => P.ParsecT BitSeries u m [Bool]
nfilter = an <|> rn
  where an = (P.try$mopc "AN")>>(False:) <$> anfilter
        rn = (P.try$mopc "RN")>>(False:) <$> rnfilter

prflt = [ undefined, nfilter, sfilter, ifilter, rfilter ]
fpattern :: DataType -> [Bool]
fpattern (_,BStatement) = repeat True
fpattern d = case (P.parse (prflt!!prior' d) "" (fst d++repeat F)) of
  Left  e -> error $ show e
  Right r -> r++repeat True

filter' :: DataType -> BitSeries
filter' d = f (fpattern d) (fst d)
  where f :: [Bool] -> BitSeries -> BitSeries
        f a b = catMaybes $ zipWith (\b v->if b then Just v else Nothing) a b

unfilter :: DataType -> BitSeries -> DataType
unfilter d b = (prcnv!!prior' d) (f p (fst d) b,BStatement)
  where p = fpattern d
        f :: [Bool] -> BitSeries -> BitSeries -> BitSeries
        f _          []     _      = []
        f _          c      []     = c
        f (True :bs) (c:cs) (d:ds) = d:(f bs cs ds)
        f (False:bs) (c:cs) (d:ds) = c:(f bs cs ds)
        f _          c      _      = c

applyBitwise :: (BitSeries -> BitSeries) -> DataType -> DataType
applyBitwise f (a,BStatement) = (f a,BStatement)
applyBitwise f dt = unfilter dt $ f $ filter' dt

applyBitwise2::(BitSeries->BitSeries->BitSeries)->DataType->DataType->DataType
applyBitwise2 f da db = unfilter da $ f (filter' da) (filter' db ++ repeat F)

-- Operations
prlst = [ D.toConstr $ BStatement, D.toConstr $ BNmspId $ Left []
        , D.toConstr $ BString [], D.toConstr $ BInteger 0
        , D.toConstr $ BRational 0 0
        ]
prcnv = [ cstmt, cnmsp, cstring, cinteger, crational ]

prior :: Primitive -> Int
prior p = maybe (error "Unknown Primitive constructor!") id $ 
  elemIndex (D.toConstr p) prlst
prior' :: DataType -> Int
prior' = prior . snd

ensureMin :: Int -> DataType -> DataType
ensureMin a b = if a > (prior' b) then (prcnv!!a) b else b
ensureMin' :: Primitive -> DataType -> DataType
ensureMin' a = ensureMin (prior a)

normDT :: DataType -> DataType -> (DataType,DataType)
normDT a b = (ensureMin m a, ensureMin m b)
  where m = max (prior' a) (prior' b)

normMDT :: Primitive -> DataType -> DataType -> (DataType,DataType)
normMDT a b = normDT (ensureMin' a b)

evaluateMSB :: Monad m => Free Stmt DataType -> State m -> m (State m,DataType)
evaluateMSB (Free (MSB p a b)) s = do
  (s2,av) <- evaluate' a s
  (s3,bv) <- evaluate' b s2
  let v=case p of
          "OP" -> case (normMDT (BString []) av bv) of
            ((_,BString t),(_,BString u)) -> bsToDT (t++u)
            ((_,BInteger t),(_,BInteger u)) -> intToDT (t+u)
            ((_,BRational t u),(_,BRational v w)) -> if u==0||w==0 then 
              rtlToDT 0 0 else rtlToDT' ((t%u)+(v%w))
          "OM" -> case (normMDT (BInteger 0) av bv) of
            ((_,BInteger t),(_,BInteger u)) -> intToDT (t-u)
            ((_,BRational t u),(_,BRational v w)) -> if u==0||w==0 then 
              rtlToDT 0 0 else rtlToDT' ((t%u)-(v%w))
          "OT" -> case (normMDT (BInteger 0) av bv) of
            ((_,BInteger t),(_,BInteger u)) -> intToDT (t*u)
            ((_,BRational t u),(_,BRational v w)) -> if u==0||w==0 then 
              rtlToDT 0 0 else rtlToDT' ((t%u)*(v%w))
          "OD" -> case (normMDT (BInteger 0) av bv) of
            ((_,BInteger t),(_,BInteger u)) -> if u==0 then
              rtlToDT 0 0 else intToDT $ t`div`u
            ((_,BRational t u),(_,BRational v w)) -> if u==0||w==0||v==0 then 
              rtlToDT 0 0 else rtlToDT' ((t%u)/(v%w))
          "OE" -> case (ensureMin' (BInteger 0) av,cinteger bv) of
            ((_,BInteger t),(_,BInteger u)) -> intToDT (t^(abs$u))
            ((_,BRational t u),(_,BInteger v)) -> if u==0 then 
              rtlToDT 0 0 else rtlToDT' ((t%u)^^(abs$v))
          "OU" -> case (normMDT (BInteger 0) av bv) of
            ((_,BInteger t),(_,BInteger u)) -> if u==0 then
              rtlToDT 0 0 else intToDT $ abs (t`rem`u)
            ((_,BRational t u),(_,BRational v w)) -> if u==0||w==0||v==0 then 
              rtlToDT 0 0 else rtlToDT' ((abs$t%u)`mod'`(abs$v%w))
          "BO" -> boolToDT (snd av') $ (dtToBool av') || (dtToBool bv')
            where (av',bv')=normDT av bv
          "BX" -> boolToDT (snd av') $ (dtToBool av') /= (dtToBool bv')
            where (av',bv')=normDT av bv
          "BA" -> boolToDT (snd av') $ (dtToBool av') && (dtToBool bv')
            where (av',bv')=normDT av bv
          "BE" -> boolToDT (snd av') $ (cmpdt av' bv' $ fst $ gs s3)==EQ
            where (av',bv')=normDT av bv
          "BL" -> boolToDT (snd av') $ (cmpdt av' bv' $ fst $ gs s3)==LT
            where (av',bv')=normDT av bv
          "BLE" -> boolToDT (snd av') $ (c==LT)||(c==EQ)
            where (av',bv')=normDT av bv
                  c=(cmpdt av' bv' $ fst $ gs s3)
          "BG" -> boolToDT (snd av') $ (cmpdt av' bv' $ fst $ gs s3)==GT
            where (av',bv')=normDT av bv
          "BGE" -> boolToDT (snd av') $ (c==GT)||(c==EQ)
            where (av',bv')=normDT av bv
                  c=(cmpdt av' bv' $ fst $ gs s3)
          "TO" -> applyBitwise2 (zipWith (||)) av' bv'
            where (av',bv')=normDT av bv
          "TX" -> applyBitwise2 (zipWith (/=)) av' bv'
            where (av',bv')=normDT av bv
          "TA" -> applyBitwise2 (zipWith (&&)) av' bv'
            where (av',bv')=normDT av bv
          "TH" -> applyBitwise (shift j) av
            where (BInteger j) = linteger $ fst bv
                  shift :: Integer -> BitSeries -> BitSeries
                  shift i b
                    | d == [] = map (const F) b
                    | i == 0  = b
                    | i >  0  = d ++ r
                    | i <  0  = r ++ d
                    where j = abs i
                          r = replicate (fromIntegral j) F
                          d = drop (fromIntegral j) b
          "TR" -> applyBitwise (rotate j) av
            where (BInteger j) = linteger $ fst bv
                  rotate :: Integer -> BitSeries -> BitSeries
                  rotate h b
                    | gl b == 0 = b
                    | i == 0    = b
                    | i >  0    = gd i b ++ gt i b
                    | i <  0    = gt i b ++ gd i b
                    where i = h `rem` gl b
                          gr = \a b -> replicate (fromIntegral a) b
                          gd = \a b -> drop (fromIntegral a) b
                          gt = \a b -> take (fromIntegral a) b
                          gl = fromIntegral . length

  return (s3,v)


-- Evaluate definitions
evaluate :: Monad m=> Free Stmt DataType -> State m -> m (State m,DataType)
evaluate (Pure a)             s = return (s,a)
evaluate (Free (AS a b))      s = do
  (s2,av) <- evaluate' a s
  (s3,bv) <- evaluate' b s2
  return $ nmspValueSet' s3 av bv
evaluate (Free (RS a))        s = do
  (s2,av) <- evaluate' a s
  return $ nmspValue' s2 av
evaluate (Free (ET a b))      s = do
  (s2,av) <- evaluate' a s
  let n = gnmsp (fst $ gs s2) av
  let nid i = n++[intToBS i]
  (s3,_) <- foldl (\v a -> do {
      (s,i)<-v;
      (t,u) <- evaluate' a s;
      return (S (fst$gs t,(M.insert (nid i) u (fst$snd$gs t),snd$snd$gs t)),i+1)
    }) (return (s2,1)) b
  let v = fst $ nmspValue (fst$gs s3) av (fst$snd$gs s3)
  let f = snd $ parseST loadStmt v
  (S (_,nm),d) <- evaluate' f $ S (n,snd$gs s3)
  return $ (S (fst$gs s,nm),d)
evaluate (Free (SQ a b))      s = do
  (s2,_) <- evaluate' a s
  evaluate' b s2
evaluate (Free (IF a b c))    s = do
  (s2,av) <- evaluate' a s
  if dtToBool av
    then evaluate' b s2
    else evaluate' c s2
evaluate (Free (DW a b))      s = do
  let dw s = do {
    (s2,v) <- evaluate' a s; 
    (s3,c) <- evaluate' b s2;
    -- Perhaps add in some checks here to prevent pointless infinite loops:
    -- if a loop operation and conditional check result in a state identical
    -- to the initial state, and neither the operation nor the conditional
    -- contain I/O, then the loop can be considered pointless because it will
    -- never break and never have side effects. Thus, we can safely exit the
    -- loop and continue with the program without missing any critical
    -- calculations.
    -- 
    -- A pointless loop in pseudo code: while (true) { 7 }
    -- A pointful loop in pseudo code: while (true) { i = i+1 }
    -- A pointless loop: while (true) { i = i+1; i = i-1 }
    -- A pointful loop: while (true) { print "spam." }
    --
    -- Because the first loop has neither a side effect nor an I/O call, we can
    -- conclude that though the loop will never terminate, it will always
    -- evaluate to 7. Therefore, we can assign the statement as a whole a value
    -- of 7. The second statement can never be completed because each iteration
    -- will evaluate to a different value. The third statement appears to change
    -- the program state, but the changes cancel each other out resulting in a
    -- consistant state. Thus, the third statement can be evaluated to "i".
    -- The final statement does not change the program state and will always 
    -- evaluate to the same value. However, the loop must continue indefinitely
    -- because the I/O call means that while terminating the loop may not result
    -- in any inconsistencies within the AA program, it will result in
    -- inconsistencies between the program and the outside world.
    if dtToBool c then dw s3 else return (s3,v)
  }
  dw s
evaluate (Free (IOS a))       s = do
  (s2,av) <- evaluate' a s
  r <- (fst$snd$snd$gs s) av
  return $ (s2,r)
evaluate (Free (MSA p a))     s = do
  (s2,av) <- evaluate' a s
  let v=case p of
          "BN" -> boolToDT (snd av) . not . dtToBool $ av
          "TN" -> applyBitwise (fmap not) av
  return (s2,v)
evaluate a@(Free (MSB _ _ _)) s = evaluateMSB a s

-- Intermediary function called between every step.
evaluate' :: Monad m => Free Stmt DataType -> State m -> m (State m,DataType)
evaluate' f s = do
  let S (a,(b,(c,f'))) = s
  s' <- f' s
  evaluate f s'
