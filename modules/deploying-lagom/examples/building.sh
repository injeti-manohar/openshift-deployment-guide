
if [ "$DOCKER_REPO_URL" == "minishift" ]
then
    # tag::minishift[]
    eval $(minishift docker-env)
    DOCKER_REPO_URL=$(minishift openshift registry)
    # end::minishift[]
fi

# tag::login[]
oc whoami -t | docker login -u $(oc whoami) --password-stdin $DOCKER_REPO_URL
# end::login[]

if [ $INSTALL_SHOPPING_CART == 1 ]
then
    if [ $SBT == 1 ]
    then
        # tag::sbt[]
        sbt -Ddocker.username=$NAMESPACE -Ddocker.registry=$DOCKER_REPO_URL shopping-cart/docker:publish
        # end::sbt[]
    else
        #tag::maven[]
        mvn -Ddocker.useOpenShiftAuth -Ddocker.registry=$DOCKER_REPO_URL/$NAMESPACE -am -pl shopping-cart package docker:push
        #end::maven[]
    fi

    # tag::image-lookup[]
    oc set image-lookup shopping-cart
    # end::image-lookup[]
fi