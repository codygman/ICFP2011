{-# OPTIONS -Wall #-}
import LTG hiding(($<), ($>))
import System.Environment
import System.IO
import System.Exit

skip :: IO ()
skip = do
  iseof <- hIsEOF stdin 
  if iseof 
    then exitSuccess 
    else do
    _ <- getLine
    _ <- getLine
    _ <- getLine
    return ()

($<) x y = do
  right x y
  skip
  
($>) x y = do
  left x y
  skip

-- Love me do
apply0 :: Int -> IO ()
apply0 field = do
  K $> field
  S $> field
  field $< Get
  field $< Zero

clear :: Int -> IO()
clear field = do
  Zero $> field

num :: Int -> Int -> IO ()
num field n = do
  clear field
  field $< Zero
  num_iter n
  where
    num_iter 0 = do
      return ()
    num_iter 1 = do
      Succ $> field
    num_iter q = do
      num_iter (q `div` 2)
      Dbl $> field
      if q `mod` 2 == 0 
        then return ()
        else (Succ $> field) >> (return ())

-- Example: attack 3 4 10
attack from to value = do
  -- v[1] <- (Attack from)
  num 1 from
  Attack $> 1
  -- v[0] <- to
  num 0 to
  -- v[1] <- apply v[1] v[0]
  apply0 1
  -- v[0] <- value
  num 0 value
  -- v[1] <- apply v[1] v[0]
  apply0 1

copytozero :: Int -> IO ()
copytozero field = do
  num 0 field
  Get $> 0

-- inject zombie that attack
inject_sayasaya :: Int -> Int -> Int -> Int -> Int -> IO ()
inject_sayasaya f1 f2 fdmg fgain dmg = do
  -- v[f1] <- S (K (attack fdmg fgain))
  num f1 fdmg
  Attack $> f1
  num 0 (255 - fgain)
  apply0 f1
  K $> f1
  S $> f1
  -- v[0] <- K dmg
  num 0 dmg
  K $> 0
  -- Sayasaya ready
  apply0 f1
  -- Inject!
  f2 $< Zero
  Zombie $> f2
  copytozero f1
  apply0 f2

sittingDuck :: IO()
sittingDuck = do
  I $> 0
  sittingDuck
  
attackloop :: Int -> Int -> Int -> IO()
attackloop v k s = do
  attack v k 8192
  attack (v+1) k 8192
  inject_sayasaya 3 4 s s 10000
  if v > 240 
    then attackloop 5 (k+1) 0
    else attackloop (v+2) (k+1) (s+1)

main :: IO()
main = do
  [arg] <- getArgs
  let b = (read arg :: Int) -- 0: Sente, 1: Gote
  if b == 1 then skip else return ()
  attackloop 5 0 0
  sittingDuck



