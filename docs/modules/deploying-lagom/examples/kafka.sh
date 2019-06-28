
if [ $INSTALL_KAFKA_REQUIRES_ADMIN == 1 ]
then
# tag::login-sysadmin[]

oc login -u system:admin

# end::login-sysadmin[]
fi

if [ $INSTALL_STRIMZI == 1 ]
then
    echo Installing Strimzi...

# tag::install-strimzi[]
helm install lightbend/strimzi-kafka-operator \
  --name my-strimzi \
  --namespace $NAMESPACE \
  --version 0.8.2 \
  --debug
# end::install-strimzi[]
fi

if [ $INSTALL_KAFKA == 1 ]
then
    echo Installing Kafka...
    if [ $KAFKA_NODES == 1 ]
    then
# tag::install-kafka-single[]
oc apply -f deploy/kafka-single.yaml -n $NAMESPACE
# end::install-kafka-single[]
    elif [ $KAFKA_NODES == 3 ]
    then
# tag::install-kafka-multi[]
oc apply -f deploy/kafka.yaml -n $NAMESPACE
# end::install-kafka-multi[]
    else
        echo "Kafka nodes must either be 1 or 3"
        exit 1
    fi

    waitForApp strimzi.io/name=strimzi-kafka $KAFKA_NODES 2
fi

if [ $INSTALL_KAFKA_REQUIRES_ADMIN == 1 ]
then
# tag::login-developer[]
oc login -u developer
# end::login-developer[]
fi
