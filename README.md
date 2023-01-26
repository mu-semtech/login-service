# Login microservice
Login microservice running on [mu.semte.ch](http://mu.semte.ch).

## How-To
### Add the login service to a stack
Add the following snippet to your `docker-compose.yml` to include the login service in your project.

```
login:
  image: semtech/mu-login-service:3.0.0
  links:
    - database:database
```

The triplestore used in the backend is linked to the login service container as `database`.

Next, add the following rules in `./config/dispatcher/dispatcher.ex` to dispatch requests to the login service. E.g.

```
  match "/sessions/*path", @any do
    Proxy.forward conn, path, "http://login/sessions/"
  end
```

The host `login` in the forward URL reflects the name of the login service in the `docker-compose.yml` file as defined above.

More information how to setup a mu.semte.ch project can be found in [mu-project](https://github.com/mu-semtech/mu-project).

## Tutorials
A tutorial using this repository can be found at https://github.com/mu-semtech/mu-project#adding-authentication-to-your-mu-project

## Reference
### Configuration
The following enviroment variables can be set on the login service:

- **USERS_GRAPH** : graph in which the person and account resources will be stored. E.g. `http://mu.semte.ch/graphs/users`. Defaults to `http://mu.semte.ch/application`.
- **SESSIONS_GRAPH** : graph in which the session resources will be stored. E.g. `http://mu.semte.ch/graphs/sessions`. Defaults to `http://mu.semte.ch/application`.
- **MU_APPLICATION_SALT** : strengthen the password hashing by configuring an application wide salt. This salt will be concatenated with a salt generated per user to hash the user passwords. By default the application wide salt is not set. If you configure this salt, make sure to configure the [registration microservice](https://github.com/mu-semtech/registration-service) with the same salt. Setting the salt makes account resources non-shareable with stacks containing a login-service configured with another salt.

### Model
This section describes the minimal required model for the login service. These models can be enriched with additional properties and/or relations.

The graphs is which the resources are stored, can be configured via environment variables.

#### Used prefixes
| Prefix  | URI                                      |
|---------|------------------------------------------|
| mu      | http://mu.semte.ch/vocabularies/core/    |
| account | http://mu.semte.ch/vocabularies/account/ |
| session | http://mu.semte.ch/vocabularies/session/ |
| foaf    | http://xmlns.com/foaf/0.1/               |

#### Accounts
##### Class
`foaf:OnlineAccount`

##### Properties
| Name        | Predicate          | Range           | Definition                                                                                                                            |
|-------------|--------------------|-----------------|---------------------------------------------------------------------------------------------------------------------------------------|
| accountName | `foaf:accountName` | `xsd:string`    | Account name / nickname                                                                                                               |
| password    | `account:password` | `xsd:string`    | Hashed password of the account                                                                                                        |
| salt        | `account:salt`     | `xsd:string`    | Salt used to hash the password                                                                                                        |
| status      | `account:status`   | `rdfs:Resource` | Status of the account. Only active (`<http://mu.semte.ch/vocabularies/account/status/active>`) accounts are taken into account on login. |

#### Sessions
##### Class
None

##### Properties
| Name    | Predicate         | Range                | Definition                     |
|---------|-------------------|----------------------|--------------------------------|
| account | `session:account` | `foaf:OnlineAccount` | Account related to the session |

### API
#### POST /sessions
Log in, i.e. create a new session for an account specified by its nickname and password.

##### Request body
```json
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

```json
{
  "links": {
    "self": "sessions/current"
  },
  "data": {
    "type": "sessions",
    "id": "b178ba66-206e-4551-b41e-4a46983912c0",
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

### Releases
#### v3.0.0
Breaking changes:
- Make responses JSON-API compliant by moving `relationships` into `data` object. It has become a child rather than a sibling. 

  You may need to change `data.authenticated.relationships.account.data.id` in the frontend to `data.authenticated.data.relationships.account.data.id` in order to consume the response data. 
