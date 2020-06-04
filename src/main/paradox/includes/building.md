## Shared docker docs

<!--- #intro --->
There are multiple ways to deploy docker images to Kubernetes. You may decide to deploy your images to an external docker registry, 
such as one that your organisation has set up, or even to a public registry. 

Docker registries have a convention for tags that is typically used to enforce permissions, that is, a Docker tag should have the format of 
`<repository-url>/<username>/<image>:<version>`. 

For convenience, we'll refer to the `repository-url` using the environment variable `DOCKER_REPO_URL`, so if you set that in your shell like so:

```sh
DOCKER_REPO_URL=docker-registry-default.example.com
```

Then you will be able to copy and paste commands from this guide.

## A node on using Minikube

Images can be published directly to the Minikube VMs docker host. This is done by running `eval $(minikube docker-env)`,
which sets up a number of environment variables so that the `docker` command will use that instead of the docker host on your host machine.

If you've built your image directly in the Minikube VMs docker host, then technically, you don't need to push to a Docker registry, since the images are already in the Minikube VMs docker host ready to be run. 
However, if your deployment spec has an `imagePullPolicy` of `Always`, as is the default when using the `latest` tag, then regardless of whether the image is there or not, 
Kubernetes will first attempt to pull the image, and this will fail if you haven't pushed it to any registry that it can see yet. 
For this reason, if using Minkube, you can still do the push step into your Docker registry, this has the advantage of being able to run the guide in a more realistic setup.
Otherwise, set `imagePullPolicy` to 'Never' to make Kubernetes only use the locally published image.

## A note on using Minishift

In addition to providing OpenShifts internal registry, Minishift makes it straight forward to build images directly into the Minishift VMs docker host. This is done by running `eval $(minishift docker-env)`, 
which sets up a number of environment variables so that the `docker` command will use that instead of the docker host on your host machine.

If you've built your image directly in the Minishift VMs docker host, then technically, you don't need to push to the OpenShift registry, since the images are already in the Minishift VMs docker host ready to be run. However, if your deployment spec has an `imagePullPolicy` of `Always`, as is the default when using the `latest` tag, then regardless of whether the image is there or not, Kubernetes will first attempt to pull the image, and this will fail if you haven't pushed it to any registry that it can see yet. For this reason, if using Minishift, we will still do the push step into the OpenShift built in registry, this has the advantage of being able to run the guide in a more realistic setup.

You still will need to setup the Minishift docker environment variables before you run this, since by default, the built in OpenShift docker registry is not exposed to your host machine, only the VM can see it.

The Minishift docker repository can be obtained by `minishift openshift registry`, so setup your Minishift environment, and initialize the `DOCKER_REPO_URL` environment variable to that:

@@snip[building.sh](scripts/building.sh) { #minishift-setup }

<!--- #intro --->
