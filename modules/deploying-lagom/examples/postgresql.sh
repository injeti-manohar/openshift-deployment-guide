
echo "Installing Postgres"

# tag::new-app[]
oc new-app -e POSTGRESQL_USER=PostgreSQL -e POSTGRESQL_PASSWORD=sdfasdfsad -e POSTGRESQL_DATABASE=shopping_cart postgresql
# end::new-app[]

# tag::create-admin-password[]
oc create secret generic postgresql-admin-password --from-literal=password="$(openssl rand -base64 24)"
# end::create-admin-password[]

# tag::patch[]
oc patch deploymentconfig postgresql --patch '{"spec": {"template": {"spec": {"containers": [
  {"name": "postgresql", "env": [
    {"name": "POSTGRESQL_ADMIN_PASSWORD", "valueFrom":
      {"secretKeyRef": {"name": "postgresql-admin-password", "key": "password"}}
    }
  ]}
]}}}}'
# end::patch[]

waitForApp app=postgresql 1

# tag::port-forward[]
oc port-forward svc/postgresql 15432:5432 &
# end::port-forward[]

echo Sleeping for 5 seconds while port forward is established...
sleep 5

# tag::create-user-password[]
oc create secret generic postgres-shopping-cart --from-literal=username=shopping_cart --from-literal=password="$(openssl rand -base64 24)"
# end::create-user-password[]

# tag::connect-database[]
psql -h localhost -p 15432 -U postgres 
# end::connect-database[]

CREATE USER shopping_cart WITH PASSWORD '$(oc get secret postgres-shopping-cart -o jsonpath='{.data.password}' | base64 --decode)';

>>DDL
# tag::create-ddl[]
REVOKE CONNECT ON DATABASE shopping_cart FROM PUBLIC;
GRANT CONNECT ON DATABASE shopping_cart TO shopping_cart;

\connect shopping_cart;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO shopping_cart;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO shopping_cart;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, USAGE ON SEQUENCES TO shopping_cart;

\include schemas/shopping-cart.sql;
# end::create-ddl[]
DDL


kill %1
