{-# OPTIONS -Wall #-}
data Card = I | Zero | Succ | Dbl | Get | Put | S | K | Inc | Dec | Attack | Help | Copy | Revive | Zombie

cardName :: Card -> String
cardName I       = "I"       
cardName Zero    = "zero"    
cardName Succ    = "succ"    
cardName Dbl     = "dbl"     
cardName Get     = "get"     
cardName Put     = "put"     
cardName S       = "S"       
cardName K       = "K"       
cardName Inc     = "inc"     
cardName Dec     = "dec"     
cardName Attack  = "attack"  
cardName Help    = "help"    
cardName Copy    = "copy"    
cardName Revive  = "revive"    
cardName Zombie  = "zombie"  


right, left :: Int -> Card -> IO ()
right s c = do
  putStrLn "2"
  putStrLn $ cardName c
  print s
  
left s c = do
  putStrLn "1"
  putStrLn $ cardName c
  print s
  
main :: IO ()  
main = do
  right 0 Zero
  left  0 Succ