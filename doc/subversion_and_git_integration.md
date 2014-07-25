# Subversion and Git Integration

OpenProject can (by default) browse subversion and git repositories.
But it does not serves them to git/svn clients.

However, with the help of the apache webserver it is possible to serve repositories.

## Set-up

OpenProject should run integrated in your apache setup. This can be done in several ways
(for example by using the passenger module).
In this document we assume that you run OpenProject using a separate process, which listens
for requests on http://localhost:3000.

We let apache serve svn and git repositories (with the help of some modules) and
authenticate against the OpenProject user database.
Therefore we use an authentication perl script located in extra/svn/OpenProjectAuthentication.pm .

It requires some apache modules to be enabled and installed:

<pre>
  aptitude install libapache2-mod-perl2 libapache2-svn
  a2enmod proxy proxy_http
</pre>

Also, the extra/svn/OpenProjectAuthentication.pm script needs to be in your apache perl path
(for example it might be sym-linked into /etc/apache2/Apache).

To make the authentication work, you need to generate a secret repository API key. To do this, open
your OpenProject installation in your favourite web browser, log in as an administrator and go to
Modules -> Administration -> Settings -> Repositories.
On that page, enable the "Enable WS for repository management" setting and generate an API key (do not
for get to save the settings). We need that API key later in our apache config.

Find a place to store the repositories. For this guide we assume that you put your svn repositories in
/srv/openproject/svn . All things in that repository should be accessible by the apache system user and
by the user running your openproject server. 

## An example apache configuration

We provide an example apache configuration. Some details are explained inline as comments.

<pre>
# Load OpenProject per module used to authenticate requests against the user database.
# Be sure that the OpenProjectAuthentication.pm script in located in your perl path.
PerlSwitches -I/srv/www/perl-lib -T
PerlLoadModule Apache::OpenProjectAuthentication

&lt;VirtualHost *:80&gt;
  ErrorLog /var/log/apache2/error

  # The /sys endpoint is an internal API used to authenticate repository
  # access requests. It shall not be reachable from remote.
  &lt;LocationMatch "/sys"&gt;
    Order Deny,Allow
    Deny from all
    Allow from 127.0.0.1
  &lt;/LocationMatch&gt;

  # This fixes COPY for webdav over https
  RequestHeader edit Destination ^https: http: early

  # Serves svn repositories locates in /srv/openproject/svn via WebDAV
  # It is secure with basic auth against the OpenProject user database.
  &lt;Location /svn&gt;
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

    &lt;Limit OPTIONS PROPFIND GET REPORT MKACTIVITY PROPPATCH PUT CHECKOUT MKCOL MOVE COPY DELETE LOCK UNLOCK MERGE&gt;
      Allow from all
    &lt;/Limit&gt;
  &lt;/Location&gt;

  # Requires the apache module mod_proxy. Enable it with
  # a2enmod proxy proxy_http
  # See: http://httpd.apache.org/docs/2.2/mod/mod_proxy.html#ProxyPass
  # Note that the ProxyPass with the longest path should be listed first, otherwise
  # a shorter path may match and will do an early redirect (without looking for other
  # more specific matching paths).
  ProxyPass /svn !
  ProxyPass / http://127.0.0.1:3000/
  ProxyPassReverse / http://127.0.0.1:3000/
&lt;/VirtualHost&gt;
</pre>

## Automatically create repositories with reposman.rb

The reposman.rb script can create repositories for your newly created OpenProject projects.
It is useful when run from a cron job (so that repositories appear 'magically' some time after you created
a project in the OpenProject administration view).

<pre>
ruby extra/svn/reposman.rb \
  --openproject-host "http://127.0.0.1:3000" \
  --owner "www-data" \
  --group "openproject" \
  --public-mode '2750' \
  --private-mode '2750' \
  --svn-dir "/srv/openproject/svn" \
  --url "file:///srv/openproject/svn" \
  --key "REPLACE WITH REPOSITORY API KEY" \
  --scm Subversion \
  --verbose
</pre>

