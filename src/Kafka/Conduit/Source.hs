module Kafka.Conduit.Source
( module X
, kafkaSource
) where

import Java
import Data.Conduit
import Data.Bifunctor
import Data.Bitraversable

import Control.Monad.IO.Class
import Control.Monad (void)
import Control.Monad.Trans.Resource
import qualified Data.Conduit.List as L

import Kafka.Types as X
import Kafka.Consumer as X
import Kafka.Consumer.Types as X
import Kafka.Consumer.ConsumerProperties as X

kafkaSource :: (MonadResource m)
            => ConsumerProperties
            -> Millis
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
                   -> Millis
                   -> Source m [ConsumerRecord (Maybe JByteArray) (Maybe JByteArray)]
kafkaSourceNoClose kc tm = go
  where
    go = (poll kc tm >>= yield) >> go

kafkaSourceAutoClose :: MonadResource m
                     => KafkaConsumer
                     -> Millis
                     -> Source m [ConsumerRecord (Maybe JByteArray) (Maybe JByteArray)]
kafkaSourceAutoClose kc tm =
  bracketP (return kc) closeConsumer go
  where
    go kc' = (poll kc' tm >>= yield) >> go kc'

------------------------------- Utitlity functions

-- | Maps over the first element of a value
--
-- > mapFirst f = L.map (first f)
mapFirst :: (Bifunctor t, Monad m) => (k -> k') -> Conduit (t k v) m (t k' v)
mapFirst f = L.map (first f)
{-# INLINE mapFirst #-}

-- | Maps over a value
--
-- > mapValue f = L.map (fmap f)
mapValue :: (Functor t, Monad m) => (v -> v') -> Conduit (t v) m (t v')
mapValue f = L.map (fmap f)
{-# INLINE mapValue #-}

-- | Bimaps (maps over both the first and the second element) over a value
--
-- > bimapValue f g = L.map (bimap f g)
bimapValue :: (Bifunctor t, Monad m) => (k -> k') -> (v -> v') -> Conduit (t k v) m (t k' v')
bimapValue f g = L.map (bimap f g)
{-# INLINE bimapValue #-}

-- | Sequences the first element of a value
--
-- > sequenceValueFirst = L.map sequenceFirst
sequenceValueFirst :: (Bitraversable t, Applicative f, Monad m) => Conduit (t (f k) v) m (f (t k v))
sequenceValueFirst = L.map sequenceFirst
{-# INLINE sequenceValueFirst #-}

-- | Sequences the value
--
-- > sequenceValue = L.map sequenceA
sequenceValue :: (Traversable t, Applicative f, Monad m) => Conduit (t (f v)) m (f (t v))
sequenceValue = L.map sequenceA
{-# INLINE sequenceValue #-}

-- | Sequences both the first and the second element of a value (bisequences the value)
--
-- > bisequenceValue = L.map bisequenceA
bisequenceValue :: (Bitraversable t, Applicative f, Monad m) => Conduit (t (f k) (f v)) m (f (t k v))
bisequenceValue = L.map bisequenceA
{-# INLINE bisequenceValue #-}

-- | Traverses over the first element of a value
--
-- > traverseValueFirst f = L.map (traverseFirst f)
traverseValueFirst :: (Bitraversable t, Applicative f, Monad m) => (k -> f k') -> Conduit (t k v) m (f (t k' v))
traverseValueFirst f = L.map (traverseFirst f)
{-# INLINE traverseValueFirst #-}

-- | Traverses over the value
--
-- > L.map (traverse f)
traverseValue :: (Traversable t, Applicative f, Monad m) => (v -> f v') -> Conduit (t v) m (f (t v'))
traverseValue f = L.map (traverse f)
{-# INLINE traverseValue #-}

-- | Traverses over both the first and the second elements of a value (bitraverses over a value)
--
-- > bitraverseValue f g = L.map (bitraverse f g)
bitraverseValue :: (Bitraversable t, Applicative f, Monad m) => (k -> f k') -> (v -> f v') -> Conduit (t k v) m (f (t k' v'))
bitraverseValue f g = L.map (bitraverse f g)
{-# INLINE bitraverseValue #-}

-- | Monadically traverses over the first element of a value
--
-- > traverseValueFirstM f = L.mapM (traverseFirstM f)
traverseValueFirstM :: (Bitraversable t, Applicative f, Monad m) => (k -> m (f k')) -> Conduit (t k v) m (f (t k' v))
traverseValueFirstM f = L.mapM (traverseFirstM f)
{-# INLINE traverseValueFirstM #-}

-- | Monadically traverses over a value
--
-- > traverseValueM f = L.mapM (traverseM f)
traverseValueM :: (Traversable t, Applicative f, Monad m) => (v -> m (f v')) -> Conduit (t v) m (f (t v'))
traverseValueM f = L.mapM (traverseM f)
{-# INLINE traverseValueM #-}

-- | Monadically traverses over both the first and the second elements of a value
-- (monadically bitraverses over a value)
--
-- > bitraverseValueM f g = L.mapM (bitraverseM f g)
bitraverseValueM :: (Bitraversable t, Applicative f, Monad m) => (k -> m (f k')) -> (v -> m (f v')) -> Conduit (t k v) m (f (t k' v'))
bitraverseValueM f g = L.mapM (bitraverseM f g)
{-# INLINE bitraverseValueM #-}

--------------------------------------------------------------------------------
