module Kafka.Conduit.Source
( module X
, kafkaSource
) where

import Java
import Data.Conduit
import Kafka.Consumer

import Control.Monad.IO.Class
import Control.Monad (void)
import Control.Monad.Trans.Resource

import Kafka.Types as X
import Kafka.Consumer.Types as X
import Kafka.Consumer.ConsumerProperties as X

kafkaSource :: (MonadResource m)
            => ConsumerProperties
            -> Timeout
            -> [TopicName]
            -> Source m [ConsumerRecord (Maybe JByteArray) (Maybe JByteArray)]
kafkaSource props tm ts =
  bracketP mkConsumer clConsumer runHandler
  where
    mkConsumer = do
      cons <- newConsumer props
      subscribeTo cons ts
      return cons

    clConsumer = closeConsumer

    runHandler cons = do
      batch <- poll cons tm
      yield batch
      runHandler cons

kafkaSourceNoClose :: MonadIO m
                   => KafkaConsumer
                   -> Timeout
                   -> Source m [ConsumerRecord (Maybe JByteArray) (Maybe JByteArray)]
kafkaSourceNoClose kc tm = go
  where
    go = (poll kc tm >>= yield) >> go

kafkaSourceAutoClose :: MonadResource m
                     => KafkaConsumer
                     -> Timeout
                     -> Source m [ConsumerRecord (Maybe JByteArray) (Maybe JByteArray)]
kafkaSourceAutoClose kc tm =
  bracketP (return kc) closeConsumer go
  where
    go kc' = (poll kc' tm >>= yield) >> go kc'
