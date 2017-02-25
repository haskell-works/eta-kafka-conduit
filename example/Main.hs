{-# LANGUAGE MagicHash, BangPatterns, FlexibleContexts, DataKinds, TypeFamilies, OverloadedStrings, ScopedTypeVariables #-}
module Main where
--

import Java
import Java.String
import GHC.Base
import Control.Monad.Trans.Resource
import Control.Monad(forM_)
import Data.Conduit
import Data.Bifunctor
import Data.Maybe (maybeToList)
import Data.Monoid ((<>))
import Kafka.Conduit.Source
import Kafka.Conduit.Sink
import Data.Conduit.List as L

consumerConf :: ConsumerProperties
consumerConf = consumerBrokersList [BrokerAddress "localhost:9092"]
            <> groupId (ConsumerGroupId "conduit-test")
            <> offsetReset Earliest
            <> noAutoCommit

producerConf :: ProducerProperties
producerConf = producerBrokersList [BrokerAddress "localhost:9092"]

testTopic  = TopicName "conduit-example-topic"

main :: IO ()
main = do
  print "Running sink..."
  runConduitRes outputStream
  print "Running source..."
  msgs <- runConduitRes $ inputStream .| L.take 3
  forM_ msgs print
  print "Ok."


outputStream =
  L.sourceList ["c-one", "c-two", "c-three"]
  .| L.map (mkProdRecord testTopic)
  .| kafkaSink producerConf

inputStream =
  kafkaSource consumerConf (Millis 1000) [testTopic]
  .| L.concat
  .| L.map (bimap rawString rawString)


mkProdRecord t v =
  let bytes = stringBytes v
   in ProducerRecord t Nothing (Just bytes) (Just bytes)

rawString :: Maybe JByteArray -> Maybe JString
rawString m = bytesToJString <$> m

-- helpers, hopefully will go away with Eta development
stringBytes :: String -> JByteArray
stringBytes s = JByteArray (getBytesUtf8# js)
  where !(JS# js) = toJString s

foreign import java unsafe "@new" bytesToJString :: JByteArray -> JString
