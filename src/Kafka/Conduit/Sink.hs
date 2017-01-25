module Kafka.Conduit.Sink
( module X
, kafkaSink
, JFuture, JRecordMetadata
) where

import Java
import Data.Conduit
import Kafka.Producer (KafkaProducer, JFuture, JRecordMetadata)
import qualified Kafka.Producer as KP

import Control.Monad.IO.Class
import Control.Monad (void)
import Control.Monad.Trans.Resource

import Kafka.Types as X
import Kafka.Producer.Types as X
import Kafka.Producer.ProducerProperties as X

newProducer :: MonadIO m => ProducerProperties -> m (KafkaProducer JByteArray JByteArray)
newProducer props = liftIO . java $ KP.newProducer props

closeProducer :: MonadIO m => KafkaProducer k v -> m ()
closeProducer c = liftIO . java $ c <.> KP.closeProducer

send :: MonadIO m => KafkaProducer JByteArray JByteArray -> ProducerRecord JByteArray JByteArray -> m (JFuture JRecordMetadata)
send p r = liftIO . java $ p <.> KP.send r

kafkaSink :: MonadResource m => ProducerProperties -> Sink (ProducerRecord JByteArray JByteArray) m ()
kafkaSink props =
  bracketP mkProducer clProduder runHandler
  where
    mkProducer = newProducer props
    clProduder = closeProducer

    runHandler prod = do
      awaitForever $ \rec -> do
        res <- send prod rec
        return res
