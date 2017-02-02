module Kafka.Conduit.Sink
( module X
, kafkaSink
, JFuture, JRecordMetadata
) where

import Java
import Data.Conduit

import Control.Monad.IO.Class
import Control.Monad (void)
import Control.Monad.Trans.Resource

import Kafka.Types as X
import Kafka.Producer as X
import Kafka.Producer.Types as X
import Kafka.Producer.ProducerProperties as X

kafkaSink :: MonadResource m => ProducerProperties -> Sink (ProducerRecord JByteArray JByteArray) m ()
kafkaSink props =
  bracketP (newProducer props) closeProducer go
  where
    go prod = awaitForever (send prod)
