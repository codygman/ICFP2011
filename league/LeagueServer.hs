#!/usr/bin/env runhaskell
{-# OPTIONS -Wall #-}

import Control.Concurrent.STM
import Control.Monad
import Data.Char
import Data.Vector (Vector, (!), (//))
import qualified Data.Vector as V
import League
import Network.MessagePackRpc.Server
import System.IO
import System.IO.Unsafe
import System.Posix.Files
import System.Random

resultFile :: String
resultFile = "result.txt"

scoreBoard :: TVar (Vector (Vector Int))
scoreBoard = unsafePerformIO $ newTVarIO $ V.replicate aiSize $ V.replicate aiSize 0

matchCount :: TVar (Vector (Vector Int))
matchCount = unsafePerformIO $ newTVarIO $ V.replicate aiSize $ V.replicate aiSize 0


suggestMatch :: IO (String, String)
suggestMatch = do
  rand <- randomRIO (0,1)
  (i0, i1) <- atomically $ do
                 mc <- readTVar matchCount
                 let match@(i0, i1) = selectMatch rand mc
                 writeTVar matchCount $  modify2 i0 i1 (+1) $ modify2 i1 i0 (+1) mc
                 return $ match
  return (command $ ais!i0, command $ ais!i1)

reportMatch :: (String, String) -> String -> IO ()
reportMatch (cmd0, cmd1) result = do
  recordMatch True match
  where
    wr = words result
    turn' = read $ last wr
    score0'
          | wr !! 1 == "draw" = 1
          | wr !! 2 == "0"    = if turn' < 100000 then 6 else 2
          | otherwise         = 0
    killRatioStr = head $ filter (elem ':') wr
    [a0,a1] = map read $ words $
              map (\c -> if isDigit c then c else ' ') killRatioStr
    match = Match {
              p0 = AI cmd0 ,
              p1 = AI cmd1 ,
              score0 = score0' ,
              alive0 = a0,
              alive1 = a1,
              turn = turn'
            }

-- results are string like this
-- !! player 0 wins by 256:0 after turn 22218
-- !! draw by 256:256 after turn 100000

selectMatch :: Double -> Vector (Vector Int) -> (Int, Int)
selectMatch ratio matchCount' = (ret0, ret1)
    where
      maxMC = V.maximum $ V.concat $ V.toList matchCount'
      weighted = V.toList $ V.concat $ V.toList $ imap2 mkWeight matchCount'
      (ret0, ret1) = ret
      weightSum = sum $ map fst weighted
      charge = ratio * weightSum
      ret = extract charge $ cycle weighted

      extract c ((w,x):rest)
              | c - w < 0 = x
              | True   = extract (c-w) rest
      extract _ _ = undefined

      mkWeight ix iy mc = let w = if ix==iy then 0
                                  else ((fromIntegral $ maxMC + 1 - mc)::Double)
                          in (w, (ix, iy))



recordMatchMutex :: TMVar ()
recordMatchMutex = unsafePerformIO $ newTMVarIO ()

recordMatch :: Bool -> Match -> IO ()
recordMatch isNew match = do
  atomically $ do
    bd <- readTVar scoreBoard
    writeTVar scoreBoard $ modify2 i0 i1 (+s0) bd
  atomically $ do
    bd <- readTVar matchCount
    writeTVar matchCount $ modify2 i0 i1 (+1) $ modify2 i1 i0 (+1) bd
  when isNew rec
      where
        i0 = aiIndex $ p0 match
        i1 = aiIndex $ p1 match
        s0 = score0 match
        rec = do
          _ <- atomically $ takeTMVar recordMatchMutex
          h <- openFile resultFile AppendMode
          hPutStrLn h $ show match
          hClose h
          atomically $ putTMVar recordMatchMutex ()

main :: IO ()
main = do
  results <- do
         exist <- fileExist resultFile
         if exist then fmap lines $ readFile resultFile
         else return []
  let matches :: [Match]
      matches = map read results
  mapM_ (recordMatch False) matches
  putStrLn "ready."
  serve port [ ("suggestMatch", fun suggestMatch),
               ("reportMatch" , fun reportMatch )]


---- Vector Libraries ----
map2 :: (a -> b) -> Vector (Vector a) -> Vector (Vector b)
map2 = V.map . V.map 

imap2 :: (Int -> Int -> a -> b) -> Vector (Vector a) -> Vector (Vector b)
imap2 f = V.imap (\iy -> V.imap (\ix -> f ix iy)) 

foldl2 :: (a -> a -> a) -> Vector (Vector a) -> a
foldl2 f = V.foldl1 f . V.map (V.foldl1 f)

write2 :: Int -> Int -> a -> Vector (Vector a) -> Vector (Vector a) 
write2 ix iy val vv = vv//[(iy, (vv!iy)//[(ix, val)])]

modify2 :: Int -> Int -> (a->a) -> Vector (Vector a) -> Vector (Vector a) 
modify2 ix iy f vv = vv//[(iy, (vv!iy)//[(ix, f (vv ! iy ! ix))])]

print2 :: (Show a) => Vector (Vector a) -> IO ()
print2 vv = print $ map V.toList $ V.toList vv