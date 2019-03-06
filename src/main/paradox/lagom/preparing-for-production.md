# Preparing for production

In preparation for production, we need to do two main things:

1. Configure our Lagom app for the production environment
2. Write a deployment spec for deploying it to OpenShift

Rather than describe these two steps completely and in sequence, this guide will take you through more incrementally, jumping back and forth between the Lagom configuration file and the deployment spec. The reason for this is that the production configuration of Lagom and the deployment spec are tightly coupled, things in Lagom's configuration file typically correspond to something configured in the deployment spec. To understand these configuration options and their coupling, it's best to do one and then the other.

If you look at the sample app, you'll see the configuration file and deployment spec in their final form. In this guide, we'll show just snippets. You may like to follow along by deleting these files and starting from scratch, though note if you do this, you will need to understand how a Kubernetes deployment spec is structured, for example, if the guide shows the configuration for an environment variable, you'll need to know where in the spec this needs to go. You may like to keep the final deployment spec handy to be able to refer to it to see where different configuration belongs.

In this guide, we'll just describe how to deploy the `shopping-cart` service. The `inventory` service is trivial, it doesn't talk to a database, it doesn't do any clustering, and everything it needs is a subset of what the `shopping-cart` service needs. You can refer to the sample app to see how it is configured.

## Setup

To start, we will create a production configuration file and barebones deployment spec. Let's start by creating the production configuration file. In `shopping-cart/src/main/resources`, create a new file called `prod-application.conf`, with the following contents:

```conf
include "application"

play {
  server {
    pidfile.path = "/dev/null"
  }
}
```

The first thing this file does is include the main `application.conf` file. Any subsequent configuration will override the configuration from `application.conf`. This pattern allows us to keep our main, non environment specific configuration in `application.conf`, while putting production specific configuration in a separate place.

