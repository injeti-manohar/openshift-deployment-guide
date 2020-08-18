
if [ $INSTALL_SHOPPING_CART == 1 ]
then
    #apply-shopping-cart
    kubectl apply -f ../deploy/specs/shopping-cart.yaml
    #apply-shopping-cart

    #expose-shopping-cart
    kubectl expose svc/shopping-cart
    #expose-shopping-cart

    waitForApp app=shopping-cart 3
fi

if [ $INSTALL_INVENTORY == 1 ]
then

    if [ $SBT == 1 ]
    then
        #sbt-publish-inventory
        sbt -Ddocker.username=$NAMESPACE -Ddocker.registry=$DOCKER_REPO_URL inventory/docker:publish
        #sbt-publish-inventory
    else
        #maven-publish-inventory
        mvn -Ddocker.useOpenShiftAuth -Ddocker.registry=$DOCKER_REPO_URL/$NAMESPACE -am -pl inventory package docker:push
        #maven-publish-inventory
    fi

    #inventory-deploy
    kubectl set image-lookup inventory
    kubectl create secret generic inventory-application-secret --from-literal=secret="$(openssl rand -base64 48)"
    kubectl apply -f ../deploy/inventory.yaml
    kubectl expose svc/inventory
    #inventory-deploy

    waitForApp app=inventory 1
fi

#shopping-cart-host
SHOPPING_CART_HOST=$(kubectl get route shopping-cart -o jsonpath='{.spec.host}')
#shopping-cart-host

#inventory-host
INVENTORY_HOST=$(kubectl get route inventory -o jsonpath='{.spec.host}')
#inventory-host

SHOPPING_CART_ID=$(openssl rand -base64 6 | tr -- '+=/' '-_~')
PRODUCT_ID=$(openssl rand -base64 6 | tr -- '+=/' '-_~')

if [ $RUN_TESTS == 1 ]
then
    echo curl http://$SHOPPING_CART_HOST/shoppingcart/$SHOPPING_CART_ID
    curl "http://$SHOPPING_CART_HOST/shoppingcart/$SHOPPING_CART_ID"
    curl -H "Content-Type: application/json" -X POST -d '{"productId": "'$PRODUCT_ID'", "quantity": 2}' \
 "http://$SHOPPING_CART_HOST/shoppingcart/$SHOPPING_CART_ID"
    echo
    curl "http://$SHOPPING_CART_HOST/shoppingcart/$SHOPPING_CART_ID"
    echo
    curl "http://$SHOPPING_CART_HOST/shoppingcart/$SHOPPING_CART_ID/checkout" -X POST
    echo
    curl "http://$SHOPPING_CART_HOST/shoppingcart/$SHOPPING_CART_ID"
    echo

    # So that it can be copied...
    echo curl "http://$INVENTORY_HOST/inventory/$PRODUCT_ID"
    echo -n "Waiting for inventory service to process shopping cart message."

    count=0
    while [ $(curl -s "http://$INVENTORY_HOST/inventory/$PRODUCT_ID") != "-2" ]
    do
        (( count = count + 1 ))
        if [ $count -gt 30 ]
        then
            echo "FAILED."
            echo "Expected $PRODUCT_ID to have -2 inventory, but got $(curl -s "http://$INVENTORY_HOST/inventory/$PRODUCT_ID")."
            exit 1
        fi
        echo -n "."
        sleep 2
    done

    echo "SUCCESS!!"
fi

