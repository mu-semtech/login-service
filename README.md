# Mock Login microservice
This is a login microservice running on [mu.semte.ch](http://mu.semte.ch). The microservice provides the necessary endpoints to link the current session to a provided user and group.

## Integrate login service in a mu.semte.ch project
Add the following snippet to your `docker-compose.yml` to include the login service in your project.

```
login:
  image: lblod/mock-login-service
```

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
data: {
   relationships: {
     account:{
       data: {
         id: "account_id",
         type: "accounts"
       }
     },
     group:{
       data: {
         id: "group_id",
         type: "groups"
       }
     }, 
   },
   type: "sessions"
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
    },
    "group": {
      "links": {
        "related": "/groups/f6419af0-c60f-465f-9333-e993c43e6ch5"
      },
      "data": {
        "type": "groups",
        "id": "f6419af0-c60f-465f-9333-e993c43e6ch5"
      }
    }
  }
}
```

###### 400 Bad Request
- if session header is missing. The header should be automatically set by the [identifier](https://github.com/mu-semtech/mu-identifier).
- if the group or account doesn't exist


#### DELETE /sessions/current
Log out the current user, i.e. remove the session associated with the current user's account.

##### Response
###### 204 No Content
On successful logout

###### 400 Bad Request
If session header is missing or invalid. The header should be automatically set by the [identifier](https://github.com/mu-semtech/mu-identifier).
