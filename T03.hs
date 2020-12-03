{-# LANGUAGE UnicodeSyntax, ViewPatterns, ScopedTypeVariables #-}

module T03 where

import Prelude ( IO, Int, Char, String, Bool, Show, Eq, Ord, (+),
                 pure, (.), (<$>), ($), fmap, dropWhile, span, drop, lines, words,
                 read, uncurry, fromEnum, filter, subtract, mod, error, otherwise,
                 getContents, print )
import Prelude.Unicode
import Data.Char ( isSpace )
import Data.Foldable ( foldMap, length )
import Data.Monoid
import Data.Bool.Unicode
import Control.Arrow
import Data.Vector ( fromList, Vector, (!), take, drop )

newtype RepeatVector α = RV (Vector α) deriving ( Show )

(!.) ∷ RepeatVector α → Int → α
(RV v@(length → l)) !. n = v ! (n `mod` l)

data MapVal = Empty | Tree deriving ( Show )

type TreeMap = Vector (RepeatVector MapVal)

parse ∷ String → TreeMap
parse = fromList . fmap (RV . fromList . fmap toMV) . lines
  where
    toMV '.' = Empty
    toMV '#' = Tree
    toMV x   = error $ "parse: Invalid map character '" <> [x] <> "'"


countTrees ∷ TreeMap → (Int, Int) -> Int
countTrees tm coo = getSum $ mapTrace proj tm coo
  where
    proj Tree  = Sum 1
    proj Empty = Sum 0

mapTrace ∷ ∀μ α. Monoid μ ⇒ (α → μ) → Vector (RepeatVector α) → (Int, Int) → μ
mapTrace proj tm@(length → rows) (xShift, yShift) = go 0 0
  where
    go x y
      | y ≥ rows  = mempty
      | otherwise = proj ((tm ! y) !. x) <> go (x + xShift) (y + yShift)


main ∷ IO ()
main = do
    treeMap ← parse <$> getContents
    print $ countTrees treeMap (3, 1)
    print . getProduct . foldMap (Product . countTrees treeMap) $
        [(1, 1), (3, 1), (5, 1), (7, 1), (1, 2)]
