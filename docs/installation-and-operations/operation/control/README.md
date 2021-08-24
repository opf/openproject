---
sidebar_navigation:
  title: Process control
  priority: 5
---

# Process control for your OpenProject installation





## Packaged installation 

#### Restart all the OpenProject processes

```bash
sudo openproject restart
```



#### Run commands like rake tasks or rails console

The OpenProject command line tool supports running rake tasks and known scripts. For instance:

Get the current version of OpenProject

```bash
sudo openproject run bundle exec rake version
```

Launch an interactive console to directly interact with the underlying Ruby on Rails application:

```bash
sudo openproject run console
# if user the docker all-in-one container: docker exec -it openproject bundle exec rails console
# if using docker-compose: docker-compose run --rm web bundle exec rails console
```

Manually launch the database migrations:

```bash
sudo openproject run rake db:migrate
# if user the docker all-in-one container: docker exec -it openproject bundle exec rake db:migrate
# if using docker-compose: docker-compose run --rm web bundle exec rake db:migrate
```

Check the version of Ruby used by OpenProject:

```bash
sudo openproject run ruby -v
# if user the docker all-in-one container: docker exec -it openproject ruby -v
# if using docker-compose: docker-compose run --rm web ruby -v
```



#### Scaling the number of web workers

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

After changing these values, simply restart the web process:

```bash
sudo openproject restart web
```



## All-in-one Docker-based installation

#### Run commands like rake tasks or rails console

You can spawn an interactive shell in your docker container to run commands in the OpenProject environment.



First, find out the container ID of your web process with: 

```bash
# Ensure the containers are running with the following output
docker ps | gre web_1

# save the container ID as a env variable $CID
export CID=$(docker ps | grep web_1 | cut -d' ' -f 1)
```



We can now run commands against that container

Run a bash shell in the container

```bash
docker exec -it $CIT bash
```

Get the current version of OpenProject

```bash
docker exec -it $CIT bash -c "RAILS_ENV=production rails version"
```

In case of using kubernetes, the command is a bit different

```bash
kubectl exec -it {POD_ID} -- bash -c "RAILS_ENV=production bundle exec rails console"
```



Launch an interactive console to directly interact with the underlying Ruby on Rails application:

```bash
docker exec -it $CIT bash -c "RAILS_ENV=production rails console"
```

## docker-compose based installation

#### Spawn a rails console

You can spawn an interactive shell in your docker-compose setup container to run commands in the OpenProject environment.


The following command will spawn a Rails console in the container:

```bash
docker-compose run web bash -c "RAILS_ENV=production bundle exec rails console"
```
