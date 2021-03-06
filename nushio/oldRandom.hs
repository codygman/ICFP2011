{-# OPTIONS -Wall #-}

import Control.Monad
import Data.Vector ((!))
import qualified Data.Vector as V
import LTG
import Prelude hiding (putStrLn)
import System.Environment
import System.Random




main :: IO ()  
main = do
  (slotRange:seed:side:_) <- fmap (map read) getArgs
  setStdGen $ mkStdGen seed
  when (side==1) skip
  play slotRange
  

skip :: IO ()
skip = do
  _ <- getLine
  _ <- getLine
  _ <- getLine
  return ()

play :: Int -> IO ()
play slotRange = do
  ci <- randomRIO (0, V.length cards-1)
  s  <- randomRIO (0, slotRange-1)
  lr <- randomRIO (0, 1::Int)
  let c = cards ! ci
  if lr == 0 
  then (s $< c)
  else (c $> s)
  skip
  play slotRange

