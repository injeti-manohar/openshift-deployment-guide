
if [ "$DOCKER_REPO_URL" == "minishift" ]
then
    #minishift-setup
    eval $(minishift docker-env)
    DOCKER_REPO_URL=$(minishift openshift registry)
    #minishift-setup
fi

if [ $INSTALL_SHOPPING_CART == 1 ]
then
    if [ $SBT == 1 ]
    then
        #sbt
        sbt -Ddocker.username=$NAMESPACE -Ddocker.registry=$DOCKER_REPO_URL shopping-cart/docker:publish
        #sbt
    else
        #maven
        mvn -Ddocker.username=$NAMESPACE -Ddocker.registry=$DOCKER_REPO_URL/$NAMESPACE -am -pl shopping-cart package docker:push
        #maven
    fi
fi