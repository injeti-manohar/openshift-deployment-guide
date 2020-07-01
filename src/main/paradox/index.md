# Deploying Lagom applications to Kubernetes 

This guide describes how to deploy Lagom applications to Kubernetes. In future, we hope to expand the scope of this guide to include Akka and Play applications, in the meantime, much of this guide will be applicable to Akka and Play, but will need to be adapted.

It is intended to be used by people who have a cursory understanding of  Kubernetes - you should know what Kubernetes is, have a basic understanding of what a pods, services and containers are, and you should have interacted with the `kubectl` command before. You are not however expected to be an expert.

## Following this guide

There are multiple different configurations that this guide documents, such as, using Scala and using Java, using Maven and using sbt, using Kafka and using a relational database. It is up to you to follow the parts that are relevant to you, and skip over the parts that are not. The sample application that is referenced by this guide is offered using either Scala or Java, either Maven or sbt, and uses Postgres and Kafka.

There are two ways to use this guide. The first is to follow along using the sample applications that we have provided. This is great if you are evaluating the technologies, or just want to get a feel for deployment to production before you deploy your own apps. The second is to follow along with your own application, applying the steps we document to your application. Careful attention will need to be paid to ensuring that all config, in particular, names, get updated to match your application.

Ideally, you should follow along using a realistic Kubernetes cluster, something deployed to AWS, GCP or Azure for example, as this will provide a more realistic demonstration of the technologies, allowing you to see many services running across a cluster. 
However, due to the hosting cost of running such a cluster, this may not always be feasible, and perhaps you are just evaluating these technologies with no budget for hosting them yet. 
In that case, you can follow this guide using [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) or [Minishift](https://www.okd.io/minishift/), running on your local machine. 
Running this guide in Minikube has some significant limitations, primarily around resources such as memory and CPU. In some cases, you will have to deploy things with only one replica, when in production you should really use at least three. 
And often you will have to assign only small fractions of CPU resources to an application, especially if you are running many, and this will make the application very slow to start up.

## Installing Kubernetes

We will not actually document installing Kubernetes, OpenShift, Minishift, or Minikube in this guide, since there are already resources on the web for doing this. 

### Installing Minikube

Minikube can be installed following [these instructions](https://kubernetes.io/docs/tasks/tools/install-minikube/).

Once installed you can start minikube:

```
minikube start
```

Once Minikube is started you can setup your Docker environment to publish to minikube:

```
eval $(minikube -p minikube docker-env)
```

### Installing Minishift

Minishift can be installed following [these instructions](https://docs.okd.io/latest/minishift/getting-started/installing.html).

Before starting Minishift, we recommend you configure it to allow it more RAM, and potentially more CPU (by default, it gets 2GB of RAM and 2 CPUs). If you use Minishift for other purposes, you may want to create a custom profile so that you don't interfere with these, a profile called `lightbend` can be created and switched to by running:

```
minishift profile set lightbend
```

Now you can configure how much RAM should be allocated to Minishift, let's allocate it 6GB:

```
minishift config set memory 6GB
```

The memory can also be set by passing an argument when you start Minishift, but doing it this way, you ensure that whenever you delete and restart your Minishift instance, the config is remembered.

Now you can start Minishift:

```
minishift start
```

Once Minishift is started, you need to ensure that the `oc` binary is on your path, and that your environment is configured to use the Minishift VMS docker host. To do this, run:

```
eval $(minishift oc-env)
eval $(minishift docker-env)
```

The first command modifies your `PATH` to ensure the `oc` binary is on it, the second sets some `DOCKER_*` environment variables to tell Docker which host to use and how to authenticate with it when building images. Since these commands just modify environment variables in your current shell session, they will need to be rerun every time you open a new terminal window, or any time you delete and then restart your Minishift instance.

## Guides

@@@ index

* [Deploying a Lagom application to Kubernetes](lagom/index.md)

@@@

@@toc { depth=1 }
