[![Build Status](https://semaphoreci.com/api/v1/azzz/tracky/branches/master/badge.svg)](https://semaphoreci.com/azzz/tracky)

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

##### Receives
JSON `{auth: {email:string, password:string}}`

##### Responses

|Code| Content        | Description                                       |
|----|----------------|---------------------------------------------------|
|404 | Not Found      | When user does not exist or password is incorrect |
|201 | `{jwt:string}` | A JSON Web token for future authorizations        |

##### Example
`curl -H "Content-Type: application/json" -i -X POST -d '{"auth": {"email":"john@local.host", "password":"12345678"}}' http://localhost:3000/user_token`

Check the given token:
`curl -i -H "Content-Type: application/json" -H "Authorization: Bearer <<token>>" http://localhost:3000/secret`. If everything is good, you will receive `{"message":"You found a cow level!"}` with status 200.

### `POST /users` to create (register) users

#### Receives
JSON `{user: {email:string, password:string, full_name:string}}`.

It does not request password confirmation because it's absolutely UI responsibility to help the user enter correct password.

#### Responses

|Code| Content              | Description                                |
|----|----------------------|--------------------------------------------|
|422 | Unprocessable Entity | A validation error                         |
|201 | `{jwt:string}`       | A JSON Web token for future authorizations |

#### Example
`curl -H "Content-Type: application/json" -i -X POST -d '{"user": {"email":"john@local.host", "password":"12345678", "full_name":"John Snow"}}' http://localhost:3000/users`

### GET `/users/:id` to read an user

#### Authorization

Any roles are allowed to read an user. Clients can read only themselves, but managers can read any user.

#### Responses

|Code| Content         | Description                                             |
|----|-----------------|---------------------------------------------------------|
|200 | `{user:object}` | User object                                             |
|401 | none            | If the user does not have access to read the given user |
|404 | none            | If the given user does not exist                        |

#### Example
`curl -i -H "Content-Type: application/json" -H "Authorization: Bearer <<token>>" http://localhost:3000/users/1`

```
{
  "user": {
    "id": 1,
    "email": "email.1@example.com",
    "full_name": "Pandora Dibbert",
    "role": "client",
    "created_at": "2017-10-11T17:20:35.720Z",
    "updated_at": "2017-10-11T17:20:35.720Z"
  }
}
```

### GET `/issues` to get list of issues

#### Authorization

Any roles are allowed to get list of issues. Clients receive only issues created by them, but managers receive all existing issues.

#### Receives

GET arguments:
- `offset:integer` Optional. A number how it should offset the result. By default, 0. I.e. shows from the beginning.
- `limit:integer` Optional. A number to limit the response. By default, 10. Maximum, 100.

#### Responses

|Code| Content                 | Description                                |
|----|-------------------------|--------------------------------------------|
|200 | `{issues:array<object>}`| A list of issues                           |

#### Example
`curl -i -H "Content-Type: application/json" -H "Authorization: Bearer <<token>>" http://localhost:3000/issues?limit=42`

```
  {
    "issues":
      [
        {"id":1,
         "author_id": 1,
         "assignee_id": 2,
         "title": "Protect the North",
         "description": "You must protect the North",
         "status": "pending",
         "created_at": "2017-10-11T17:25:38.967Z",
         "updated_at": "2017-10-11T17:25:38.967Z"},

         ...
      ]
   }
```

### GET `/issues/:id` to read an issue

#### Authorization

Any roles are allowed to read an issue. Clients can read only issues created by them, but managers can read any issue.

#### Responses

|Code| Content         | Description                               |
|----|-----------------|-------------------------------------------|
|200 | `{issue:object}`| Issue object                              |
|401 | none            | If user does not have access to the issue |
|404 | none            | If issue does not exist                   |

#### Example
`curl -i -H "Content-Type: application/json" -H "Authorization: Bearer <<token>>" http://localhost:3000/issues/1`

```
{
  "issue": {
    "id": 1,
    "author_id": 1,
    "assignee_id": 2,
    "title": "Protect the North",
    "description": "You must protect the North",
    "status": "pending",
    "created_at": "2017-10-11T17:25:38.967Z",
    "updated_at": "2017-10-11T17:25:38.967Z"
  }
}
```

### POST `/issues` to create an issue

#### Authorization
Any roles can create issues in any status. Issues in non-pending status must have assignee_id.

#### Receives
JSON `{issue:object}` where object is attributes object. Can get next attributes:

- `title:string`. Required. Short title of the issue.
- `description:text`. Optional. Details description of the issue.
- `status:string`. Optional. Allowed values: `pending`, `in_progress`, `resolved`. By default, `pending`
- `assignee_id:integer`. Optional if status is missing or `pending`.

#### Responses

|Code| Content         | Description                               |
|----|-----------------|-------------------------------------------|
|200 | `{issue:object}`| Issue object                              |
|422 | none            | A validation error                        |

#### Example
`curl -i -H "Content-Type: application/json" -H "Authorization: Bearer <<token>>" -X POST -d '{"issue": {"title":"Hello World", "description":"Please help me they turned me in a parrot"}}' http://localhost:3000/issues`

```
{
  "issue": {
    "id": 4,
    "author_id": 1,
    "assignee_id": null,
    "title": "Hello World",
    "description": "Please help me they turned me in a parrot",
    "status": "pending",
    "created_at": "2017-10-11T18:27:47.043Z",
    "updated_at": "2017-10-11T18:27:47.043Z"
  }
}
```

### PUT `/issues/:id` to update an issue

#### Authorization

Any roles are allowed to update issues. Clients can update only issues created by them, but managers can update any issue.

#### Receives
JSON `{issue:object}` where object is attributes object. Can get next attributes:

- `title:string`. Required. Short title of the issue.
- `description:text`. Optional. Details description of the issue.
- `status:string`. Optional. Allowed values: `pending`, `in_progress`, `resolved`. By default, `pending`
- `assignee_id:integer`. Optional if status is missing or `pending`.

Skipped attributes will not be applied to the issue as null (or "") values.

#### Responses

|Code| Content         | Description                               |
|----|-----------------|-------------------------------------------|
|200 | `{issue:object}`| Issue object                              |
|422 | none            | A validation error                        |

#### Example
`curl -i -H "Content-Type: application/json" -H "Authorization: Bearer <<token>>" -X PUT -d '{"issue": {"title":"Find a magic wand"}}' http://localhost:3000/issues/4`

```
{
  "issue": {
    "id": 4,
    "author_id": 1,
    "assignee_id": null,
    "title": "Find a magic wand",
    "description": "Please help me they turned me in a parrot",
    "status": "pending",
    "created_at": "2017-10-11T18:27:47.043Z",
    "updated_at": "2017-10-11T18:27:47.043Z"
  }
}
```
