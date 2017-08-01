{-# LANGUAGE OverloadedStrings #-}
module Main where
--

import           Control.Monad                (forM_)
import           Control.Monad.IO.Class
import           Control.Monad.Trans.Resource
import           Data.Bifunctor
import           Data.ByteString              as BS
import           Data.Conduit
import           Data.Conduit.List            as L
import           Data.Maybe                   (maybeToList)
import           Data.Monoid                  ((<>))
import           GHC.Base
import           Kafka.Conduit.Sink
import           Kafka.Conduit.Source

consumerConf :: ConsumerProperties
consumerConf = consumerBrokersList [BrokerAddress "localhost:9092"]
            <> groupId (ConsumerGroupId "conduit-test")
            <> offsetReset Earliest
            <> noAutoCommit

producerConf :: ProducerProperties
producerConf = producerBrokersList [BrokerAddress "localhost:9092"]

testTopic :: TopicName
testTopic  = TopicName "conduit-example-topic"

main :: IO ()
main = do
  print "Producing messages..."
  runConduitRes $ outputStream producerConf testTopic
  print "Consuming messages..."
  msgs <- runConduitRes $ inputStream consumerConf testTopic .| L.take 3
  forM_ msgs print
  print "Ok."


outputStream :: (MonadIO m, MonadResource m)
             => ProducerProperties -> TopicName -> Sink a m ()
outputStream props topic =
  L.sourceList ["c-one", "c-two", "c-three"]
  .| L.map (mkProdRecord topic)
  .| kafkaSink props

inputStream :: (MonadIO m, MonadResource m)
            => ConsumerProperties
            -> TopicName
            -> Source m (ConsumerRecord (Maybe ByteString) (Maybe ByteString))
inputStream props topic =
  kafkaSource props (Millis 1000) [topic]
  .| L.concat

mkProdRecord :: TopicName -> ByteString -> ProducerRecord
mkProdRecord t v = ProducerRecord t Nothing (Just v) (Just v)