Setting `play.server.pidfile.path = /dev/null` [disables](https://www.playframework.com/documentation/2.7.x/ProductionConfiguration#Changing-the-path-of-RUNNING_PID) the use of a `pidFile`. A `pidFile` is not necessary for a process running on a container.

Now, let's define an initial, incomplete deployment spec. We'll do this in a file called `deploy/shopping-cart.yaml`:

```yaml
apiVersion: "apps/v1"
kind: Deployment
metadata:
  name: shopping-cart
spec:
  selector:
    matchLabels:
      app: shopping-cart

  template:
    metadata:
      labels:
        app: shopping-cart
    spec:
      containers:
        - name: shopping-cart
          image: "shopping-cart:latest"
          env:
            - name: JAVA_OPTS
              value: "-Xms256m -Xmx256m -Dconfig.resource=prod-application.conf"
          resources:
            limits:
              memory: 512Mi
            requests:
              cpu: 0.25
              memory: 512Mi
---
apiVersion: v1
kind: Service
metadata:
  name: shopping-cart
spec:
  ports:
    - name: http
      port: 80
      targetPort: 9000
  selector:
    app: shopping-cart
  type: LoadBalancer
```

Here are a few things to note:

* We're using a Kubernetes deployment. Deployments are logical groupings of pods that represent a single service using the same template. They support [configurable rolling updates](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/#deploymentstrategy-v1-apps), meaning that the cluster will be gradually upgraded, rather than upgrading every node at once and incurring an outage.
* We label the pod in the `template` with `app: shopping-cart`. This must match the the deployments `matchLabels` and also the services `selector`, so that the deployment knows which pods it owns and should maintain and upgrade, and so the service knows which pods to include in its service resolution.
* The image we're using is `shopping-cart:latest`. This corresponds to the name and version of the service in our build. We will discuss how to select an appropriate version number below.
* We use the `JAVA_OPTS` environment variable to pass the configuration to tell Lagom to use the `prod-application.conf` configuration file, rather than the default `application.conf`.
* We've configured a maximum of 256mb of memory for the JVM heap size, while the pod gets 512mb. The reason the pod gets more than the JVM heap size is that the JVM doesn't only consume memory for its heap. The JVM will consume other memory, for class file metadata, thread stacks, compiled code, and JVM specific libraries. To accommodate this we need to give at least an additional 256mb of memory to the pod.
* We've only requested very minimal CPU to the pods for this service. This is suitable for a local deployment, but you may wish to increase it if you're deploying to a real deployment. Note that we also haven't set a CPU limit, this is because it's [recommended that JVMs do not set a CPU limit](https://doc.akka.io/docs/akka/2.5/additional/deploy.html#resource-limits).
* The service exposes HTTP on port 80, and directs it to port 9000 on the pods. Port 9000 is Lagom's default HTTP port.

## Image version number

In the above spec, we use a version tag of `latest` for the image. An important thing to understand about the `latest` tag is that there is nothing special about it, it does not automatically refer to the latest deployed version of an image, it simply is the default tag that is used when no tag is specified. We could have just say `shopping-cart`, and this would mean the same thing as `shopping-cart:latest`.

For production, the use of the `latest` tag is considered bad practice. For development, it's convenient and usually fine. We recommend if you're deploying to production, that you replace this with an actual version number, one that gets updated each time you deploy. In the @ref[Building your application](building.md) section of this guide we will describe how to configure your build to base its version number off the current git commit hash, which is great especially for continuous deployment scenarios as it means a human doesn't need to be involved in selecting a unique version number. After building the image, you can take the version number generated in that step and update the image referenced in the spec accordingly.

## Application secret

Play Framework requires a secret key which is used to sign its session cookie, a JSON Web Token. While generally, Lagom applications don't use this, it's a good idea to configure it properly anyway. To do this, we'll generate a secret, store it in the Kubernetes Secret API, and then update our configuration and spec to consume it.

First, generate the secret:

@@snip[perparing.sh](scripts/preparing.sh) { #create-application-secret }

Note, this uses OpenSSL to generate the secret, you can replace that with any secret generation mechanism you want.

Next, add the following configuration to your `prod-application.conf` to consume the secret via an environment variable:

```conf
play {
  http.secret.key = "${APPLICATION_SECRET}"
}
```

Now add the environment variable to your deployment spec, configuring it to read the secret from Kubernetes:

```yaml
- name: APPLICATION_SECRET
  valueFrom:
    secretKeyRef:
        name: shopping-cart-application-secret
        key: secret
```

## Connecting to Postgres

In @ref:[Deploying Postgres](deploying-postgres.md) we deployed a Postgres server, created a database, username and password, and put the password in the Kubernetes secrets API. Now we need to configure our application to connect and consume the secret.

In `prod-application.conf`, add the following configuration:

```conf
db.default {
    url = ${POSTGRESQL_URL}
    username = ${POSTGRESQL_USERNAME}
    password = ${POSTGRESQL_PASSWORD}
}

lagom.persistence.jdbc.create-tables.auto = false
```

This will override the defaults defined for development in `application.conf`. You can see that we've disabled the automatic creating of tables, since we've already created them. We're also expecting three environment variables, the URL, username, and password. The first we'll hard code into the spec, and the second two we'll consume as secrets:

```yaml
- name: POSTGRESQL_URL
  value: "jdbc:postgresql://postgresql/shopping_cart"
- name: POSTGRESQL_USERNAME
  valueFrom:
    secretKeyRef:
        name: postgres-shopping-cart
        key: username
- name: POSTGRESQL_PASSWORD
  valueFrom:
    secretKeyRef:
        name: postgres-shopping-cart
        key: password
```

If you used a different name for the Postgres database deployment, or for the Kubernetes secrets, you'll need to update the spec accordingly.

## Connecting to Kafka

In @ref:[Deploying Kafka](deploying-kafka.md), we deployed a Kafka instance, which we called `strimzi`. To connect to it, we simply need to pass the URL the service name for it to the Lagom application.

Lagom will automatically read an environment variable called `KAFKA_SERVICE_NAME` if present, so there's nothing to configure in our configuration file, we just need to update the spec to pass that environment variable, pointing to the Kafka service we provisioned. The actual service name that we need to configure needs to match the SRV lookup for the Kafka broker - our Kafka broker defines a TCP port called `clients`, to lookup the IP address or host name and port number for this, we need to use a service name of `_clients._tcp.strimzi-kafka-brokers`:

```yaml
- name: KAFKA_SERVICE_NAME
  value: "_clients._tcp.strimzi-kafka-brokers"
```

## Configuring the service locator

Lagom uses a service locator to look up other services. The service locators responsibility is to take the service name defined in a Lagom service descriptor, and translate it into an address to use when communicating with the service. In development (that is, when you run `runAll`), Lagom starts up its own development service locator, and injects that into each service, which means as a developer you don't have to worry about this aspect of deployment until you move outside the Lagom development environment. When you do that, you need to provide a service locator yourself.

Akka provides an API called [Akka Discovery](https://doc.akka.io/docs/akka/current/discovery/index.html), with a number of backends, including multiple that are compatible with a Kubernetes environment. We're going to use a service locator implementation built on Akka Discovery, and then we're going to use the DNS implementation of Akka discovery to discover other services.

### Dependencies

First we need to add the Lagom Akka Discovery dependency to our project:

Java with Maven
: @@@vars
```xml
<dependency>
  <groupId>com.lightbend.lagom</groupId>
  <artifactId>lagom-javadsl-akka-discovery-service-locator_2.12</artifactId>
  <version>$lagom.akka.discovery.version$</version>
</dependency>
```
@@@

Java with sbt
: @@@vars
```scala
libraryDependencies += 
  "com.lightbend.lagom" %% "lagom-javadsl-akka-discovery-service-locator" % "$lagom.akka.discovery.version$"
```
@@@

Scala with sbt
: @@@vars
```scala
libraryDependencies += 
  "com.lightbend.lagom" %% "lagom-scaladsl-akka-discovery-service-locator" % "$lagom.akka.discovery.version$"
```
@@@

### Configuration

Now let's configure Akka discovery to use DNS as the discovery method, by adding the following to `prod-application.conf`:

```
akka.discovery.method = akka-dns
```

### Binding

If you're using Java with Lagom's Guice backend, then nothing more needs to be done, The `lagom-javadsl-akka-discovery` module provides a Guice module that is automatically loaded, which provides the service locator implementation.

If however you're using Scala, you will need to wire in the service locator yourself. To do this, modify your production application cake to mix the Akka discovery service locator components in, by opening `com/example/shoppingcart/impl/ShoppingCartLoader.scala` in `shopping-cart/src/main/scala`, and modifying the `load` method:

```scala
import com.lightbend.lagom.scaladsl.akkadiscovery.AkkaDiscoveryComponents

override def load(context: LagomApplicationContext): LagomApplication =
    new ShoppingCartApplication(context) with AkkaDiscoveryComponents
```

@@@ index

* [Forming an Akka cluster](forming-a-cluster.md)

@@@

