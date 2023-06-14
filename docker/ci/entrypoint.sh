#!/bin/bash
set -e

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
	chown -R $USER:$USER /cache
fi


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
	if ! BANNER="[execute_quiet]" execute "$@" >/tmp/op-output.log ; then
		cat /tmp/op-output.log
		return 1
	else
		return 0
	fi
}

cleanup() {
	echo "CLEANUP"
	rm -rf tmp/cache/parallel*
	rm -f /tmp/op-output.log
	if [ -d tmp/features ]; then mv tmp/features spec/ ; fi
}

trap cleanup INT TERM EXIT

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
	# create test database "app" and dump schema
	execute_quiet "time bundle exec rails db:create db:migrate db:schema:dump webdrivers:chromedriver:update webdrivers:geckodriver:update openproject:plugins:register_frontend"
	# create parallel test databases "app#n" and load schema
	execute_quiet "time bundle exec rails parallel:create parallel:load_schema"
	# setup frontend deps
	execute_quiet "cd frontend && npm install"
fi

if [ "$1" == "run-units" ]; then
	shift
	execute_quiet "cp -f /cache/turbo_runtime_units.log spec/support/ || true"
	# turbo_tests cannot yet exclude specific directories, so copying spec/features elsewhere (temporarily)
	execute_quiet "mv spec/features tmp/"
	execute_quiet "time bundle exec rails zeitwerk:check"
	execute "time bundle exec turbo_tests --verbose -n $JOBS --runtime-log spec/support/turbo_runtime_units.log spec"
	execute_quiet "cp -f spec/support/turbo_runtime_units.log /cache/ || true"
	cleanup
fi

if [ "$1" == "run-features" ]; then
	shift
	execute_quiet "cp -f /cache/turbo_runtime_features.log spec/support/ || true"
	execute_quiet "time bundle exec rails assets:precompile"
	execute_quiet "cp -rp config/frontend_assets.manifest.json public/assets/frontend_assets.manifest.json"
	execute "time bundle exec turbo_tests --verbose -n $JOBS --runtime-log spec/support/turbo_runtime_features.log spec/features"
	execute_quiet "cp -f spec/support/turbo_runtime_features.log /cache/ || true"
	cleanup
fi

if [ ! -z "$1" ] ; then
	exec "$@"
fi
