#!/bin/bash
#set -e

export PGBIN="/usr/lib/postgresql/$PGVERSION/bin"
export JOBS="${CI_JOBS:=$(nproc)}"
# for parallel rspec
export PARALLEL_TEST_PROCESSORS=$JOBS
export PARALLEL_TEST_FIRST_IS_1=true

# if from within docker
if [ $(id -u) -eq 0 ]; then
	if [ ! -d "/tmp/nulldb" ]; then
		echo "fsync = off" >> /etc/postgresql/$PGVERSION/main/postgresql.conf
		echo "full_page_writes = off" >> /etc/postgresql/$PGVERSION/main/postgresql.conf
		su - postgres -c "$PGBIN/initdb -E UTF8 -D /tmp/nulldb"
		su - postgres -c "$PGBIN/pg_ctl -D /tmp/nulldb -l /dev/null -w start"
		echo "create database app; create user app with superuser encrypted password 'p4ssw0rd'; grant all privileges on database app to app;" | su - postgres -c $PGBIN/psql
	fi

	mkdir -p /usr/local/bundle
	mkdir -p /home/$USER/openproject/frontend/node_modules
	mkdir -p /home/$USER/openproject/frontend/.angular
	mkdir -p /home/$USER/openproject/tmp
	mkdir -p /cache
	chown $USER:$USER /usr/local/bundle
	chown $USER:$USER /home/$USER/openproject/frontend/node_modules
	chown $USER:$USER /home/$USER/openproject/frontend/.angular
	chown $USER:$USER /home/$USER/openproject/tmp
	chown $USER:$USER /cache
fi


execute() {
	if [ $(id -u) -eq 0 ]; then
		su $USER -c "$@"
	else
		bash -c "$@"
	fi
}

cleanup() {
	rm -rf tmp/cache/parallel*
	[ -d tmp/features ] && mv tmp/features spec/
}

trap cleanup INT TERM EXIT

if [ "$1" == "setup-tests" ]; then
	echo "Preparing environment for running tests..."
	shift

	execute "mkdir -p tmp"
	execute "cp docker/ci/database.yml config/"

	for i in $(seq 0 $JOBS); do
		folder="$CAPYBARA_DOWNLOADED_FILE_DIR/$i"
		echo "Creating folder $folder..."
		rm -rf "$folder"
		mkdir -p "$folder"
		chmod 1777 "$folder"
	done

	execute "time bundle install -j$JOBS"
	# create test database "app" and dump schema
	execute "time bundle exec rails db:create db:migrate db:schema:dump webdrivers:chromedriver:update webdrivers:geckodriver:update openproject:plugins:register_frontend"
	# create parallel test databases "app#n" and load schema
	execute "time bundle exec rails parallel:create parallel:load_schema"
	# setup frontend deps
	execute "cd frontend && npm install"
fi

if [ "$1" == "run-units" ]; then
	shift
	execute "cp -f /cache/turbo_runtime_units.log spec/support/"
	execute "time bundle exec rails zeitwerk:check"
	execute "mv spec/features tmp/"
	execute "time bundle exec turbo_tests -n $JOBS --runtime-log spec/support/turbo_runtime_units.log spec"
	execute "cp -f spec/support/turbo_runtime_units.log /cache/"
fi

if [ "$1" == "run-features" ]; then
	shift
	execute "cp -f /cache/turbo_runtime_features.log spec/support/"
	execute "time bundle exec rails assets:precompile"
	execute "cp -rp config/frontend_assets.manifest.json public/assets/frontend_assets.manifest.json"
	execute "time bundle exec turbo_tests -n $JOBS --runtime-log spec/support/turbo_runtime_features.log spec/features"
	execute "cp -f spec/support/turbo_runtime_features.log /cache/"
fi

if [ ! -z "$1" ] ; then
	exec "$@"
fi
