{-# LANGUAGE DataKinds #-}
module RandomMonotone (randomMonotoneShowcase ) where

import           Algorithms.Geometry.MonotonePolygon.MonotonePolygon

import           Control.Lens
import           Control.Monad.Random
import           Data.Ext
import           Data.Ratio
import qualified Data.Foldable                                       as F
import           Data.Geometry.Line                                  (Line (..))
import           Data.Geometry.LineSegment
import           Data.Geometry.Point
import           Data.Geometry.Polygon                               as P
import           Data.Geometry.Polygon.Convex
import           Data.Geometry.Transformation
import           Data.Geometry.Vector
import           Data.Hashable
import           Data.Intersection
import qualified Data.List.NonEmpty                                  as NonEmpty
import           Data.Maybe
import qualified Data.Vector.Circular                                as CV
import           Data.Vinyl
import           Data.Vinyl.CoRec
import           Graphics.SvgTree                                    (Cap (..),
                                                                      LineJoin (..),
                                                                      strokeLineCap)
import           Reanimate
import           Reanimate.Animation

import           Common
import           Data.RealNumber.Rational

type R = Rational -- RealNumber 5

{- Animation overview:
* Start with N random points.
* Draw polygon outline.
* Scan through polygon, highlighting intersections.
* Fade out everything except points.
* Interpolate to new random set of points.
-}

randomMonotoneShowcase :: Animation
randomMonotoneShowcase = scene $ do
    forM_ pairs $ \((dir, pl), next) -> do
      play $ randomMonotoneSingle pl dir
      play $ animate (\t ->
        let morph = lerpPolygon t pl next
        in ppVertices (map _core $ toPoints morph))
        & signalA (curveS 2)
  where
    pairs = zip monotonePolygons (drop 1 (map snd (monotonePolygons++[Prelude.head monotonePolygons])))

randomMonotoneSingle :: SimplePolygon () R -> Vector 2 R -> Animation
randomMonotoneSingle p' dir = scene $ do
    adjustZ succ $ newSpriteSVG_ $ ppVertices pts
    path <- newPath
    forM_ pts $ pushPath path
    pushPath path (Prelude.head pts)
    wait 1
    adjustZ succ $ play $
      applyE (overEnding 0.1 fadeOutE) $
      applyE (overBeginning 0.1 fadeInE) $
      pauseAround 0.1 0.1 $
      signalA (curveS 2) $
      setDuration 5 $
      animate $ \t ->
      let atP = lerpPoint t (maxP^.core) (minP^.core) in
      withStrokeColorPixel red $ mkGroup
      [ mkGroup
        [ ppLine atP iPt
        , ppMarker iPt ]
      | iPt <- intersectionsAt p' dir atP ]
  where
    pts = map _core $ toPoints p
    minP = P.minimumBy (cmpExtreme dir) p'
    maxP = P.maximumBy (cmpExtreme dir) p'
    Just p = P.findRotateTo (==minP) p'

intersectionsAt :: SimplePolygon () R -> Vector 2 R -> Point 2 R -> [Point 2 R]
intersectionsAt p direction pt = catMaybes
  [ match (Data.Intersection.intersect edge line) $
           H (\NoIntersection -> Nothing)
        :& H (\pt -> Just pt)
        -- This happens when an edge is parallel with the given direction.
        -- I think it's correct to count it as a single intersection.
        :& H (\LineSegment{} -> Nothing)
        :& RNil
  | edge <- F.toList $ outerBoundaryEdges p ]
  where
    line = Line pt (rot90 direction)
    rot90 (Vector2 x y) = Vector2 (-y) x

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
    else do
      let prev = Prelude.last oldPath
          dist = sqrt $ realToFrac $ squaredEuclideanDist pt prev
      tweenVar var (dist*0.2) $ \_ t ->
        oldPath ++ [lerpPoint t pt prev]

showPoints :: [Point 2 Rational] -> SVG
showPoints pts = mkGroup
  [ ppPoint pt
  | pt <- pts
  ]

seed :: Int
seed = hash "random monotone"

nPoints :: Int
nPoints = 10

nPolygons :: Int
nPolygons = 5

monotonePolygons :: [(Vector 2 R, SimplePolygon () R)]
monotonePolygons = flip evalRand (mkStdGen seed) $
  replicateM nPolygons $ do
    dir <- generateRandomVector2
    p <- randomMonotone nPoints dir
    return (dir, pAtCenter $ scaleUniformlyBy (screenHeight*0.9) p)


generateRandomVector2 :: RandomGen g => Rand g (Vector 2 Rational)
generateRandomVector2 = do
    a <- liftRand $ randomR(-granularity, granularity)
    b <- liftRand $ randomR(-granularity, granularity)
    pure $ Vector2 (a % granularity) (b % granularity)

ppVertices :: Real r => [Point 2 r] -> SVG
ppVertices = mkGroup . map ppPoint

ppPoint :: Real r => Point 2 r -> SVG
ppPoint (Point2 x y) =
  withFillColorPixel green $
  withStrokeColorPixel black $
  translate (realToFrac x) (realToFrac y) $
  mkCircle nodeRadius

ppMarker :: Real r => Point 2 r -> SVG
ppMarker (Point2 x y) =
  withFillColorPixel red $
  translate (realToFrac x) (realToFrac y) $
  mkCircle (nodeRadius*0.25)

