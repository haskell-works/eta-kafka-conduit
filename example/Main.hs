{-# LANGUAGE MagicHash, BangPatterns, FlexibleContexts, DataKinds, TypeFamilies, OverloadedStrings, ScopedTypeVariables #-}
module Main where
--

import Java
import Control.Monad.Trans.Resource
import Control.Monad(forM_)
import Data.Conduit
import Data.Maybe (maybeToList)
import Data.Monoid ((<>))
import Kafka.Conduit.Source
import Data.Conduit.List as L

consumerConf :: ConsumerProperties
consumerConf = consumerBrokersList [BrokerAddress "localhost:9092"]
            <> groupId (ConsumerGroupId "test-group-1")
            <> offsetReset Earliest
            <> noAutoCommit

testTopic  = TopicName "kafka-example-topic"

main :: IO ()
main = do
  msgs <- runResourceT $ runConduit $ kafkaSource consumerConf (Timeout 1000) [testTopic] .| L.take 1
  let received = msgs >>= id >>= maybeToList . crValue
  forM_ received (print . bytesToJString)
  print "Ok."

foreign import java unsafe "@new" bytesToJString :: JByteArray -> JString
