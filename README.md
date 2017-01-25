# Conduit bindings for Kafka
[![CircleCI](https://circleci.com/gh/haskell-works/eta-kafka-conduit.svg?style=svg&circle-token=3ed057833de7fa5d1c2289ba76f088061e85cc26)](https://circleci.com/gh/haskell-works/eta-kafka-conduit)

## Example
An example can be found in the [example](example/Main.hs) project.

### Running the example
Running the example requires Kafka to be available at `localhost`.  

#### Run Kafka inside `docker-compose`
If you already have Kafka accessible at `localhost:9092` skip this section.

```
$ export DOCKER_IP=your_ip_address
$ docker-compose up
```

**Note** `DOCKER_IP` should be a real IP address of your machine, not `127.0.0.1`.
The following script can be used as a helper (MacOS):
```
export DOCKER_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1)
```

#### Execute the example
```
$ epm run

"Running sink..."
"Running source..."
ConsumerRecord {crTopic = TopicName "conduit-example-topic", crPartition = PartitionId 0, crOffset = Offset 0, crChecksum = Checksum 50557688, crKey = Just "c-one", crValue = Just "c-one"}
ConsumerRecord {crTopic = TopicName "conduit-example-topic", crPartition = PartitionId 0, crOffset = Offset 1, crChecksum = Checksum 1248482825, crKey = Just "c-two", crValue = Just "c-two"}
ConsumerRecord {crTopic = TopicName "conduit-example-topic", crPartition = PartitionId 0, crOffset = Offset 2, crChecksum = Checksum 3484821948, crKey = Just "c-three", crValue = Just "c-three"}
"Ok."
```
