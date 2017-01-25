module Kafka.Conduit.Source
( module X
, kafkaSource
) where

import Java
import Data.Conduit
import Kafka.Consumer (ConsumerProperties, KafkaConsumer, Timeout, TopicName, ConsumerRecord)
import qualified Kafka.Consumer as KC

import Control.Monad.IO.Class
import Control.Monad (void)
import Control.Monad.Trans.Resource

import Kafka.Types as X
import Kafka.Consumer.Types as X
import Kafka.Consumer.ConsumerProperties as X

newConsumer :: MonadIO m => ConsumerProperties -> m (KafkaConsumer JByteArray JByteArray)
newConsumer props = liftIO . java $ KC.newConsumer props

closeConsumer :: MonadIO m => KafkaConsumer k v -> m ()
closeConsumer c = liftIO . java $ c <.> KC.closeConsumer

poll :: MonadIO m => KafkaConsumer JByteArray JByteArray -> Timeout -> m [ConsumerRecord (Maybe JByteArray) (Maybe JByteArray)]
poll c t = liftIO . java $ c <.> KC.poll t

subscribe :: MonadIO m => KafkaConsumer JByteArray JByteArray -> [TopicName] -> m ()
subscribe c ts = liftIO . java $ c <.> KC.subscribeTo ts

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
      subscribe cons ts
      return cons

    clConsumer = closeConsumer

    runHandler cons = do
      batch <- poll cons tm
      yield batch
      runHandler cons
