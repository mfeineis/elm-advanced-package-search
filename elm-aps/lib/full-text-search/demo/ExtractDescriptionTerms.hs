
module ExtractDescriptionTerms (
    extractSynopsisTerms,
    extractDescriptionTerms
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Char
import qualified NLP.Tokenize as NLP
import qualified NLP.Snowball as NLP
import Control.Monad ((>=>))
import Data.Maybe

import HaddockTypes as Haddock
import HaddockHtml  as Haddock (markup)
import qualified HaddockParse as Haddock (parseHaddockParagraphs)
import qualified HaddockLex   as Haddock (tokenise)


extractSynopsisTerms :: Set Text -> String -> [Text]
extractSynopsisTerms stopWords =
      NLP.stems NLP.English
    . filter (`Set.notMember` stopWords)
    . map (T.toCaseFold . T.pack)
    . concatMap splitTok
    . filter (not . ignoreTok)
    . NLP.tokenize


ignoreTok :: String -> Bool  
ignoreTok = all isPunctuation

splitTok :: String -> [String]
splitTok tok =
    case go tok of
      toks@(_:_:_) -> tok:toks
      toks         -> toks
  where
    go remaining =
      case break (\c -> c == ')' || c == '-' || c == '/') remaining of
        ([],      _:trailing) -> go trailing
        (leading, _:trailing) -> leading : go trailing
        ([],      [])         -> []
        (leading, [])         -> leading : []


extractDescriptionTerms :: Set Text -> String -> [Text]
extractDescriptionTerms stopWords =
      NLP.stems NLP.English
    . filter (`Set.notMember` stopWords)
    . map (T.toCaseFold . T.pack)
    . maybe
        [] --TODO: something here
        (  filter (not . ignoreTok)
         . NLP.tokenize
         . concat . Haddock.markup termsMarkup)
    . (Haddock.tokenise >=> Haddock.parseHaddockParagraphs)

termsMarkup :: DocMarkup String [String]
termsMarkup = Markup {
  markupEmpty         = [],
  markupString        = \s -> [s],
  markupParagraph     = id,
  markupAppend        = (++),
  markupIdentifier    = \s -> [s],
  markupModule        = const [], -- i.e. filter these out
  markupEmphasis      = id,
  markupMonospaced    = \s -> if length s > 1 then [] else s,
  markupUnorderedList = concat,
  markupOrderedList   = concat,
  markupDefList       = concatMap (\(d,t) -> d ++ t),
  markupCodeBlock     = const [],
  markupHyperlink     = \(Hyperlink _url mLabel) -> maybeToList mLabel,
                        --TODO: extract main part of hostname
  markupPic           = const [],
  markupAName         = const []
  }

{-
-------------------
-- Main experiment
--

main = do
    pkgsFile <- readFile "pkgs"
    let mostFreq :: [String]
        pkgs     :: [PackageDescription]
        (mostFreq, pkgs) = read pkgsFile
    
    stopWordsFile <- T.readFile "stopwords.txt"
--    wordsFile <- T.readFile "/usr/share/dict/words"
--    let ws = Set.fromList (map T.toLower $ T.lines wordsFile)


    print "reading file"
    evaluate (length mostFreq + length pkgs)
    print "done"

    let stopWords = Set.fromList $ T.lines stopWordsFile
    print stopWords

    sequence_
      [ putStrLn $ display (packageName pkg) ++ ": "
                ++ --intercalate ", "
                   (description pkg) ++ "\n" 
                ++ intercalate ", "
                   (map T.unpack $ extractDescriptionTerms stopWords (description pkg)) ++ "\n"
      | pkg <- pkgs
      , let pkgname = display (packageName pkg) ]
-}
