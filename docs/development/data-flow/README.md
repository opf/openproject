# Data flow and usage

Regardless of the type of installation of OpenProject, the following diagram provides a high-level overview of through which systems data related to OpenProject is flowing.



```mermaid
%%{init: {'theme':'neutral'}}%%

flowchart TD
  A[Client Browser] -->|"HTTP(s) requests"| B(Load Balancer / Proxy)
  A1[API or Native clients] -->|"HTTP(s) requests"| B(Load Balancer / Proxy)
  A2[SVN or Git clients] -->|"HTTP(s) requests"| B(Load Balancer / Proxy)
  B -->|Proxy| openproject

  subgraph openproject[OpenProject]
    C[Puma app server]
    D[Background worker]
  end


  subgraph integrations[External integrations]
	  O[Other integrations]
    N[Nextcloud]
  end

  subgraph services[Services]
  	M[memcached]
	  P[PostgreSQL]
	  S[Object storage or NFS]
  end


  openproject <--> services
  openproject --> integrations
  B <--> integrations

```

As a web application, the primary data flow is between the Client browser (or attached API clients) through an external proxying web server (this might be a load balancer or proxying server). We're assuming it is the one responsible for terminating TLS connections for the course of this document - although encrypted connections between Load balancer and Puma server are possible. In case of packaged or kubernetes installations, this proxying server might be part of the OpenProject stack (e.g., an Apache2 packaged installation server or nginx ingress).

The external web server acts as a proxy/reverse-proxy for the OpenProject Puma application server, relaying requests for it to handle and respond. In the course of the request, access to external services such as the PostgreSQL database, a caching server, or attached storages might be performed. In case of S3-compatible object storage set ups, OpenProject performs calls to the object storage to put or request files from it. Likewise, for network-attached storages linked into the application, underlying network requests are performed. These are out of scope for this evaluation, as they are provided and maintained by the operator of the system.

In the course of using the application, background tasks are enqueued in the database such as outgoing emails, cleanup tasks, or notification processing. These tasks are performed in a separate process, the background worker queue. This process accesses the same services as the application server process to access or modify data. It might connect to external integrations such as a Nextcloud instance to set up file sharings depending on actions performed by the users.



## Exemplary request flow

- **User request**: An end-user sends an HTTPS request to the load balancer or proxying server.

- **Load balancer**: The external load balancer or proxying server receives the request, terminates TLS, and forwards the HTTP request to the Puma application server.

- **Puma server**: Processes the request and invokes the appropriate Rails middlewares and controller.

- **Rails application**:

  - Authenticates the user according to the mechanisms outlined in the [secure coding guidelines](../concepts/secure-coding)
  - Validates session and input data
  - Responsible for error handling, logging, and auditing aggregation

  - Retrieves or updates resources to the PostgreSQL database via models
  - Calls or interacts with external services for requests, such as retrieving files or attachments from object storage

  - Renders the appropriate views

- **Response**: Sends the HTTP response back through the Puma server and load balancer to the end-user.

- **Background worker:** Operate on periodical background data, or perform actions requested by the web request of user (sending emails, exporting data, communicating with external services)



## Schema information

OpenProject's database schema is considered an internal API, please do not rely on it as a stable point of references. Schema modifications by the OpenProject core might be performed in any upgrade, including patch releases. Modifications to the database schema are considered a third-party customization and might prevent us from giving proper support. If you have an active support contract with OpenProject, please note that modifications affect our warranty. For more information, please consult the [Terms of Services](https://www.openproject.org/legal/terms-of-service/#-5-warranty).

We recommend you use existing database tools to inspect and export the database as an ERD. That being said, we've prepared an export of an ERD of the current state of the database. Note that this diagram is not regularly updated. Use tools like IntelliJ database explorer or [mermerd](https://github.com/KarnerTh/mermerd) to generate a live ERD of your database set up instead.

[![OpenProject database schema ERD](openproject-erd.jpg)](openproject-erd.jpg)



# Use of technical cookies

OpenProject makes use of technical cookies to identity the browser client and/or remember information such as 2FA login state. The core application makes use of these cookies:

| **Cookie name**                                | **Description**                                              | **Expiry**                                                   | **Security flags**                                    | **Implementation**                                           |
| ---------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ----------------------------------------------------- | ------------------------------------------------------------ |
| `_open_project_session` (name is configurable) | contains the information about the logged in user as well as information stored between requests on the user's choices (e.g. the filters for costs are in part stored there) | Session <br />+ configurable server-sideTTL                  | secure<br />httponly<br />Samesite=Lax<br />encrypted | [Code ref](https://github.com/opf/openproject/blob/release/13.0/config/initializers/session_store.rb#L34-L39) |
| `autologin` (name is configurable)             | (Optional feature, requires opt-in under Administration > Authentication settings) <br />enables the user to automatically log in again after the session expired (e.g. because the browser was closed). It is set when the user checks the '*Stay logged in*' box in the login form.<br /> | Cookie 1 year<br />+ server-side token N days (configurable) | secure<br />httponly<br />Samesite=Lax<br />encrypted | [Code ref](https://github.com/opf/openproject/blob/release/13.0/app/controllers/concerns/accounts/user_login.rb#L19C1-L29) |
| `op2fa_remember_token`                         | the presence of that cookie suppresses the need for the user to provide a second factor upon login for N days (configurable by administration) if the user selects to do so when entering the 2fa information. | N days (configurable)                                        | secure<br />httponly<br />Samesite=Lax<br />encrypted | [Code ref](https://github.com/opf/openproject/blob/release/13.0/modules/two_factor_authentication/app/controllers/concerns/two_factor_authentication/remember_token.rb#L28-L34) |



On top of that, for cloud instances:

- `openproject_cloud_instances` contains a list of instances the user recently accessed.
- additional technical cookies might be set by the load balancer and intermediate processes (i.e., to remember a sticky load balancer and ensuring subsequent requests are routed similarly).



# Processing of Personally Identifiable Information

As OpenProject is dealing with user account data, it is processing personally identifiable information (PII). This data encompasses:

- User's first and last name
- E-Mail address(es)
- Other uniquely identifiable information used as authentication data of external identity providers (such as SAML or OpenID Connect)
- User pictures / Avatars
- IP addresses in log files
- Possibly data that is filled as part of user custom fields, configurable data fields shown and editable for users. The content of these fields are user-provided and not systematically processed by OpenProject however.



Affected services:

- PostgreSQL database (stores user account data)
- Object storage or NFS (stores user pictures as files)
- Memcached (Might contain references to cached information of user data)



## Deletion and Anonymization of PII

Whenever users in OpenProject are fully deleted, the system scrubs and removes all structural PII. For more information on user account deletion, please see [the user administration guide](../../system-admin-guide/users-permissions/users/#delete-users).

Deleting a user account is a permanent action and cannot be reversed. All actions performed in the name of the user are being scrubbed and replaced with a singular "Deleted user" reference in order to maintain integrity of database references, such as being an author of a work package that remains. Finally, the user data itself will be deleted, removing all structural traces of PII in the system. Due to the user references changing, respective cache keys for information such as work packages or projects are invalidated automatically. Note that user-input data such as text or comments cannot be deleted or scrubbed in an automated fashion.

Log files might still retain PII data of the user for the configured retention period. Memory references in memcached might still refer to (invalidated) user data until it is being reassigned.
