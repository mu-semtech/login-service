# Login microservice
Login microservice running on [mu.semte.ch](http://mu.semte.ch).

## Integrate login service in a mu.semte.ch project
Add the following snippet to your `docker-compose.yml` to include the login service in your project.

```
login:
  image: semtech/mu-login-service:2.5.0
  links:
    - database:database
  environment:
    MU_APPLICATION_SALT: mysupersecretsaltchangeme
```

The triple store used in the backend is linked to the login service container as `database`. If you configure another SPARQL endpoint URL through `MU_SPARQL_ENDPOINT` update the link name accordingly. Make sure the login service is able to execute update queries against this store.

The `MU_APPLICATION_SALT` environment variable specifies (part of) the salt used to hash the user passwords. Configure the [registration microservice](https://github.com/mu-semtech/registration-service) with the same salt.

The `MU_APPLICATION_GRAPH` environment variable (default: `http://mu.semte.ch/application`) specifies the graph in the triple store the login service will work in.


Add rules to the `dispatcher.ex` to dispatch requests to the login service. E.g. 

```
  match "/sessions/*path" do
    Proxy.forward conn, path, "http://login/sessions/"
  end
```
The host `login` in the forward URL reflects the name of the login service in the `docker-compose.yml` file as defined above.

More information how to setup a mu.semte.ch project can be found in [mu-project](https://github.com/mu-semtech/mu-project).


## Available requests

#### POST /sessions
Log in, i.e. create a new session for an account specified by its nickname and password.

##### Request body
```javascript
{
  "data": {
    "type": "sessions",
    "attributes": {
      "nickname": "john_doe",
      "password": "secret"
    }
  }
}
```

##### Response
###### 201 Created
On successful login with the newly created session in the response body:

```javascript
{
  "links": {
    "self": "sessions/current"
  },
  "data": {
    "type": "sessions",
    "id": "b178ba66-206e-4551-b41e-4a46983912c0"
  },
  "relationships": {
    "account": {
      "links": {
        "related": "/accounts/f6419af0-c90f-465f-9333-e993c43e6cf2"
      },
      "data": {
        "type": "accounts",
        "id": "f6419af0-c90f-465f-9333-e993c43e6cf2"
      }
    }
  }
}
```

###### 400 Bad Request
- if session header is missing. The header should be automatically set by the [identifier](https://github.com/mu-semtech/mu-identifier).
- if combination of nickname and password is incorrect.
- if account is inactive.



#### DELETE /sessions/current
Log out the current user, i.e. remove the session associated with the current user's account.

##### Response
###### 204 No Content
On successful logout

###### 400 Bad Request
If session header is missing or invalid. The header should be automatically set by the [identifier](https://github.com/mu-semtech/mu-identifier).
