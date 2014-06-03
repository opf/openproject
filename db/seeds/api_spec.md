FORMAT: 1A

# Gist Fox API
Gist Fox API is a **pastes service** similar to [GitHub's Gist][http://gist.github.com].

# Gist Fox API Root [/]
Gist Fox API entry point.

This resource does not have any attributes. Instead it offers the initial API affordances in the form of the HTTP Link header and HAL links.

## Retrieve Entry Point [GET]

+ Response 200 (application/hal+json)
    + Headers

                Link: <http:/api.gistfox.com/>;rel="self",<http:/api.gistfox.com/gists>;rel="gists"

    + Body

                {
                    "_links": {
                        "self": { "href": "/" },
                        gists": { "href": "/gists?{since}", "templated": true }
                    }
                }

# Group Gist
Gist-related resources of *Gist Fox API*.

## Gist [/gists/{id}]
A single Gist object The Gist resource is the central resource in the Gist Fox API.

The Gist resource has the following attributes:

- id
- created_at
- description
- content

The states *id* and *created_at* are assigned by the Gist Fox API at the moment of creation.

+ Parameters
    + id (string) ... ID of the Gist in the form of a hash.

+ Model (application/hal+json)

        HAL+JSON representation of Gist Resource.

        + Headers

                Link: <http:/api.gistfox.com/gists/42>;rel="self", <http:/api.gistfox.com/gists/42/star>;rel="star"

        + Body

                {
                    "_links": {
                        "self": { "href": "/gists/42" },
                        "star": { "href": "/gists/42/star" },
                    },
                    id: 42,
                    "created_at": "2014-04-14T02:15:15Z",
                    "description": "Description of Gist",
                    "content": "String contents"
                }

### Retrieve a Single Gist [GET]
Some description

+ Response 200

    [Gist][]

### Edit a Gist [PATCH]
To update a Gist send a JSON with updated value fo one or more of the Gist resource attributes.

+ Request (application/json)

        {
            "content": "Updated file contents"
        }

+ Response 200

    [Gist][]

### Delete a Gist [DELETE]
+ Response 204

## Gists Collection [/fists{?since}]
Collection of all Gists.

The Gist collection resource has the following attributes:

- total

In addition it **embeds** *Gist Resources* in the Gist Fox API.

+ Model (application/hal+json)

    HAL+JSON representation of Gist collection resource.

    + Headers

            Link: <http:/api.gistfox.com/gists>;rel="self"

    + Body

            {
                "_links": {
                    "self": { "href": "/gists" }
                },
                "_embedded": {
                    "gists": [
                        {
                            "_links": {
                                "self": { "href": "/gists/42" }
                            },
                            "id": "42",
                            "created_at": "2014-04-14T02:15:15Z",
                            "description": "Description of Gist"
                        }
                    ]
                },
                "total": 1
            }

### List All Gists [GET]
+ Parameters
    + since (optional, string) ... Timestamp in ISO 8601 format

+ Response 200

    [Gists Collection][]

### Create a Gist [POST]
+ Request (application/json)

        {
            "description": "Description of Gist",
            "content": "String content"
        }

+ Response 201 (application/hal+json)

    [Gist][]

## Star [/gists/{id}/star]
Star resource represents a Gist starred status.

The Star resource has the following attributes:

- starred

+ Parameters

    + id (string)  ... ID of the gist in the form of a hash.

+ Model (application/hal+json)

    HAL+JSON representation of Star Resource.

    + Headers

            Link: <http:/api.gistfox.com/gists/42/star>;rel="self"

    + Body

            {
                "_links": {
                    "self": { "href": "/gists/42/star" },
                },
                "starred": true
            }

### Star a Gist [PUT]
+ Response 204

### Unstar a Gist [DELETE]
+ Response 204

### Check if a Gist is Starred [GET]
+ Response 200

    [Star][]
