module Kafka.Conduit.Sink
( module X
, kafkaSink
, JFuture, JRecordMetadata
) where

import           Data.Conduit
import           Java

import           Control.Monad                     (void)
import           Control.Monad.IO.Class
import           Control.Monad.Trans.Resource

import           Kafka.Producer                    as X
import           Kafka.Producer.ProducerProperties as X
import           Kafka.Producer.Types              as X
import           Kafka.Types                       as X

kafkaSink :: MonadResource m => ProducerProperties -> Sink ProducerRecord m ()
kafkaSink props =
  bracketP (newProducer props) closeProducer go
  where
    go prod = awaitForever (send prod)
