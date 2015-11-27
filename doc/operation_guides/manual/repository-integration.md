# Repository Integration in OpenProject

OpenProject can (by default) browse Subversion and Git repositories, but it does not serve them to git/svn clients.

We do however support an integration with the Apache webserver to create and serve repositories on the fly, including integration into the fine-grained project authorization system of OpenProject.

## Existing Repositories

Using the default configuration, OpenProject allows you to *link* existing Subversion and Git repositories from the local filesystem (For Subversion, you can also integrate repositories from other servers using basic auth credentials).

When you link these repositories in OpenProject, you may browse the repository through OpenProject.

This functionality is extended with managed repositories, whose life spans are actively controlled by OpenProject. You can explicitly create local repositories for a project and configure repository access using permission the existing access-control functionality on a per-project level.

## Managed Repositories

You can create repositories explicitly on the filesystem using *managed* repositories.
Managed repositories need to be enabled manually for each SCM vendor individually using the `configuration.yml`.

It contains a YAML configuration section for repository management residing under the namespace `scm`.
The following is an excerpt of the configuration and contains all required information to set up your data.
	
	# Configuration of Source control vendors
	# client_command:
	#   Use this command to the default SCM vendor command (taken from path).
	#   Absolute path (e.g. /usr/local/bin/hg) or command name (e.g. hg.exe, bzr.exe)
	#   On Windows, *.cmd, *.bat (e.g. hg.cmd, bzr.bat) does not work.
	# manages:
	#   You may either specify a local path on the filesystem or an absolute URL to call when
	#   repositories are to be created or deleted.
	#   This allows OpenProject to take control over the given path to create and delete repositories
	#   directly when created in the frontend.
	#
	#   When entering a URL, OpenProject will POST to this resource when repositories are created
	#   using the following JSON-encoded payload:
	#     - action: The action to perform (create, delete)
	#     - identifier: The repository identifier name
	#     - vendor: The SCM vendor of the repository to create
	#     - project: identifier, name and ID of the associated project
	#     - old_identifier: The identifier to the old repository (used only during relocate)
	#
	#   NOTE: Disabling :managed repositories using disabled_types takes precedence over this setting.
	#
	# disabled_types:
	#   Disable specific repository types for this particular vendor. This allows
	#   to restrict the available choices a project administrator has for creating repositories
	#   See the example below for available types
	#
	#   Available types for git:
	#     - :local (Local repositories, registered using a local path)
	#     - :managed (Managed repositores, available IF :manages path is set below)
	#   Available types for subversion:
	#     - :existing (Existing subversion repositories by URL - local using file:/// or remote
	#                 using one of the supported URL schemes (e.g., https://, svn+ssh:// )
	#     - :managed (Managed repositores, available IF :manages path is set below)
	#
	# Examplary configuration (Enables managed Git repositories at the given path)
	scm:
	  git:
	    manages: /srv/repositories/git


With this configuration, you can create managed repositories by selecting the `managed` Git repository in the Project repository settings tab.

### Reposman.rb

Part of the managed repositories functionality was previously provided with reposman.rb.
Reposman periodically checked for new projects and automatically created a repository of a given type.
It never deleted repositories on the filesystem when their associated project was removed in OpenProject.

This script has been integrated into OpenProject and extended. If you previously used reposman, please see the [upgrade guide to 5.0](./upgrade-guide.md) for further guidance on how to migrate to managed repositories.

### Managing Repositories Remotely

OpenProject comes with a simple webhook to call other services rather than management repositories itself.
To enable remote managed repositories, simply pass an absolute URL to the `manages` key of a vendor in the `configuration.yml`. The following excerpt shows that configuration for Subversion, assuming your callback is `https://example.org/repos`.

	scm:
	  subversion:
	    manages: https://example.org/repos
	    accesstoken: <Fixed access token passed to the endpoint>

Upon creating and deleting repositories in the frontend, OpenProject will POST to this endpoint a JSON object containg information on the repository.

	{
		"identifier": "seeded_project.git",
		"vendor": "git",
		"scm_type": "managed",
		"project": {
			"id": 1,
			"name": "Seeded Project",
			"identifier": "seeded_project"
		},
		"action": "create",
		"token": <Fixed access token passed to the endpoint>
	}

The endpoint is expected to return a JSON with at least a `message` property when the response is not successful (2xx).
When the response is successful, it must at least return a `url` property that contains an accessible URL, an optionally, a `path` property to access the repository locally.
Note that for Git repositories, OpenProject currently can only read them locally (i.e, through an NFS mount), so a path is mandatory here.
For Subversion, you can either return a `file:///<path>` URL, or a local path.

