### Basic Dockerfile for OpenProject
#
# This is a very basic Dockerfile for OpenProject which mostly acts
# as executable documentation on how to install and run OpenProject
# from scratch.
#
# It takes the local checkout and builds an image with it. After
# building you can run it in all rails environments, including test.
#
# Intentionally, no optimizations have been applied to the Dockerfile.
# This means building takes ages after every single modification of a file,
# but it keeps the Dockerfile clean and expressive.
#
# If you happen to build this file more often have a look at more optimized
# Dockerfiles look in the openproject-docker repository or use one of the
# prebuilt images.
#
#
# USAGE:
#
# First of all we need to build the image.
#
#     docker build -t opf/openproject .
#
# Once that's done we can start a container from the image. But before running
# the app we need to prepare our database.
#
# Let's fire up a postgres container on our docker host that we can connect to.
#
#     docker run -d --name postgres \
#       -e POSTGRES_USER=openproject -e POSTGRES_PASSWORD=openproject postgres:9.4
#
# We use the official postgres 9.4 image and give the container a name for linking later on.
# We also create a user with password which we will use when connecting from our OpenProject container.
#
# Usually Rails apps require a couple of rake commands to be issued before we can run the application.
# Some of them were already done when building the image, but database related tasks are executed separately.
#
# Let's migrate our database through our openproject image.
#
#     docker run -it --rm --link postgres:database \
#       -e DATABASE_URL=postgres://openproject:openproject@database:5432/openproject \
#       opf/openproject bundle exec rake db:migrate
#
#     docker run -it --rm --link postgres:database \
#       -e DATABASE_URL=postgres://openproject:openproject@database:5432/openproject \
#       -e RAILS_ENV=production -e SECRET_TOKEN=foobar \
#       opf/openproject bundle exec rake db:seed
#
# Note, that we run `rake db:seed` in the production environment, which results in a minimal seed.
# This is a little openproject detail and might be changed in the future.
#
# If you want a more complex seed, run `rake db:seed` in development. This will add a lot of
# work packages with lorem ipsum style content.
#
#     docker run -it --rm --link postgres:database \
#       -e DATABASE_URL=postgres://openproject:openproject@database:5432/openproject \
#       linki/openproject:simple bundle exec rake db:seed
#
# And then finally run the app server in the background.
#
#     docker run -d -p 3000:3000 --link postgres:database \
#       -e DATABASE_URL=postgres://openproject:openproject@database:5432/openproject opf/openproject
#
# Voila, now browse to your docker host's ip address on port 3000.
#
#   If you're on Linux then most likely you can go to localhost:3000.
#   If you're using boot2docker on a mac you can probably use `boot2docker.me:3000`.
#
# Login with `admin/admin`
#
# If you want to run it in production just pass the rails env and a secret token.
#
#     docker run -d -p 3000:3000 --link postgres:database \
#       -e DATABASE_URL=postgres://openproject:openproject@database:5432/openproject \
#       -e RAILS_ENV=production -e SECRET_TOKEN=foobar opf/openproject
#
# The worker process can be run in a separate container.
#
#     docker run -d --link postgres:database \
#       -e DATABASE_URL=postgres://openproject:openproject@database:5432/openproject \
#       -e RAILS_ENV=production -e SECRET_TOKEN=foobar opf/openproject \
#       bundle exec rake jobs:work
#
# If you don't want to execute these commands by hand all the time, have a look at the fig.yml

FROM ubuntu:15.04
MAINTAINER Finn GmbH <info@finn.de>

# update the package list
RUN apt-get update

# install build-essential because we need to compile some native extensions
RUN apt-get install -y build-essential

# install zlib development headers for nokogiri to build
#
# http://www.nokogiri.org/tutorials/installing_nokogiri.html
#
RUN apt-get install -y zlib1g-dev

# we use a database for our backend, so let's add a couple of them
RUN apt-get -y install libpq-dev libmysql++-dev sqlite3 libsqlite3-dev

# newer versions of openproject use angular-js, so we want node and npm
RUN apt-get -y install nodejs npm

# allow the nodejs binary to be called via node (this should be fixed somehow)
RUN ln -s nodejs /usr/bin/node

# install git in order to checkout gems defined by git urls
RUN apt-get -y install git-core

# install ruby 2.1 with development extensions
RUN apt-get install -y ruby2.1 ruby2.1-dev

# install our beloved bundler
RUN gem install bundler

# install foreman to run our app server at the end
RUN gem install foreman

# add openproject's source to the container
COPY . /app

# set the working directory to the app
WORKDIR /app

# add two gems that are required to make everything work inside a container
#
# sqlite3: for connecting to a dummy database during asset precompilation
# 12factor: to serve static assets by rails and log to stdout in production
#
RUN echo "gem 'sqlite3', '~> 1.3.10'" >> ./Gemfile.local
RUN echo "gem 'rails_12factor', '~> 0.0.3'" >> ./Gemfile.local

# create an unprivileged user that owns the code and will run the app server
RUN useradd -m app
RUN chown -R app:app /app

# switch to the app user from now on
USER app

# install all ruby dependencies via bundler into a local path
RUN bundle install --path ./vendor/bundle

# install all node dependencies via npm
RUN npm install

# use a database.yml that takes its values from an environment variable
RUN cp ./config/database.env.yml ./config/database.yml

# precompile all assets
#
# openproject currently requires a database when compiling assets
# we fake one by providing an sqlite db location for this command only
#
# note, asset precompilation needs to be done in production, otherwise icon images are missing
#
RUN RAILS_ENV=production SECRET_TOKEN=foobar DATABASE_URL=sqlite3://db/ignore_me.sqlite3 \
  bundle exec rake assets:precompile

# expose the app server's port
EXPOSE 3000

# launch the rails server unless another command is given
CMD HOST=0.0.0.0 PORT=3000 foreman start web
