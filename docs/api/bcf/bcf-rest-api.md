# BCF REST API
![](https://raw.githubusercontent.com/BuildingSMART/BCF/master/Icons/BCFicon128.png)

The following describes the extensions and deviations of the BCF API v2.1 implementation in OpenProject. 

This document should be read as an extension to the [standard specification](https://github.com/buildingSMART/BCF-API/blob/release_2_1/README.md). 
The user should read the standard specification first, and then take a look at this document to be informed about OpenProject specificities.

While the intend of the implementation is to follow the specification, the API builds on the existing OpenProject data
schema and by that requires to map between the concepts required in the much broader domain of project management and BCF. 

In other parts, the BCF API specification has not been completely implemented. It will be amended where requirements dictate.
OpenProject offers a second API (v3) which might be able to fill the gaps the BCF API implementation still has.

The document follows the structure of the standard specification to ease comparing the two documents.

**Table of Contents**

<!-- toc -->

- [1. Introduction](#1-introduction)
  * [1.1 Paging, Sorting and Filtering](#11-paging-sorting-and-filtering)
  * [1.2 Caching](#12-caching)
  * [1.3 Updating Resources via HTTP PUT](#13-updating-resources-via-http-put)
  * [1.4 Cross Origin Resource Sharing (CORS)](#14-cross-origin-resource-sharing-cors)
  * [1.5 Http Status Codes](#15-http-status-codes)
  * [1.6 Error Response Body Format](#16-error-response-body-format)
  * [1.7 DateTime Format](#17-datetime-format)
  * [1.8 Authorization](#18-authorization)
    + [1.8.1 Per-Entity Authorization](#181-per-entity-authorization)
    + [1.8.2 Determining Authorized Entity Actions](#182-determining-authorized-entity-actions)
  * [1.9 Additional Response and Request Object Properties](#19-additional-response-and-request-object-properties)
  * [1.10 Binary File Uploads](#110-binary-file-uploads)
- [2. Topologies](#2-topologies)
  * [2.1 Topology 1 - BCF-Server only](#21-topology-1---bcf-server-only)
  * [2.2 Topology 2 - Colocated BCF-Server and Model Server](#22-topology-2---colocated-bcf-server-and-model-server)
- [3. Public Services](#3-public-services)
  * [3.1 Versions Service](#31-versions-service)
  * [3.2 Authentication Services](#32-authentication-services)
    + [3.2.1 Obtaining Authentication Information](#321-obtaining-authentication-information)
    + [3.2.2 OAuth2 Example](#322-oauth2-example)
    + [3.2.3 OAuth2 Protocol Flow - Dynamic Client Registration](#323-oauth2-protocol-flow---dynamic-client-registration)
  * [3.3 User Services](#33-user-services)
    + [3.3.1 Get current user](#331-get-current-user)
- [4. BCF Services](#4-bcf-services)
  * [4.1 Project Services](#41-project-services)
    + [4.1.1 GET Projects Service](#411-get-projects-service)
    + [4.1.2 GET Project Service](#412-get-project-service)
    + [4.1.3 PUT Project Service](#413-put-project-service)
    + [4.1.4 GET Project Extension Service](#414-get-project-extension-service)
    + [4.1.5 Expressing User Authorization Through Project Extensions](#415-expressing-user-authorization-through-project-extensions)
      - [4.1.5.1 Project](#4151-project)
      - [4.1.5.2 Topic](#4152-topic)
      - [4.1.5.3 Comment](#4153-comment)
  * [4.2 Topic Services](#42-topic-services)
    + [4.2.1 GET Topics Service](#421-get-topics-service)
    + [4.2.2 POST Topic Service](#422-post-topic-service)
    + [4.2.3 GET Topic Service](#423-get-topic-service)
    + [4.2.4 PUT Topic Service](#424-put-topic-service)
    + [4.2.5 DELETE Topic Service](#425-delete-topic-service)
    + [4.2.6 GET Topic BIM Snippet Service](#426-get-topic-bim-snippet-service)
    + [4.2.7 PUT Topic BIM Snippet Service](#427-put-topic-bim-snippet-service)
    + [4.2.8 Determining Allowed Topic Modifications](#428-determining-allowed-topic-modifications)
  * [4.3 File Services](#43-file-services)
    + [4.3.1 GET Files (Header) Service](#431-get-files-header-service)
    + [4.3.2 PUT Files (Header) Service](#432-put-files-header-service)
  * [4.4 Comment Services](#44-comment-services)
    + [4.4.1 GET Comments Service](#441-get-comments-service)
    + [4.4.2 POST Comment Service](#442-post-comment-service)
    + [4.4.3 GET Comment Service](#443-get-comment-service)
    + [4.4.4 PUT Comment Service](#444-put-comment-service)
    + [4.4.5 DELETE Comment Service](#445-delete-comment-service)
    + [4.4.6 Determining allowed Comment modifications](#446-determining-allowed-comment-modifications)
  * [4.5 Viewpoint Services](#45-viewpoint-services)
    + [4.5.1 GET Viewpoints Service](#451-get-viewpoints-service)
    + [4.5.2 POST Viewpoint Service](#452-post-viewpoint-service)
      - [4.5.2.1 Point](#4521-point)
      - [4.5.2.2 Direction](#4522-direction)
      - [4.5.2.3 Orthogonal camera](#4523-orthogonal-camera)
      - [4.5.2.4 Perspective camera](#4524-perspective-camera)
      - [4.5.2.5 Line](#4525-line)
      - [4.5.2.6 Clipping plane](#4526-clipping-plane)
      - [4.5.2.7 Bitmap](#4527-bitmap)
      - [4.5.2.8 Snapshot](#4528-snapshot)
      - [4.5.2.9 Components](#4529-components)
      - [4.5.2.10 Component](#45210-component)
        * [Optimization rules](#optimization-rules)
      - [4.5.2.11 Coloring](#45211-coloring)
        * [Optimization rules](#optimization-rules-1)
      - [4.5.2.12 Visibility](#45212-visibility)
        * [Optimization rules](#optimization-rules-2)
      - [4.5.2.13 View setup hints](#45213-view-setup-hints)
    + [4.5.3 GET Viewpoint Service](#453-get-viewpoint-service)
    + [4.5.4 GET Viewpoint Snapshot Service](#454-get-viewpoint-snapshot-service)
    + [4.5.5 GET Viewpoint Bitmap Service](#455-get-viewpoint-bitmap-service)
    + [4.5.6 GET selected Components Service](#456-get-selected-components-service)
    + [4.5.7 GET colored Components Service](#457-get-colored-components-service)
    + [4.5.8 GET visibility of Components Service](#458-get-visibility-of-components-service)
  * [4.6 Related Topics Services](#46-related-topics-services)
    + [4.6.1 GET Related Topics Service](#461-get-related-topics-service)
    + [4.6.2 PUT Related Topics Service](#462-put-related-topics-service)
  * [4.7 Document Reference Services](#47-document-reference-services)
    + [4.7.1 GET Document References Service](#471-get-document-references-service)
    + [4.7.2 POST Document Reference Service](#472-post-document-reference-service)
    + [4.7.3 PUT Document Reference Service](#473-put-document-reference-service)
  * [4.8 Document Services](#48-document-services)
    + [4.8.1 GET Documents Service](#481-get-documents-service)
    + [4.8.2 POST Document Service](#482-post-document-service)
    + [4.8.3 GET Document Service](#483-get-document-service)
  * [4.9 Topics Events Services](#49-topics-events-services)
    + [4.9.1 GET Topics Events Service](#491-get-topics-events-service)
    + [4.9.2 GET Topic Events Service](#492-get-topic-events-service)
  * [4.10 Comments Events Services](#410-comments-events-services)
    + [4.10.1 GET Comments Events Service](#4101-get-comments-events-service)
    + [4.10.2 GET Comment Events Service](#4102-get-comment-events-service)

<!-- tocstop -->

# 1. Introduction

All end points are nested within the `/api` path. So for a server listening on `https://foo.com/` the API root will be
`https://foo.com/api/bcf/2.1`. For a server listening on `https://foo.com/bar` the API root will be
`https://foo.com/bar/api/bcf/2.1`.

## 1.1 Paging, Sorting and Filtering

_Not implemented_

## 1.2 Caching

_Implemented_

## 1.3 Updating Resources via HTTP PUT

_Implemented_

## 1.4 Cross Origin Resource Sharing (CORS)

_Not implemented_

## 1.5 Http Status Codes

_Implemented_

## 1.6 Error Response Body Format

_Implemented_

## 1.7 DateTime Format

_Implemented_

## 1.8 Authorization

_Implemented_

Authorization is granted based on the _view_linked_issues_ and the _manage_bcf_ permission. As BCFs share part of their
data structure with WorkPackages, which enables them to be worked on by the project team just like any other work package,
a user also needs to have the _view_work_packages_ permission to have _view_linked_issues_. For _manage_bcf_ the permissions
_view_work_packages_, _add_work_packages_, _edit_work_packages_ and _delete_work_packages_ are dependently required.

### 1.8.1 Per-Entity Authorization

_Implemented_

The `authorization` field is always returned, regardless of an `includeAuthorization` query parameter.

### 1.8.2 Determining Authorized Entity Actions

_Implemented_

## 1.9 Additional Response and Request Object Properties

The implementation relies on a client to particularly adhere to this.

## 1.10 Binary File Uploads

_Implemented_

# 2. Topologies

_Out of scope_

# 3. Public Services

## 3.1 Versions Service

_Not implemented_

## 3.2 Authentication Services

### 3.2.1 Obtaining Authentication Information

_Implemented_

The following OAuth2 flows are supported:
* `authorization_code_grant` - [4.1 - Authorization Code Grant](https://tools.ietf.org/html/rfc6749#section-4.1)
* `client_credentials` - [4.4 - Client Credentials Grant](https://tools.ietf.org/html/rfc6749#section-4.4)

The `clients_credentials` grant explicitly ruled out by the standard specification as not being user specific can be supported by OpenProject as the grant is mapped to a user account
when configuring the OAuth access.

Before a client is able to perform the flows, they need to be [configured in OpenProject](https://docs.openproject.org/system-admin-guide/authentication/oauth-applications/). `bcf_v2_1` needs
to be checked for the scope. That value also needs to be provided for the scope property in OAuth requests.

The OAuth2 flows alternatively proposed by the specification
* `implicit_grant` - [4.2 - Implicit Grant](https://tools.ietf.org/html/rfc6749#section-4.2)
* `resource_owner_password_credentials_grant` - [4.3 - Resource Owner Password Credentials Grant](https://tools.ietf.org/html/rfc6749#section-4.3)
are not implemented.

### 3.2.2 OAuth2 Example

_Out of scope_

### 3.2.3 OAuth2 Protocol Flow - Dynamic Client Registration

_Not implemented_

## 3.3 User Services

### 3.3.1 Get current user

_Implemented_

# 4. BCF Services

## 4.1 Project Services

The `project_id` is an integer value. However, the API also understands requests where the project identifier, e.g. `bcf_project`
is used instead of the integer within a url. So the following urls might point to the same project resource: `/api/bcf/2.1/projects/3` and `/api/bcf/2.1/projects/bcf_project`.

### 4.1.1 GET Projects Service

_Partly implemented_

The end point is implemented but lacks the `authorization` property. However, the [Project Extension Service](#414-get-project-extension-service) is completely implemented and provides the same information.

### 4.1.2 GET Project Service

_Partly implemented_

The end point is implemented but lacks the `authorization` property. However, the [Project Extension Service](#414-get-project-extension-service) is completely implemented and provides the same information.

### 4.1.3 PUT Project Service

_Implemented_

### 4.1.4 GET Project Extension Service

_Implemented and extended_

However, as some end points are not implemented, the actions indicating the ability to call those end points will also not be returned, e.g. `updateDocumentReferences` 

### 4.1.5 Expressing User Authorization Through Project Extensions

_Out of scope_

#### 4.1.5.1 Project

_Implemented and extended_

* *viewTopic* - The ability to see topics (see [4.2.3 GET Topic Service](#423-get-topic-service))

#### 4.1.5.2 Topic

_Implemented_

#### 4.1.5.3 Comment

_Implemented_

## 4.2 Topic Services

BCF topics are tightly coupled to work packages in OpenProject. This coupling is denoted in the `reference_links` property
of a topic which will always have a link to the work package resource in the API v3. e.g.:

```
<-- other properties -->
"reference_links": [
 "/api/v3/work_packages/92"
],
<-- other properties -->
```

### 4.2.1 GET Topics Service

_Partly implemented_

The following properties are not supported:
* `labels` (the property exists but cannot be written and is always empty)
* `stage` (the property exists but cannot be written and is always null)
* `bim_snippet.snippet_type`
* `bim_snippet.is_external`
* `bim_snippet.reference`
* `bim_snippet.reference_schema`

OData sort, filtering and pagination is not supported.

### 4.2.2 POST Topic Service

_Partly implemented_

See [4.2.3 GET Topic Service](#423-get-topic-service) for details.

Either a new work package is created or, if a work package is referenced in the `reference_links` section, a the referenced
work package is associated to the newly created topic. A work package can only be associated to one topic and vice versa.

### 4.2.3 GET Topic Service

_Partly implemented_

See [4.2.3 GET Topic Service](#423-get-topic-service) for details.

### 4.2.4 PUT Topic Service

_Partly implemented_

The reference to the work package cannot be altered.

See [4.2.3 GET Topic Service](#423-get-topic-service) for details.

### 4.2.5 DELETE Topic Service

_Implemented_

The associated work package will also be deleted.

### 4.2.6 GET Topic BIM Snippet Service

_Not implemented_

### 4.2.7 PUT Topic BIM Snippet Service

_Not implemented_

## 4.3 File Services

### 4.3.1 GET Files (Header) Service

_Not implemented_

### 4.3.2 PUT Files (Header) Service

_Not implemented_

## 4.4 Comment Services

### 4.4.1 GET Comments Service

_Not implemented_

### 4.4.2 POST Comment Service

_Not implemented_

### 4.4.3 GET Comment Service

_Not implemented_

### 4.4.4 PUT Comment Service

_Not implemented_

### 4.4.5 DELETE Comment Service

_Not implemented_

### 4.4.6 Determining allowed Comment modifications

_Not implemented_

## 4.5 Viewpoint Services

### 4.5.1 GET Viewpoints Service

_Implemented_

### 4.5.2 POST Viewpoint Service

_Implemented_

#### 4.5.2.1 Point

_Implemented_

#### 4.5.2.2 Direction

_Implemented_

#### 4.5.2.3 Orthogonal camera

_Implemented_

#### 4.5.2.4 Perspective camera

_Implemented_

#### 4.5.2.5 Line

_Implemented_

#### 4.5.2.6 Clipping plane

_Implemented_

#### 4.5.2.7 Bitmap

_Implemented_

#### 4.5.2.8 Snapshot

_Implemented_

#### 4.5.2.9 Components

_Implemented_

#### 4.5.2.10 Component

_Implemented_

#### 4.5.2.11 Coloring

_Implemented_

#### 4.5.2.12 Visibility

_Implemented_

#### 4.5.2.13 View setup hints

_Implemented_

### 4.5.3 GET Viewpoint Service

_Implemented_

### 4.5.4 GET Viewpoint Snapshot Service

_Implemented_

### 4.5.6 GET selected Components Service

_Implemented_

### 4.5.7 GET colored Components Service

_Implemented_

### 4.5.8 GET visibility of Components Service

_Implemented_

## 4.6 Related Topics Services

### 4.6.1 GET Related Topics Service

_Not implemented_

### 4.6.2 PUT Related Topics Service

_Not implemented_

## 4.7 Document Reference Services

### 4.7.1 GET Document References Service

_Not implemented_

### 4.7.2 POST Document Reference Service

_Not implemented_

### 4.7.3 PUT Document Reference Service

_Not implemented_

## 4.8 Document Services

### 4.8.1 GET Documents Service

_Not implemented_

### 4.8.2 POST Document Service

_Not implemented_

### 4.8.3 GET Document Service

_Not implemented_

## 4.9 Topics Events Services

### 4.9.1 GET Topics Events Service

_Not implemented_

### 4.9.2 GET Topic Events Service

_Not implemented_

## 4.10 Comments Events Services

_Not implemented_

### 4.10.1 GET Comments Events Service

_Not implemented_

### 4.10.2 GET Comment Events Service

_Not implemented_