Our main use-case for this feature is to reduce the complexity of permission issues around Subversion mainly in packager, for which a simple Apache wrapper script is used in `extra/Apache/OpenProjectRepoman.pm`.
This functionality is very limited, but may be extended when other use cases arise.
It supports notifications for creating repositories (action `create`), moving repositories (action `relocate`, when a project's identifier has changed), and deleting repositories (action `delete`).

If you're interested in setting up the integration manually outside the context of packager, the following excerpt will help you:

	
	PerlSwitches -I/srv/www/perl-lib -T
	PerlLoadModule Apache::OpenProjectRepoman
	
	<Location /repos>
	        SetHandler perl-script
	
	        # Sets the access token secret to check against
	        AccessSecret "<Fixed access token passed to the endpoint>"
	
	        # Configure pairs of (vendor, path) to the wrapper
	        PerlAddVar ScmVendorPaths "git"
	        PerlAddVar ScmVendorPaths "/srv/repositories/git"
	
	        PerlAddVar ScmVendorPaths "subversion"
	        PerlAddVar ScmVendorPaths "/srv/repositories/subversion"
	
	        PerlResponseHandler Apache::OpenProjectRepoman
	</Location>


## Other Features

OpenProject 5.0 introduces more features regarding repository management that we briefly outline in the following.

### Checkout instructions

OpenProject 5.0 also integrates functionality to display checkout instructions and URLs for Subversion and Git repositories.
This functionality is very basic and will probably be made more robust over the next releases.

* Checkout instructions may be configured globally for each vendor
* Checkout URLs are constructed from a base URL and the project identifier
* On the repository page, the user is provided with a button to show/expand checkout instructions on demand.
 * This checkout instruction contains the checkout URL for the given repository, and some further information on how the checkout works for this particular vendor (e.g., Subversion → svn checkout, Git → git clone).
 * The instructions may contain information regarding the capabilities a user has (read, read-write)
 * The instructions are defined by the SCM vendor implementations themselves, so that the checkout instructions may be extended by some 3rd party SCM vendor plugin

 
### Required Disk Storage Information

The total required disk space for a project (specifically, its repository and attachments) are listed in the projects administration pane, as well as the project setting overview.

This information is refreshed in the same manner that changesets are retrieved: By default, the repository is refreshed when a user visits the repository page. This information is cached for the time configured under the global `administration settings → repositories`.

You may also externally refresh this information using a cron job using the Sys API. Executing a GET against `/sys/projects/:identifier/repository/update_storage` will cause a refresh when the maximum cache time is expired. If you pass the query `?force=1` to the request above, it will ignore the cache.

For a future release, we are hoping to provide a webhook to update changesets and storage immediately after a change has been committed to the repository.

# Accessing repositories through Apache

With managed repositories, OpenProject takes care of the lifetime of repositories and their association with projects, however we still need to serve the repositories to the client.

## Preliminary Setup

In the remainder of this document, we assume that you run OpenProject but using a separate process, which listens for requests on http://localhost:3000 that you serve over Apache using a proxy.

We let Apache serve Subversion and git repositories (with the help of some modules) and
authenticate against the OpenProject user database.

Therefore we use an authentication perl script located in `extra/svn/OpenProjectAuthentication.pm`.
This script needs to be in your Apache perl path (for example it might be sym-linked into /etc/apache2/Apache).

To make the authentication work, you need to generate a secret repository API key, which you can generate in your OpenProject instance at `Modules → Administration → Settings → Repositories`.
On that page, enable  *"Enable repository management web service"* and generate an API key (do not
forget to save the settings). We need that API key later in our Apache configuration.

You also need a distinct filesystem path for Subversion and Git repositories.
In this guide, we assume that you put your svn repositories in /srv/openproject/svn and your git repositories in /srv/openproject/git .

## Subversion Integration

Apache provides the module `mod_dav_svn` to serve Subversion repositories through HTTP(s).

This method requires some apache modules to be enabled and installed. The following commands are required for Debian / Ubuntu, please adjust accordingly for other distributions:

<pre>
  apt-get install subversion libapache2-mod-perl2 libapache2-svn
  a2enmod proxy proxy_http dav dav_svn
</pre>

### Permissions

**Important:** If Apache and OpenProject run under separate users, you need to ensure OpenProject remains the owner of the repository in order to browse and delete it, when requsted through the user interface.

Due to the implementation of `mod_svn`, we have no way to influence the permissions determined by apache when changing repositories (i.e., by committing changes).
Without correcting the permissions, the following situation will occur:

* The run user of OpenProject can correctly create and manage repository under the managed path with appropriate permissions set
* As soon as a user checks out the repository and commits new data
  * Apache alters and adds files to the repository on the server, now owned by the apache user its default umask.
* If the user decides to delete the repository through the frontend
  * Altered files are not / no longer owned or writable by the OpenProject user
  * The deletion fails

The following workarounds exist:

#### Apache running `mod_dav_svn` and OpenProject must be run with the same user

This is a simple solution, but theoretically less secure when the server provides more than just SVN and OpenProject.

#### Use Filesystem ACLs

You can define ACLs on the managed repository root (requires compatible FS).
You'll need the the `acl` package and define the ACL.

Assuming the following situation:

* Apache run user / group: `www-data`
* OpenProject run user: `openproject`
* Repository path for SCM vendor X: `/srv/repositories/X`

    
		# Set existing ACL
		# Results in this ACL setting
		# user::rwx
		# user:www-data:rwx
		# user:deploy:rwx
		# group::r-x
		# group:www-data:rwx
		# mask::rwx
	
		setfacl -R -m u:www-data:rwx -m u: openproject:rwx -m d:m:rwx /srv/repositories/X
	
		# Promote to default ACL
		# Results in
		# default:user::rwx
		# default:user:www-data:rwx
		# default:user:deploy:rwx
		# default:group::r-x
		# default:group:www-data:rwx
		# default:mask::rwx
		# default:other::---
	
		setfacl -dR -m u:www-data:rwx -m u:openproject:rwx -m m:rwx /srv/repositories/X

		
On many file systems, ACLS are enabled by default. On others, you might need to remount affected filesystems with the `acl` option set.

Note that this issue applies to mod_dav_svn only.

### Use the Apache wrapper script

Similar to the integration we use ourselves for the packager-based installation, you can set up Apache to manage repositories using the remote hook in OpenProject.

For more information, see the section 'Managing Repositories Remotely'.

### Exemplary Apache Configuration

We provide an example apache configuration. Some details are explained inline as comments.

    # Load OpenProject per module used to authenticate requests against the user database.
    # Be sure that the OpenProjectAuthentication.pm script is located in your perl path.
    PerlSwitches -I/srv/www/perl-lib -T
    PerlLoadModule Apache::OpenProjectAuthentication
    
    <VirtualHost *:80>
      ErrorLog /var/log/apache2/error
    
      # The /sys endpoint is an internal API used to authenticate repository
      # access requests. It shall not be reachable from remote.
      <LocationMatch "/sys">
        Order Deny,Allow
        Deny from all
        Allow from 127.0.0.1
      </LocationMatch>
    
      # This fixes COPY for webdav over https
      RequestHeader edit Destination ^https: http: early
    
      # Serves svn repositories locates in /srv/openproject/svn via WebDAV
      # It is secure with basic auth against the OpenProject user database.
      <Location /svn>
        DAV svn
        SVNParentPath "/srv/openproject/svn"
        
        # Avoid listing available repositories
        SVNListParentPath Off
        
        # Prefer bulk updates for improved performance
        # Enable when SVN on server is >= 1.8
        # SVNAllowBulkUpdates Prefer
        
        # Avoid path-based authorization
        SVNPathAuthz Off
        
        # Caching options
        SVNInMemoryCacheSize 131072
        SVNCacheTextDeltas On
        SVNCacheFullTexts On
        
        DirectorySlash Off
    
        AuthType Basic
        AuthName "OpenProject Subversion Server"
        Require valid-user
    
        PerlAccessHandler Apache::Authn::OpenProject::access_handler
        PerlAuthenHandler Apache::Authn::OpenProject::authen_handler
    
        OpenProjectUrl 'http://127.0.0.1:3000'
        OpenProjectApiKey 'REPLACE WITH REPOSITORY API KEY'
    
        <Limit OPTIONS PROPFIND GET REPORT MKACTIVITY PROPPATCH PUT CHECKOUT MKCOL MOVE COPY DELETE LOCK UNLOCK MERGE>
          Allow from all
        </Limit>
        
        # Requires the apache module mod_proxy. Enable it with
        # a2enmod proxy proxy_http
        # See: http://httpd.apache.org/docs/2.2/mod/mod_proxy.html#ProxyPass
        # Note that the ProxyPass with the longest path should be listed first, otherwise
        # a shorter path may match and will do an early redirect (without looking for other
        # more specific matching paths).
        ProxyPass /svn !
        ProxyPass / http://127.0.0.1:3000/
        ProxyPassReverse / http://127.0.0.1:3000/        
      </Location>

## Git Integration

We can exploit git-http-backend to serve Git repositories through HTTP(s) with Apache.

This method additionally requires the `cgi` Apache module to be installed. The following commands are required for Debian / Ubuntu, please adjust accordingly for other distributions:

<pre>
  apt-get install git libapache2-mod-perl2
  a2enmod proxy proxy_http cgi
</pre>

You need to locate the location of the `git-http-backend` CGI wrapper shipping with the Git installation.
Depending on your installation, it may reside in `/usr/libexec/git-core/git-http-backend`.

[More information on git-http-backend.](http://git-scm.com/docs/git-http-backend)

### Permissions

We create bare Git repositories in OpenProject with the [`--shared`](https://www.kernel.org/pub/software/scm/git/docs/git-init.html) option of `git-init` set to group-writable.
Thus, if you use a separate user for Apache and OpenProject, they need to reside in a common group that is used for repository management. That group must be set in the `configuration.yml` (see above).

### Exemplary Apache Configuration

We provide an example apache configuration. Some details are explained inline as comments.

    # Load OpenProject per module used to authenticate requests against the user database.
    # Be sure that the OpenProjectAuthentication.pm script is located in your perl path.
    PerlSwitches -I/srv/www/perl-lib -T
    PerlLoadModule Apache::OpenProjectAuthentication
    
    <VirtualHost *:80>
      ErrorLog /var/log/apache2/error
    
      # The /sys endpoint is an internal API used to authenticate repository
      # access requests. It shall not be reachable from remote.
      <LocationMatch "/sys">
        Order Deny,Allow
        Deny from all
        Allow from 127.0.0.1
      </LocationMatch>
    
      # This fixes COPY for webdav over https
      RequestHeader edit Destination ^https: http: early
    
      # Serves svn repositories locates in /srv/openproject/svn via WebDAV
      # It is secure with basic auth against the OpenProject user database.
      <Location /svn>
        DAV svn
        SVNParentPath "/srv/openproject/svn"
        DirectorySlash Off
    
        AuthType Basic
        AuthName "Secured Area"
        Require valid-user
    
        PerlAccessHandler Apache::Authn::OpenProject::access_handler
        PerlAuthenHandler Apache::Authn::OpenProject::authen_handler
    
        OpenProjectUrl 'http://127.0.0.1:3000'
        OpenProjectApiKey 'REPLACE WITH REPOSITORY API KEY'
    
        <Limit OPTIONS PROPFIND GET REPORT MKACTIVITY PROPPATCH PUT CHECKOUT MKCOL MOVE COPY DELETE LOCK UNLOCK MERGE>
          Allow from all
        </Limit>
      </Location>
    
      # see https://www.kernel.org/pub/software/scm/git/docs/git-http-backend.html for details
      # needs mod_cgi to work -> a2enmod cgi
      SetEnv GIT_PROJECT_ROOT /srv/openproject/git
      SetEnv GIT_HTTP_EXPORT_ALL
      ScriptAlias /git/ /usr/lib/git-core/git-http-backend/
      <Location /git>
        Order allow,deny
        Allow from all
    
        AuthType Basic
        AuthName "OpenProject GIT"
        Require valid-user
    
        PerlAccessHandler Apache::Authn::OpenProject::access_handler
        PerlAuthenHandler Apache::Authn::OpenProject::authen_handler
    
        OpenProjectGitSmartHttp yes
        OpenProjectUrl 'http://127.0.0.1:3000'
        OpenProjectApiKey 'REPLACE WITH REPOSITORY API KEY'
      </Location>
    
      # Requires the apache module mod_proxy. Enable it with
      # a2enmod proxy proxy_http
      # See: http://httpd.apache.org/docs/2.2/mod/mod_proxy.html#ProxyPass
      # Note that the ProxyPass with the longest path should be listed first, otherwise
      # a shorter path may match and will do an early redirect (without looking for other
      # more specific matching paths).
      ProxyPass /svn !
      ProxyPass /git !
      ProxyPass / http://127.0.0.1:3000/
      ProxyPassReverse / http://127.0.0.1:3000/
    </VirtualHost>


## Other integrations

With OpenProject 5.0, the interface to create custom integrations for other SCM vendors was improved dramatically.

If you're interested in writing a custom integration for some other SCM vendor (such as Mercurial), feel free to contact the developers of OpenProject over Github.

One examplary integration is the Gitolite plugin, which serves Git repositories from OpenProject over SSH using [Gitolite](http://www.gitolite.com).
The plugin is available at https://github.com/oliverguenther/openproject-revisions_git.
