#!/bin/bash
set -e

export PGBIN="/usr/lib/postgresql/$PGVERSION/bin"
export JOBS="${CI_JOBS:=$(nproc)}"
# for parallel rspec
export PARALLEL_TEST_PROCESSORS=$JOBS
export PARALLEL_TEST_FIRST_IS_1=true
export DISABLE_DATABASE_ENVIRONMENT_CHECK=1
LOG_FILE=/tmp/op-output.log

cleanup() {
	exit_code=$?
	echo "CLEANUP"
	rm -rf tmp/cache/parallel*
	if [ -d tmp/features ]; then mv tmp/features spec/ ; fi
	if [ ! $exit_code -eq "0" ]; then
		echo "ERROR: exit code $exit_code"
		cat $LOG_FILE
	fi
	rm -f $LOG_FILE
}

trap cleanup INT TERM EXIT

execute() {
	BANNER=${BANNER:="[execute]"}
	echo "$BANNER $@" >&2
	if [ $(id -u) -eq 0 ]; then
		su $USER -c "$@"
	else
		bash -c "$@"
	fi
}

execute_quiet() {
	if ! BANNER="[execute_quiet]" execute "$@" >$LOG_FILE ; then
		return 1
	else
		return 0
	fi
}

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
	chown -R $USER:$USER /cache
fi

if [ "$1" == "setup-tests" ]; then
	echo "Preparing environment for running tests..."
	shift

	execute_quiet "mkdir -p tmp"
	execute_quiet "cp docker/ci/database.yml config/"

	for i in $(seq 0 $JOBS); do
		folder="$CAPYBARA_DOWNLOADED_FILE_DIR/$i"
		execute_quiet "rm -rf '$folder' ; mkdir -p '$folder' ; chmod 1777 '$folder'"
	done

	execute_quiet "time bundle install -j$JOBS --quiet"
	# create test database "app" and dump schema because db/structure.sql is not checked in
	execute_quiet "time bundle exec rails db:migrate db:schema:dump"
	# create test databases "app1" to "app$JOBS", far faster than using parallel_rspec tasks for that
	for i in $(seq 1 $JOBS); do
		execute_quiet "echo 'create database app$i with template app owner app;' | $PGBIN/psql $DATABASE_URL"
	done
	execute_quiet "time bundle exec rails webdrivers:chromedriver:update webdrivers:geckodriver:update openproject:plugins:register_frontend"
	# setup frontend deps
	execute_quiet "cd frontend && npm install"
fi

if [ "$1" == "run-units" ]; then
	shift
	execute_quiet "cp -f /cache/turbo_runtime_units.log spec/support/ || true"
	# turbo_tests cannot yet exclude specific directories, so copying spec/features elsewhere (temporarily)
	execute_quiet "mv spec/features tmp/"
	execute_quiet "time bin/rails zeitwerk:check"
	execute "time bundle exec turbo_tests -n $JOBS --runtime-log spec/support/turbo_runtime_units.log spec"
	execute_quiet "cp -f spec/support/turbo_runtime_units.log /cache/ || true"
	cleanup
fi

if [ "$1" == "run-features" ]; then
	shift
	execute_quiet "cp -f /cache/turbo_runtime_features.log spec/support/ || true"
	execute_quiet "time bundle exec rails assets:precompile"
	execute_quiet "cp -rp config/frontend_assets.manifest.json public/assets/frontend_assets.manifest.json"
	execute "time bundle exec turbo_tests -n $JOBS --runtime-log spec/support/turbo_runtime_features.log spec/features"
	execute_quiet "cp -f spec/support/turbo_runtime_features.log /cache/ || true"
	cleanup
fi

if [ ! -z "$1" ] ; then
	exec "$@"
fi
