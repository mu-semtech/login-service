# Login microservice
Login microservice using a triple store in the backend

## Running the login microservice
    docker run --name mu-login \
        -p 80:80 \
        --link my-triple-store:database \
        -e MU_APPLICATION_GRAPH=http://mu.semte.ch/app \
        -e MU_APPLICATION_SALT=mysupersecretsaltchangeme \
        -d semtech/mu-login-service
        
The triple store used in the backend is linked to the login service container as `database`. Make sure the login service is able to execute update queries against this store.

The `MU_APPLICATION_GRAPH` environment variable specifies the graph in the triple store the login service will work in.

The `MU_APPLICATION_SALT` environment variable specifies (part of) the salt used to hash the user passwords. Configure the [registration microservice](https://github.com/mu-semtech/registration-service) with the same salt.


