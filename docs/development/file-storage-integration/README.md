# File storage integration

External file storages can be used from within OpenProject with the file storage module. This adds certain use cases,
e.g. in the files tab of a work package, to interact with files located on the storage and link them to entities in
OpenProject. Currently supported file storages are:

- [Nextcloud](https://nextcloud.com/)

## Checklist for new candidates

This section contains a checklist for new candidates for the development of a new file storage integration. It lists
requirements, which are meant to be the very foundation of making the basic use cases work.

- The file storage must have a HTTP API
- The user must be able to authenticate the requests against the API.
  - Currently supported authentication methods: OAuth2 with authorization code with or without PKCE
- The file storage must have uniquely identifiable files across the user context. (Any user must be able to find the
  file with the same identification data.)
- The file storage must provide a direct link to open the file on the file storage's web interface.
- The file storage must be able to fetch an index for a location, providing all children files and folders on this
  location.
- Optional: The file storage must provide a direct download link for the file.
- Optional: The file storage must provide a direct upload link for files to a location on the file storage.
