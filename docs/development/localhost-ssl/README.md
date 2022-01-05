# Developing OpenProject locally with HTTPS

In some cases, running OpenProject locally with https can be useful for development. For example, if your testing or developing an OmniAuth plugin, you'll want to be able to return to OpenProject running under https.

This guide will instruct you how to install and configure an Apache2 proxy/reverse-proxy pattern with OpenProject. This closely matches the way OpenProject is run in production systems for packaged and docker-based installations.



## Step 1: Create a self-signed certificate

You will need a certificate to terminate SSL requests at Apache. For development purposes only, create a self-signed certificate as follows:

```bash
sudo mkdir -p /etc/ssl/openproject-dev/
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/openproject-dev/privkey.key -out /etc/ssl/openproject-dev/cert.crt
```



This will output a private key and certificate to `/etc/ssl/openproject-dev` for use with Apache2.



## Step 2: Set up a custom host

You may want to have a full host name available for development. Let's assume this is `openproject.example.com`. You can forward this hostname to your local machine by editing `/etc/hosts` and adding `openproject.example.com 127.0.0.1` to it.



## Step 3: Install and configure Apache2

First, you'll need to install the Apache2 web server. The actual command will differ depending on your actual distribution. For apt-based systems, the following command is used:

```bash
sudo apt-get install apache2
```

Next, ensure that `mod_ssl`, `mod_proxy`, `mod_proxy_http` and `mod_headers` are installed and active. Read up in your distribution's apache configuration on how to enable them. You can check the output of `apachectl -M` and verify they are being loaded.

You will then add a configuration for OpenProject under:

```bash
nano /etc/apache2/sites-available/openproject-dev-ssl.conf
```

The path might differ. For RHEL/Fedora systems, the configuration directory resides at `/etc/apache2/conf.d/`.

The following contains an exemplary configuration:

```
<VirtualHost *:80>
    ServerName openproject.example.com
    redirect permanent / https://openproject.example.com/
</VirtualHost>

<VirtualHost *:443>
    #
    # SSL Start
    #

    SSLEngine On
    SSLCertificateFile /etc/ssl/openproject-dev/cert.crt
    SSLCertificateKeyFile /etc/ssl/openproject-dev/privkey.key
    
    # If you have a chain file (not self-signed certificate), uncomment this
    # SSLCertificateChainFile /etc/ssl/openproject-dev/chain.pem

    # Set Forwarded protocol header to proxy
    # otherwise OpenProject doesn't know we're terminating SSL here.
    RequestHeader set X_FORWARDED_PROTO 'https'

    #
    # SSL End
    #

    ServerName      openproject.example.com
    ServerAdmin     admin@example.com

    # Proxy requests to development localhost:3000 / puma worker
    ProxyRequests off
    ProxyPass / http://127.0.0.1:3000/ retry=0
    ProxyPassReverse / http://127.0.0.1:3000/
</VirtualHost>

```



Save the configuration file, activate it (e.g. with `sudo a2ensite openproject-dev-ssl.conf`) and reload the Apache2 server. Ensure the syntax is correct with `apachectl configtest`. 

In case you're in an environment with SELinux enabled, you will also need to allow Apache2 to connect locally to the application server. You can do that with `/usr/sbin/setsebool -P httpd_can_network_connect 1`.



## Step 4: Configure OpenProject for HTTPS usage

We assume you have already configured your OpenProject local development environment as [described in this guide](../development-environment-ubuntu). You will need to add your custom host name to `config/environments/development.rb`:

```ruby
Rails.application.config.hosts << 'openproject.example.com'
```



Then, you will start a REPL console for OpenProject with: `RAILS_ENV=development ./bin/rails console`

Update the settings for host name and protocol:

```ruby
Setting.protocol = 'https'
Setting.host_name = 'openproject.example.com'
```



Finally, start your OpenProject development server and Frontend server and access `https://openproject.example.com` in your browser.



## Questions, Comments, and Feedback

If you have any further questions, comments, feedback, or an idea to enhance this guide, please tell us at the appropriate community.openproject.org [forum](https://community.openproject.org/projects/openproject/boards/9).
[Follow OpenProject on twitter](https://twitter.com/openproject), and follow [the news](https://www.openproject.org/blog) to stay up to date.
