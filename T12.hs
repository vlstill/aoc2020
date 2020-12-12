{-# LANGUAGE UnicodeSyntax, ScopedTypeVariables, BangPatterns, TemplateHaskell, ViewPatterns #-}

module T12 where

import Control.Lens ( makeLenses, (%~), (-~), (+~), (.~), (*~), view, (&) )
import Data.Default.Class

import Debug.Trace

data Direction = E | S | W | N | L | R | F deriving ( Eq, Show, Read, Enum )
type Action = (Direction, Int)

parseAction ∷ String → Action
parseAction (x:xs) = (read [x], read xs)
parseAction _      = error "empty action"

data ShipPosition = ShipPosition { _eastWest ∷ Int, _northSouth ∷ Int, _heading ∷ Direction } deriving Show
makeLenses ''ShipPosition

data NaviPosition = NaviPosition { _wpEW ∷ Int, _wpNS ∷ Int, _sEW ∷ Int, _sNS ∷ Int } deriving Show
makeLenses ''NaviPosition

instance Default ShipPosition where
    def = ShipPosition { _northSouth = 0, _eastWest = 0, _heading = E }

instance Default NaviPosition where
    def = NaviPosition { _wpEW = 10, _wpNS = 1, _sEW = 0, _sNS = 0 }

manhattanBy ns ew ship = abs (view ns ship) + abs (view ew ship)

navigage ∷ ShipPosition → Action → ShipPosition
navigage ship = uncurry go
  where
    go ∷ Direction → Int → ShipPosition
    go F x = go (view heading ship) x
    go R x = ship & heading %~ rotate x
    go L x = ship & heading %~ rotate (-x)
    go W x = ship & eastWest -~ x
    go E x = ship & eastWest +~ x
    go S x = ship & northSouth -~ x
    go N x = ship & northSouth +~ x

    rotate ∷ Int → Direction → Direction
    rotate x@((`mod` 90) → 0) = toEnum . rot (x `div` 90) . fromEnum
    rotate x     = error $ "rotate: " <> show x

    rot x y = (y + x) `mod` 4

navigage' ∷ NaviPosition → Action → NaviPosition
navigage' ship = traceShowId . uncurry go
  where
    go ∷ Direction → Int → NaviPosition
    go N x = ship & wpNS +~ x
    go S x = ship & wpNS -~ x
    go E x = ship & wpEW +~ x
    go W x = ship & wpEW -~ x
    go L x = ship & rotate (-x)
    go R x = ship & rotate x
    go F x = ship & do
              ns ← view wpNS
              ew ← view wpEW
              (sNS +~ ns * x) . (sEW +~ ew * x)

    rotate 0 = id
    rotate n@(signum → s) = do
                ns ← view wpNS
                ew ← view wpEW
                rotate (n - (90 * s)) . (wpNS .~ (-s) * ew) . (wpEW .~ s * ns)

main ∷ IO ()
main = do
    navigInstr ← fmap parseAction . lines <$> getContents
    print . manhattanBy northSouth eastWest $ foldl navigage def navigInstr
    print . manhattanBy sNS sEW $ foldl navigage' def navigInstr
    pure ()
