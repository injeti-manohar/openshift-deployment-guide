# tag::apply-shopping-cart[]
oc apply -f deploy/shopping-cart.yaml
# end::apply-shopping-cart[]

# tag::expose-shopping-cart[]
oc expose svc/shopping-cart
# end::expose-shopping-cart[]

# tag::inventory-deploy[]
oc set image-lookup inventory
oc create secret generic inventory-application-secret --from-literal=secret="$(openssl rand -base64 48)"
oc apply -f deploy/inventory.yaml
oc expose svc/inventory
# end::inventory-deploy[]


# tag::shopping-cart-host[]
SHOPPING_CART_HOST=$(oc get route shopping-cart -o jsonpath='{.spec.host}')
# end::shopping-cart-host[]

# tag::inventory-host[]
INVENTORY_HOST=$(oc get route inventory -o jsonpath='{.spec.host}')
# end::inventory-host[]


# tag::sbt-publish-inventory[]
sbt -Ddocker.username=$NAMESPACE -Ddocker.registry=$DOCKER_REPO_URL inventory/docker:publish
# end::sbt-publish-inventory[]

# tag::maven-publish-inventory[]
mvn -Ddocker.useOpenShiftAuth -Ddocker.registry=$DOCKER_REPO_URL/$NAMESPACE -am -pl inventory package docker:push
# end::maven-publish-inventory[]

# tag::shopping-cart-image-lookup[]
oc set image-lookup shopping-cart
# end::shopping-cart-image-lookup[]
