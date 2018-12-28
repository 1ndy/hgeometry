module Main where

import Data.Monoid
import Control.Applicative
import Options.Applicative
import Data.Data

--------------------------------------------------------------------------------

import qualified Demo.DrawGPX as DrawGPX
import qualified Demo.WriteEnsemble as EnsembleWriter
import qualified Demo.MinDisk as MinDisk
import qualified Demo.Delaunay as Delaunay
import qualified Demo.ExpectedPairwiseDistance as ExpPWD
import qualified Demo.TriangulateWorld as TriangulateWorld
import qualified Demo.IpeToSvg as IpeToSvg




--------------------------------------------------------------------------------

data Options = BAPC                      BAPCOptions
             | DrawGPX                   DrawGPX.Options
             | EnsembleWriter            EnsembleWriter.Options
             | MinDisk                   MinDisk.Options
             | Delaunay                  Delaunay.Options
             | ExpectedPairwiseDistance  ExpPWD.Options
             | TriangulateWorld          TriangulateWorld.Options
             | IpeToSvg                  IpeToSvg.Options
             deriving Data

parser :: Parser Options
parser = subparser (
       command' DrawGPX                        DrawGPX.options
    <> command' EnsembleWriter                 EnsembleWriter.options
    <> command' MinDisk                        MinDisk.options
    <> command' Delaunay                       Delaunay.options
    <> command' ExpectedPairwiseDistance       ExpPWD.options
    <> command' TriangulateWorld               TriangulateWorld.options
    <> command' IpeToSvg                       IpeToSvg.options
    )


mainWith       :: Options -> IO ()
mainWith opts' = case opts' of
  BAPC _                              -> putStrLn "not yet"
  DrawGPX opts                        -> DrawGPX.mainWith opts
  EnsembleWriter opts                 -> EnsembleWriter.mainWith opts
  MinDisk opts                        -> MinDisk.mainWith opts
  Delaunay opts                       -> Delaunay.mainWith opts
  ExpectedPairwiseDistance opts       -> ExpPWD.mainWith opts
  TriangulateWorld opts               -> TriangulateWorld.mainWith opts
  IpeToSvg opts                       -> IpeToSvg.mainWith opts

--------------------------------------------------------------------------------

options :: ParserInfo Options
options = info (helper <*> parser)
               (  progDesc "Example programs for HGeometry. Use -h to get a list of programs."
               <> header   "hgeometry-examples - Examples for HGeometry"
               )

--------------------------------------------------------------------------------

main :: IO ()
main = execParser options >>= mainWith


command'          :: Data o => (a -> o) -> ParserInfo a -> Mod CommandFields o
command' constr p = command (show . toConstr $ constr undefined) (constr <$> p)


noOpts :: InfoMod () -> ParserInfo ()
noOpts = info (pure ())







data BAPCOptions = BAPCOptions { year :: Int
                               }
                   deriving Data
