---
sidebar_navigation:
  title: Process control
  priority: 5
---

# Process control for your OpenProject installation

## Packaged installation

### Restart all the OpenProject processes

```shell
sudo openproject restart
```

### Run commands like rake tasks or rails console

The OpenProject command line tool supports running rake tasks and known scripts. For instance:

Get the current version of OpenProject

```shell
sudo openproject run bundle exec rake version
```

Launch an interactive console to directly interact with the underlying Ruby on Rails application:

```shell
sudo openproject run console
# if user the docker all-in-one container: docker exec -it openproject bundle exec rails console
# if using docker-compose: docker-compose run --rm web bundle exec rails console
```

Manually launch the database migrations:

```shell
sudo openproject run rake db:migrate
# if user the docker all-in-one container: docker exec -it openproject bundle exec rake db:migrate
# if using docker-compose: docker-compose run --rm web bundle exec rake db:migrate
```

Check the version of Ruby used by OpenProject:

```shell
sudo openproject run ruby -v
# if user the docker all-in-one container: docker exec -it openproject ruby -v
# if using docker-compose: docker-compose run --rm web ruby -v
```

### Scaling the number of web workers

Note: Depending on your free RAM on your system, we recommend you raise the default number of web processes. The default from 9.0.3 onwards is 4 web processes. Each worker will take roughly 300-400MB RAM.

We recommend at least 4 web processes. Please check your current web processes count with:

```shell
sudo openproject config:get OPENPROJECT_WEB_WORKERS
```

If it returns nothing, the default process count of `4` applies. To increase or decrease the process count, call

```shell
sudo openproject config:set OPENPROJECT_WEB_WORKERS=number
```

Where `number` is a positive number between 1 and `round(AVAILABLE_RAM * 1.5)`.

After changing these values, simply restart the web process:

```shell
sudo openproject restart web
```

### Scaling the number of background workers

Note: Depending on your free RAM on your system, we recommend you raise the default number of background processes. By default, one background worker is spawned. Background workers are responsible for delivering mails, copying projects, performing backups and deleting resources.

We recommend to have two background worker processes. Please check your current web processes count with:

To set the desired process count, call

```shell
sudo openproject scale worker=number
```

Where `number` is a positive number between 1 and `round(AVAILABLE_RAM * 1.5)`.

The respective systemd services are automatically created or removed. If you were already at the entered value, it will output `Nothing to do.`

## All-in-one Docker-based installation

### Run commands like rake tasks or rails console

You can spawn an interactive shell in your docker container to run commands in the OpenProject environment.

First, find out the container ID of your web process with:

```shell
# Ensure the containers are running with the following output
docker ps | grep web_1

# save the container ID as a env variable $CID
export CID=$(docker ps | grep web_1 | cut -d' ' -f 1)
```

We can now run commands against that container

Run a bash shell in the container

```shell
docker exec -it $CID bash
```

Get the current version of OpenProject

```shell
docker exec -it $CID bash -c "RAILS_ENV=production bundle exec rails version"
```

In case of using kubernetes, the command is a bit different

```shell
kubectl exec -it {POD_ID} -- bash -c "RAILS_ENV=production bundle exec rails console"
```

Launch an interactive console to directly interact with the underlying Ruby on Rails application:

```shell
docker exec -it $CID bash -c "RAILS_ENV=production bundle exec rails console"
```

## docker-compose based installation

### Spawn a rails console

You can spawn an interactive shell in your docker-compose setup container to run commands in the OpenProject environment.

The following command will spawn a Rails console in the container:

```shell
docker-compose run web bash -c "RAILS_ENV=production bundle exec rails console"
```

## Kubernetes and Helm-Charts

For Kubernetes installations, you can use `kubectl` to access pods and get information about them. For example, to get a shell in one of the worker pods, you would have to do the following.

First, get the pod name of the worker. Assuming your kubectl cluster has OpenProject installed at the `openproject` namespace:

```shell
kubectl get pods -n openproject 
```

Then spawn a shell in the relevant one

```shell
kubectl exec -n openproject -it pods/openproject-worker-656c77d594-xjdck -- bash
```

This spawns a bash console. In there, you could for example run a rails console like follows:

```shell
bundle exec rails console
```
