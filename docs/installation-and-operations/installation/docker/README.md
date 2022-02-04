---
sidebar_navigation:
  title: Docker
  priority: 300
---

# Install OpenProject with Docker

[Docker](https://www.docker.com/) is a way to distribute self-contained applications easily. We
provide a Docker image for the Community Edition that you can very easily
install and upgrade on your servers. However, contrary to the manual or
package-based installation, your machine needs to have the Docker Engine
installed first, which usually requires a recent operating system. Please see
the [Docker Engine installation page](https://docs.docker.com/install) if you don't have Docker
installed.

OpenProject with Docker can be launched in two ways:

1. Multiple containers (recommended), each with a single process inside, using a Compose file. Allows to easily choose which services you want to run, and simplifies scaling and monitoring aspects.

2. One container with all the processes inside. Easy but not recommended for production. This is the legacy behaviour.

## One container per process (recommended)

### Quick Start

First, you must clone the [openproject-deploy](https://github.com/opf/openproject-deploy/tree/stable/12/compose) repository:

```bash
git clone https://github.com/opf/openproject-deploy --depth=1 --branch=stable/12 openproject
```

Then, go into the compose folder:

```bash
cd openproject/compose
```

Make sure you are using the latest version of the Docker images:

```bash
docker-compose pull
```

Launch the containers:

```bash
docker-compose up -d
```

After a while, OpenProject should be up and running on <http://localhost:8080>. The default username and password is login: `admin`, and password: `admin`.

Note that the `docker-compose.yml` file present in the repository can be adjusted to your convenience. For instance you could mount specific configuration files, override environment variables, or switch off services you don't need. Please refer to the official [Docker Compose documentation](https://docs.docker.com/compose/extends/) for more details.

You can stop the Compose stack by running:

```
docker-compose down
```

## All-in-one container

### Quick Start

The fastest way to get an OpenProject instance up and running is to run the
following command:

```bash
docker run -it -p 8080:80 -e SECRET_KEY_BASE=secret openproject/community:12
```

This will take a bit of time the first time you launch it, but after a few
minutes you should see a success message indicating the default administration
password (login: `admin`, password: `admin`).

You can then launch a browser and access your new OpenProject installation at
<http://localhost:8080>. Easy!

To stop the container, simply hit CTRL-C.

Note that the above command will not daemonize the container and will display
the logs to your terminal, which helps with debugging if anything goes wrong.
For normal usage you probably want to start it in the background, which can be
achieved with the `-d` flag:

```bash
docker run -d -p 8080:80 -e SECRET_KEY_BASE=secret openproject/community:12
```

**Note**: We've had reports of people being unable to start OpenProject this way
because of an [issue regarding pseudo-TTY allocations](https://github.com/moby/moby/issues/31243#issuecomment-406825071)
and permissions to write to `/dev/stdout`. If you run into this, a workaround
seems to be to add `-t` to your run command, even if you run in detached mode.

## Using this container in production

The one-liner above is great to get started quickly, but we strongly advise against
using this setup for production purposes.

Also, if you want to run OpenProject in production you need to ensure that your data is not
lost if you restart the container.

To achieve this, we recommend that you create a directory on your host system
where the Docker Engine is installed (for instance: `/var/lib/openproject`)
where all this data will be stored.

You can use the following commands to create the local directories where the
data will be stored across container restarts, and start the container with
those directories mounted:

```bash
sudo mkdir -p /var/lib/openproject/{pgdata,assets} 

docker run -d -p 8080:80 --name openproject \
  -e SERVER_HOSTNAME=openproject.example.com \ # The public facing host name
  -e SECRET_KEY_BASE=secret \ # The secret key base used for cookies
  -v /var/lib/openproject/pgdata:/var/openproject/pgdata \
  -v /var/lib/openproject/assets:/var/openproject/assets \
  openproject/community:12
```

Please make sure you set the correct public facing hostname in `SERVER_HOSTNAME`. If you don't have a load-balancing or proxying web server in front of your docker container,
you will otherwise be vulnerable to [HOST header injections](https://portswigger.net/web-security/host-header), as the internal server has no way of identifying the correct host name.

**Note**: Make sure to replace `secret` with a random string. One way to generate one is to run `head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo ''` if you are on Linux.

**Note**: MacOS users might encounter an "Operation not permitted" error on the mounted directories. The fix for this is to create the two directories in a user-owned directory of the host machine.

Since we named the container, you can now stop it by running:

```bash
docker stop openproject
```

And start it again:

```bash
docker start openproject
```

If you want to destroy the container, run the following commands

```bash
docker stop openproject
docker rm openproject
```

### Initial configuration

OpenProject is usually configured through a YAML file, but with the Docker
image you need to pass all configuration through environment variables. You can
overwrite any of the values usually found in the standard YAML file by using
[environment variables](../../configuration/environment).

Environment variables can be either passed directly on the command-line to the
Docker Engine, or via an environment file:

```bash
docker run -d -e KEY1=VALUE1 -e KEY2=VALUE2 ...
# or
docker run -d --env-file path/to/file ...
```

For more advanced configuration, please have a look at the [Advanced configuration](../../configuration) section.

### Apache Reverse Proxy Setup

The containers above are not meant as public facing endpoints. Always use an existing proxying web server or load balancer to provide access to OpenProject

There are two ways to run OpenProject. We'll cover each configuration in a separate of the following sections.

For both configurations the following Apache mods are required:

* proxy
* proxy_http
* rewrite
* ssl (optional)

In each case you will create a file `/usr/local/apache2/conf/sites/openproject.conf`
with the contents as described in the respective sections.

Both configuration examples are based on the following assumptions:

* the site is accessed via https
* certificate and key are located under `/etc/ssl/crt/server.{crt, key}`
* the OpenProject docker container's port 80 is mapped to the docker host's port 8080

*Important:* Once OpenProject is running make sure to also set the host name and protocol
accordingly under Administration -> System Settings.

#### 1) Virtual host root

The default scenario is to have OpenProject serve the whole virtual host.
This requires no further configuration for the docker container beyond what is
described above.

Assuming the desired *server name* is `openproject.example.com` the configuration
will look like this:

```
<VirtualHost *:80>
    ServerName openproject.example.com

    RewriteEngine on
    RewriteCond %{HTTPS} !=on
    RewriteRule ^/?(.*)$ https://%{SERVER_NAME}/$1 [R,L]
</VirtualHost>

<VirtualHost *:443>
    ServerName openproject.example.com

    SSLEngine on
    SSLCertificateFile /etc/ssl/crt/server.crt
    SSLCertificateKeyFile /etc/ssl/crt//server.key

    RewriteEngine on
    RewriteRule "^$" "/" [R,L]

    ProxyRequests off

    <Location "/">
      RequestHeader set X-Forwarded-Proto 'https'

      ProxyPreserveHost On
      ProxyPass http://127.0.0.1:8080/
      ProxyPassReverse http://127.0.0.1:8080/
    </Location>
</VirtualHost>
```

#### 2) Location (subdirectory)

Let's assume you want OpenProject to run on your host with the *server name* `example.com`
under the *subdirectory* `/openproject`.

If you want to run OpenProject in a subdirectory on your server, first you will
need to configure OpenProject accordingly by adding the following options to the `docker run` call:

```
-e OPENPROJECT_RAILS__RELATIVE__URL__ROOT=/openproject \
-e OPENPROJECT_RAILS__FORCE__SSL=true \
```

The `force ssl` option can be left out if you are not using HTTPS.

The apache configuration for this configuration then looks like this:

```
<VirtualHost *:80>
    ServerName example.com

    RewriteEngine on
    RewriteCond %{HTTPS} !=on
    RewriteRule ^/?(openproject.*)$ https://%{SERVER_NAME}/$1 [R,L]
</VirtualHost>

<VirtualHost *:443>
    ServerName example.com

    SSLEngine on
    SSLCertificateFile /etc/ssl/crt/server.crt
    SSLCertificateKeyFile /etc/ssl/crt/server.key

    RewriteEngine on
    RewriteRule "^/openproject$" "/openproject/" [R,L]

    ProxyRequests off

    <Location "/openproject/">
      RequestHeader set X-Forwarded-Proto 'https'

      ProxyPreserveHost On
      ProxyPass http://127.0.0.1:8080/openproject/
      ProxyPassReverse http://127.0.0.1:8080/openproject/
    </Location>
</VirtualHost>
```

### OpenProject plugins

The docker image itself does not support plugins. But you can create your own docker image to include plugins.

**1. Create a new folder** with any name, for instance `custom-openproject`. Change into that folder.

**2. Create the file `Gemfile.plugins`** in that folder. In the file you declare the plugins you want to install.
For instance:

```
group :opf_plugins do
  gem "openproject-slack", git: "https://github.com/opf/openproject-slack.git", branch: "release/12.0"
end
```

**3. Create the `Dockerfile`** in the same folder. The contents have to look like this:

```
FROM openproject/community:12

# If installing a local plugin (using `path:` in the `Gemfile.plugins` above),
# you will have to copy the plugin code into the container here and use the
# path inside of the container. Say for `/app/vendor/plugins/openproject-slack`:
# COPY /path/to/my/local/openproject-slack /app/vendor/plugins/openproject-slack

COPY Gemfile.plugins /app/

# If the plugin uses any external NPM dependencies you have to install them here.
# RUN npm add npm <package-name>*

RUN bundle config unset deployment && bundle install && bundle config set deployment 'true'
RUN ./docker/prod/setup/postinstall.sh
```

The file is based on the normal OpenProject docker image.
All the Dockerfile does is copy your custom plugins gemfile into the image, install the gems and precompile any new assets.

**4. Build the image**

To actually build the docker image run:

```
docker build -t openproject-with-slack .
```

The `-t` option is the tag for your image. You can choose what ever you want.

**5. Run the image**

You can run the image just like the normal OpenProject image (as shown earlier).
You just have to use your chosen tag instead of `openproject/community:12`.
To just give it a quick try you can run this:

```
docker run -p 8080:80 --rm -it openproject-with-slack
```

After which you can access OpenProject under http://localhost:8080.

## Offline/air-gapped installation

It's possible to run the docker image on an a system with no internet access using `docker save` and `docker load`.
The installation works the same as described above. The only difference is that you don't download the image the usual way.

**1) Save the image**

On a system that has access to the internet run the following.

```
docker pull openproject/community:12 && docker save openproject/community:12 | gzip > openproject-12.tar.gz
```

This creates a compressed archive containing the latest OpenProject docker image.
The file will have a size of around 700mb.

**2) Transfer the file onto the system**

Copy the file onto the target system by any means that works.
This could be sftp, scp or even via a USB stick in case of a truly air-gapped system.

**3) Load the image**

Once the file is on the system you can load it like this:

```
gunzip openproject-12.tar.gz && docker load -i openproject-12.tar
```

This extracts the archive and loads the contained image layers into docker.
The .tar file can be deleted after this.

**4) Proceed with the installation**

After this both installation and later upgrades work just as usual.
You only replaced `docker-compose pull` or the normal, implicit download of the image with the steps described here.

## Docker Swarm

If you need to serve a very large number of users it's time to scale up horizontally.
One way to do that is to use your orchestration tool of choice such as [Kubernetes](../kubernetes/) or [Swarm](https://docs.docker.com/engine/swarm/).
Here we'll cover how to scale up using the latter.

### 1) Setup Swarm

Here we will go through a simple setup of a Swarm with a single manager.
For more advanced setups and more information please consult the [docker swarm documentation](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/).

First [initialize your swarm](https://docs.docker.com/get-started/swarm-deploy/) on the host you wish to be the swarm manager.

```bash
docker swarm init
# You may need or want to specify the advertise address.
# Say your node manager host's IP is 10.0.2.77:
#
#   docker swarm init --advertise-addr=10.0.2.77
```

The host will automatically also join the swarm as a node to host containers.

**Add nodes**

To add worker nodes run `docker swarm join-token worker`.
This will print the necessary command (which includes the join token) which you need to run
on the host you wish to add as a worker node. For instance:

```bash
docker swarm join --token SWMTKN-1-2wnvro17w7w2u7878yflajyjfa93e8b2x58g9c04lavcee93eb-abig91iqb6e5vmupfvq2f33ni 10.0.2.77:2377
```

Where `10.0.2.77` is your swarm manager's (advertise) IP address.

### 2) Setup shared storage

**Note:** This is only relevant if you have more than 1 node in your swarm.

If your containers run distributed on multiple nodes you will need a shared network storage to store OpenProject's attachments.
The easiest way for this would be to setup an NFS drive that is shared among all nodes and mounted to the same path on each of them.
Say `/mnt/openproject/`.

Alternatively, if using S3 is an option, you can use S3 attachments instead.
We will show both possibilities later in the configuration.

### 3) Create stack

To create a stack you need a stack file. The easiest way is to just copy OpenProject's [docker-compose.yml](https://github.com/opf/openproject/blob/release/12.0/docker-compose.yml). Just download it and save it as, say, `openproject-stack.yml`.

#### Configuring storage

**Note:** This is only necessary if your swarm runs on multiple nodes.

##### Attachments

###### NFS

If you are using NFS to share attachments use a mounted docker volume to share the attachments folder.

Per default the YAML file will include the following section:

```yaml
x-op-app: &app
  <<: *image
  <<: *restart_policy
  environment:
    # ...
  volumes:
    - "opdata:/var/openproject/assets"
  depends_on:
    # ...
```

As you can see it already mounts a local directory by default.
You can either change this to a path in your mounted NFS folder or just create a symlink:

```
ln -s /mnt/openproject/assets /var/openproject/assets
```

###### AWS S3

If you want to use S3 you will need to add the following configuration to the `app` section of `stack.yml`.

```yaml
x-op-app: &app
  <<: *image
  <<: *restart_policy
  environment:
    ...
    OPENPROJECT_ATTACHMENTS__STORAGE: "fog"
    OPENPROJECT_FOG_DIRECTORY: "«s3-bucket-name»"
    OPENPROJECT_FOG_CREDENTIALS_PROVIDER: "AWS"
    OPENPROJECT_FOG_CREDENTIALS_AWS__ACCESS__KEY__ID: "«access-key-id»" 
    OPENPROJECT_FOG_CREDENTIALS_AWS__SECRET__ACCESS__KEY: "«secret-access-key»" 
    OPENPROJECT_FOG_CREDENTIALS_REGION: "«us-east-1»" # Must be the region that you created your bucket in
```

###### MinIO S3

If you want to use MinIO as a self-hosted S3-compliant storage backend you will need to add the following configuration to the `app` section of `stack.yml`.

```yaml
x-op-app: &app
  <<: *image
  <<: *restart_policy
  environment:
    ...
    OPENPROJECT_ATTACHMENTS__STORAGE: "fog"
    OPENPROJECT_FOG_DIRECTORY: "«s3-bucket-name»"
    OPENPROJECT_FOG_CREDENTIALS_PROVIDER: "aws" # Minio is S3 compliant, so we can use the AWS provider
    OPENPROJECT_FOG_CREDENTIALS_ENDPOINT: "«https://minio-host.domain.tld»" # URI for your MinIO instance
    OPENPROJECT_FOG_CREDENTIALS_AWS__ACCESS__KEY__ID: "«access-key-id»" 
    OPENPROJECT_FOG_CREDENTIALS_AWS__SECRET__ACCESS__KEY: "«secret-access-key»" 
    OPENPROJECT_FOG_CREDENTIALS_PATH__STYLE: "true"
```

##### Database

The database's data directory should also be shared so that the database service can be moved to another node
in case the original node fails. The easiest way to do this would again be a shared NFS mount present on each node.
This is also the easiest way to persist the database data so it remains even if you shutdown the whole stack.

You could either use a new mounted NFS folder or use a sub-folder in the one we will use for attachments.
Along the same lines as attachments you could adjust the `pgdata` volume in the `openproject-stack.yml` so it would look something like this:

```yaml
x-op-app: &app
  <<: *image
  <<: *restart_policy
  environment:
    # ...
  volumes:
    - "pgdata:/mnt/openproject/pgdata"
    - "opdata:/mnt/openproject/assets"
  depends_on:
    # ...
```

**Disclaimer**: This may not be the best possible solution, but it is the most straight-forward one.

#### OpenProject Configuration

Any additional configuration of OpenProject happens in the environment section (like for S3 above) of the app inside of the `openproject-stack.yml`.
For instance should you want to disable an OpenProject module globally, you would add the following:

```
x-op-app: &app
  <<: *image
  <<: *restart_policy
  environment:
    # ...
    - "OPENPROJECT_DISABLED__MODULES='backlogs meetings'"
```

Please refer to our documentation on the [configuration](../../configuration/)
and [environment variables](../../configuration/environment/) for further information
on what you can configure and how.

#### Launching

Once you made any necessary adjustments to the `openproject-stack.yml` you are ready to launch the stack.

```
docker stack deploy -c openproject-stack.yaml openproject
```

Once this has finished you should see something like this when running `docker service ls`:

```
docker service ls
ID                  NAME                 MODE                REPLICAS            IMAGE                      PORTS
kpdoc86ggema        openproject_cache    replicated          1/1                 memcached:latest           
qrd8rx6ybg90        openproject_cron     replicated          1/1                 openproject/community:12   
cvgd4c4at61i        openproject_db       replicated          1/1                 postgres:10                
uvtfnc9dnlbn        openproject_proxy    replicated          1/1                 openproject/community:12   *:8080->80/tcp
g8e3lannlpb8        openproject_seeder   replicated          0/1                 openproject/community:12   
canb3m7ilkjn        openproject_web      replicated          1/1                 openproject/community:12   
7ovn0sbu8a7w        openproject_worker   replicated          1/1                 openproject/community:12
```

You can now access OpenProject under [http://0.0.0.0:8080](http://0.0.0.0:8080).
This endpoint then can be used in a apache reverse proxy setup as shown further up, for instance.

Don't worry about one of the services (openproject_seeder) having 0/1 replicas.
That is intended. The service will only start once to initialize the seed data and then stop.

#### Scaling

Now the whole reason we are using swarm is to be able to scale.
This is now easily done using the `docker service scale` command.

We'll keep the database and memcached at 1 which should be sufficient for any but huge amounts of users (several tens of thousands of users)
assuming that the docker hosts (swarm nodes) are powerful enough.
Even with the database's data directory shared via NFS **you cannot scale up the database** in this setup.
Scaling the database horizontally adds another level of complexity which we won't cover here.

What we can scale is both the proxy, and most importantly the web service.
For a couple of thousand users we may want to use 6 web service (`openproject_web`) replicas.
The proxy processes (`openproject_proxy`) in front of the actual OpenProject process does not need as many replicas.
2 are fine here.

Also at least 2 worker (`openproject_worker`) replicas make sense to handle the increased number of background tasks.
If you find that it takes too long for those tasks (such as sending emails or work package exports) to complete
you may want to increase this number further.

```
docker service scale openproject_proxy=2 openproject_web=6 openproject_worker=2
```

This will take a moment to converge. Once done you should see something like the following when listing the services using `docker service ls`:

```
docker service ls
ID                  NAME                 MODE                REPLICAS            IMAGE                      PORTS
kpdoc86ggema        openproject_cache    replicated          1/1                 memcached:latest           
qrd8rx6ybg90        openproject_cron     replicated          1/1                 openproject/community:12   
cvgd4c4at61i        openproject_db       replicated          1/1                 postgres:10                
uvtfnc9dnlbn        openproject_proxy    replicated          2/2                 openproject/community:12   *:8080->80/tcp
g8e3lannlpb8        openproject_seeder   replicated          0/1                 openproject/community:12   
canb3m7ilkjn        openproject_web      replicated          6/6                 openproject/community:12   
7ovn0sbu8a7w        openproject_worker   replicated          1/1                 openproject/community:12
```

Docker swarm handles the networking necessary to distribute the load among the nodes.
The application will still be accessible as before simply under `http://0.0.0.0:8080` on each node, e.g. `http://10.0.2.77:8080`, the manager node's IP.

#### Load balancer setup

Now as mentioned earlier you can simply use the manager node's endpoint in a reverse proxy setup and the load will be balanced among the nodes.
But that will be a single point of failure if the manager node goes down.

To make this more redundant you can use the load balancer directive in your proxy configuration.
For instance for apache this could look like this:

```
<Proxy balancer://swarm>
    BalancerMember http://10.0.2.77:8080 # swarm node 1 (manager)
    BalancerMember http://10.0.2.78:8080 # swarm node 2
    BalancerMember http://10.0.2.79:8080 # swarm node 3, etc.

    ProxySet lbmethod=bytraffic
</Proxy>

# ...

ProxyPass "balancer://swarm/"
ProxyPassReverse "balancer://swarm/"

# instead of
#   ProxyPass http://127.0.0.1:8080/
#   ProxyPassReverse http://127.0.0.1:8080/
# shown in the reverse proxy configuration example further up
```

The application will be accessible on any node even if the process isn't running on the node itself.
In that case it will use swarm's [internal load balancing](https://docs.docker.com/engine/swarm/key-concepts/#load-balancing) to route the request to a node that does run the service. So feel free to put all nodes into the load balancer configuration.
