{-# LANGUAGE DataKinds #-}
module RandomMonotone where

import           Algorithms.Geometry.MonotonePolygon.MonotonePolygon

import           Control.Lens
import           Control.Monad.Random
import           Data.Ext
import           Data.Geometry.Point
import           Data.Geometry.Polygon as P
import           Data.Geometry.Polygon.Convex
import           Data.Geometry.Transformation
import Data.Geometry.Vector
import           Data.Hashable
import qualified Data.List.NonEmpty                                  as NonEmpty
import qualified Data.Vector.Circular                                as CV
import           Graphics.SvgTree                                    (Cap (..),
                                                                      LineJoin (..),
                                                                      strokeLineCap)
import           Reanimate

import           Common
import Data.RealNumber.Rational

type R = Rational -- RealNumber 5

randomMonotoneShowcase :: Animation
randomMonotoneShowcase = scene $ do
  let direction = Vector2 1 0
      p = scaleUniformlyBy (screenTop*0.9) $
        evalRand (randomMonotone 4 direction) (mkStdGen seed)
      pts = map _core $ toPoints p
      minP = P.minimumBy (cmpExtreme direction) p
      maxP = P.maximumBy (cmpExtreme direction) p
  adjustZ (+2) $ newSpriteSVG_ $ mkGroup $ map ppPoint [_core minP, _core maxP]
  wait 1
  adjustZ succ $ newSpriteSVG_ $ mkGroup $ map ppPoint pts
  wait 1
  path <- newPath
  forM_ pts $ \pt -> pushPath path pt
  pushPath path (Prelude.head pts)

newPath :: Scene s (Var s [Point 2 R])
newPath = do
    path <- newVar []
    s <- newSprite $ render <$> unVar path
    spriteE s $ overEnding 0.2 fadeOutE
    return path
  where
    render lst = withFillOpacity 0 $ withStrokeColorPixel black $
      withStrokeLineJoin JoinRound $ (strokeLineCap .~ pure CapRound) $
      withStrokeWidth (defaultStrokeWidth*2) $
      mkLinePath
      [ (x,y) | e <- lst, let Point2 x y = realToFrac <$> e ]

pushPath :: Var s [Point 2 R] -> Point 2 R -> Scene s ()
pushPath var pt = do
  oldPath <- readVar var
  if null oldPath
    then writeVar var [pt]
    else tweenVar var 1 $ \_ t ->
            oldPath ++ [lerpPoint (curveS 2 t) pt (Prelude.last oldPath)]

showPoints :: [Point 2 Rational] -> SVG
showPoints pts = mkGroup
  [ ppPoint pt
  | pt <- pts
  ]

seed :: Int
seed = hash "random monotone"

nPoints :: Int
nPoints = 10

ppPoint :: Real r => Point 2 r -> SVG
ppPoint (Point2 x y) =
  withFillColorPixel green $
  withStrokeColorPixel black $
  translate (realToFrac x) (realToFrac y) $
  mkCircle nodeRadius

