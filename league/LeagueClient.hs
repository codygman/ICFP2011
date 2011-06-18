#!/usr/bin/env runhaskell
{-# OPTIONS -Wall #-}

import Control.Monad
import League 
import Network.MessagePackRpc.Client
import System.IO
import System.Process

suggestMatch :: RpcMethod (IO (String, String))
suggestMatch = method "suggestMatch"

reportMatch :: RpcMethod ((String, String) -> String -> IO ())
reportMatch = method "reportMatch"

seal :: String -> String
seal cmd = "'./nostderr.rb " ++  cmd ++ "'"

main :: IO ()
main = do
  conn <- connect "192.168.0.1" port
  forever $ do
    (cmd0, cmd1) <- suggestMatch conn 
    let vs :: String -> String -> IO ()
        vs cmd0' cmd1' = do
              let cmd = "../bin/ltg -silent true match " ++ seal cmd0' ++ " " ++ seal cmd1'
              hPutStrLn stderr cmd
              (_, _, Just herr,_) <- createProcess (shell cmd) {std_err = CreatePipe}
              ret <- hGetContents herr
              --_ <- length ret `seq` waitForProcess hdl
              let result = last $ filter ((=="!!").(take 2)) $ lines ret
              reportMatch conn (cmd0', cmd1') result
    cmd0 `vs` cmd1
    cmd1 `vs` cmd0





