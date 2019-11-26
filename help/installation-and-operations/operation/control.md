---
sidebar_navigation:
  title: Process control
  priority: 5
---

# Process control for your OpenProject installation

Note: this guide is specific to the package-based installation.

## Restart all the OpenProject processes

```bash
sudo openproject restart
```

## Run commands like rake tasks or rails console

The OpenProject command line tool supports running rake tasks and known scripts. For instance:

Get the current version of OpenProject

```bash
sudo openproject run bundle exec rake version
```

Launch an interactive console to directly interact with the underlying Ruby on Rails application:

```bash
sudo openproject run console
```

Manually launch the database migrations:

```bash
sudo openproject run rake db:migrate
```

Check the version of Ruby used by OpenProject:

```bash
sudo openproject run ruby -v
```

## Scaling the number of web workers

TODO: review

Note: Depending on your free RAM on your system, we recommend you raise the default number of web processes. The default from 9.0.3 onwards is 4 web processes. Each worker will take roughly 300-400MB RAM.

We recommend at least 4 web processes. Please check your current web processes count with:

```bash
sudo openproject config:get OPENPROJECT_WEB_WORKERS
```

If it returns nothing, the default process count of `4` applies. To increase or decrease the process count, call

```bash
sudo openproject config:set OPENPROJECT_WEB_WORKERS=number
```

Where `number` is a positive number between 1 and `round(AVAILABLE_RAM * 1.5)`.

After changing these values, call `sudo openproject configure` to apply it to the web server.
