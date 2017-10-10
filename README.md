# README

Simple issue tracker

## Installation

* Ruby version: 2.4.0
* Database: postgresql

Before you continue, copy `config/database.yml.example` to `config/database.yml` and edit the file for your settings.

## Authorization

The application uses JWT (JSON Web Token) to authorize requests. Every requests which needs to be auhtorized must be signed with an authorization header with JWT:
`Authorization: Bearer <<token>>` (e.g. `Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9`)

To receive a token, look at the "API Endpoints" section, subsection `/user_token`

If a request made without (or with incorrect/expired/etc) token to a protected endpoint, `401 Unauthorized` will be returned.

## Handling API errors

All errors are returns in JSON format with `application/json` content-type and a status code.

All errors contain `message` key (e.g. 'Not Found' or 'Validation failed: Full name can't be blank'). Some errors may contain section `error:string` or `errors:array<string>`. For example, validation errors (status 422 Unprocessable Entity) looks like:

```
  {
    "errors": {
      "full_name": ["can't be blank"]
    },
    "message": "Validation failed: Full name can't be blank"
  }
```

## API Endpoints

**Note:** if it's not noticed, all requests have to be made with `application/json` content-type. All responses are `application/json` too.

### `POST /user_token` to get a JSON Web Token

#### Receives
JSON `{auth: {email:string, password:string}}`

#### Responses

|Code| Content        | Description                                       |
|----|----------------|---------------------------------------------------|
|404 | Not Found      | When user does not exist or password is incorrect |
|201 | `{jwt:string}` | A JSON Web token for future authorizations        |

#### Example
`curl -H "Content-Type: application/json" -i -X POST -d '{"auth": {"email":"john@local.host", "password":"12345678"}}' http://localhost:3000/user_token`

Check the given token:
`curl -i -H "Content-Type: application/json" -H "Authorization: Bearer <<token>>" http://localhost:3000/secret`. If everything is good, you will receive `{"message":"You found a cow level!"}` with status 200.

### `POST /users` to create (register) users

### Receives
JSON `{user: {email:string, password:string, full_name:string}}`.

It does not request password confirmation because it's absolutely UI responsibility to help the user enter correct password.

### Responses

|Code| Content              | Description                                |
|----|----------------------|--------------------------------------------|
|422 | Unprocessable Entity | A validation error                         |
|201 | `{jwt:string}`       | a JSON Web token for future authorizations |

### Example
`curl -H "Content-Type: application/json" -i -X POST -d '{"user": {"email":"john@local.host", "password":"12345678", "full_name":"John Snow"}}' http://localhost:3000/users`
