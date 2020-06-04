# Building using sbt

sbt uses a plugin called [sbt-native-packager](https://www.scala-sbt.org/sbt-native-packager/) to allow conveniently packaging Java and Scala applications built using sbt as Docker images.

## Setup

To use this plugin in your sbt application, add the following to your `project/plugins.sbt` file:

@@@vars
```scala
addSbtPlugin("com.typesafe.sbt" % "sbt-native-packager" % "$sbt.native.packager.version$")
```
@@@

Now you can enable the appropriate plugins in your build, by modifying your project in `build.sbt`:

```scala
enablePlugins(JavaAppPackaging, DockerPlugin)
```

Here we're telling native packager to package our application as a Java application that can be run from the command line. This will package up all the applications dependencies (jar files), and generate a start script to start the application. To generate this start script, native packager needs to know what the applications main class is. When the application only has one main class in its source folder, sbt will detect this automatically, but in case there are multiple, or the main class comes from a dependency, it can be set in `build.sbt` like so:

```scala
mainClass in Compile := Some("com.lightbend.example.Main")
```

<!--- #no-setup --->
### Selecting a JDK

By default, sbt native packager uses the `openjdk` latest Docker image from DockerHub. At time of writing, this will give you OpenJDK 11, which is not certified by Lightbend, and it also gives you the Debian OpenJDK build, which is not certified by Lightbend either. For a full list of Lightbend certified JDK builds and versions, see [here](https://developer.lightbend.com/docs/reactive-platform/2.0/supported-java-versions/index.html).

If you're a RedHat customer, then you will probably want to use RedHat's certified OpenJDK base image, which is using RHEL. These OpenJDK builds are certified by Lightbend too for use with Lightbend products. This can be configured using:

```scala
dockerBaseImage := "registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift"
```

Otherwise, we recommend using the AdoptOpenJDK base image:

```scala
dockerBaseImage := "adoptopenjdk/openjdk8"
```

### Git hash based version numbers

This step is optional, but we recommend basing the version number of your application on the current git hash, since this ensures that you will always be able to map what is deployed to production back to the exact version of your application being used.

There are a number of sbt plugins available for generating a version number from a git hash, we're going to use [`sbt-dynver`](https://github.com/dwijnand/sbt-dynver), which incorporates the most recent git tag as the base version number, appends the git hash to that only if there are any changes since that tag, and also includes a datetime stamp if there are local changes in the repository. To add this plugin to your project, add the following to `project/plugins.sbt`:

@@@vars
```scala
addSbtPlugin("com.dwijnand" % "sbt-dynver" % "$sbt.dynver.version$")
```
@@@

For the plugin to work, you need to ensure that you *don't* specify a `version` in your sbt build, since this will overwrite the version that `sbt-dynver` generates. Additionally, `sbt-dynver` generates versions with a `+` character in them (the `+` is used to indicate how many commits have been added since the last tag, so `1.0+4` indicates this is the 1.0 tag plus 4 commits). To replace this with a `-` character, add the following to `build.sbt`:

```scala
version in ThisBuild ~= (_.replace('+', '-'))
dynver in ThisBuild ~= (_.replace('+', '-'))
```

You may also want to configure the sbt native packager to tag your image as the `latest` image, this will be necessary if you're using the `latest` tag in your deployment spec. To do this, enable `dockerUpdateLatest` in `build.sbt`:

```scala
dockerUpdateLatest := true
```

### Configuring deployment

After building the docker image, we will need to deploy it to your Docker registry. To do that, we need to configure both the docker username as well as the registry. 
This can be done by configuring the `dockerUsername` and `dockerRepository` settings:

```scala
dockerUsername := sys.props.get("docker.username")
dockerRepository := sys.props.get("docker.registry")
```

In this case, we're reading both variables from system properties, which ensures that the build is not tied to any particular registry. We'll supply these system properties when we invoke sbt.

## Building the docker image

Now that we're setup, we can build our docker image. Run the following:

@@snip[building.sh](scripts/building.sh) { #sbt }

This will build the project that you wish to build, tag it, and then push it to the configured Docker registry.

<!--- #no-setup --->