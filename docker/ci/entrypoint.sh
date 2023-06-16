#!/bin/bash
set -e

export PGBIN="/usr/lib/postgresql/$PGVERSION/bin"
export JOBS="${CI_JOBS:=$(nproc)}"
# for parallel rspec
export PARALLEL_TEST_PROCESSORS=$JOBS
export PARALLEL_TEST_FIRST_IS_1=true
export DISABLE_DATABASE_ENVIRONMENT_CHECK=1
export NODE_OPTIONS="--max-old-space-size=8192"
LOG_FILE=/tmp/op-output.log

run_psql() {
	$PGBIN/psql -v ON_ERROR_STOP=1 -U dev -h 127.0.0.1 "$@"
}

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
	eval "$@"
}

execute_quiet() {
	if ! BANNER="[execute_quiet]" execute "$@" >$LOG_FILE ; then
		return 1
	else
		return 0
	fi
}

reset_dbs() {
	# must reset main db because for some reason the users table is not empty, after running db:migrate
	execute_quiet "echo 'drop database if exists appdb ; create database appdb' | run_psql -d postgres"
	execute_quiet "cat db/structure.sql | run_psql -d appdb"
	# create and load schema for test databases "appdb1" to "appdb$JOBS", far faster than using parallel_rspec tasks for that
	for i in $(seq 1 $JOBS); do
		execute_quiet "echo 'drop database if exists appdb$i ; create database appdb$i with template appdb owner appuser;' | run_psql -d postgres"
	done
}

if [ "$1" == "setup-tests" ]; then
	shift
	echo "Preparing environment for running tests..."

	execute_quiet "mkdir -p tmp"
	execute_quiet "cp docker/ci/database.yml config/"

	for i in $(seq 0 $JOBS); do
		folder="$CAPYBARA_DOWNLOADED_FILE_DIR/$i"
		execute_quiet "rm -rf '$folder' ; mkdir -p '$folder' ; chmod 1777 '$folder'"
	done

	if [ ! -d "/tmp/nulldb" ]; then
		execute_quiet "$PGBIN/initdb -E UTF8 -D /tmp/nulldb"
		execute_quiet "cp docker/ci/postgresql.conf /tmp/nulldb/"
		execute_quiet "$PGBIN/pg_ctl -D /tmp/nulldb -l /dev/null -w start"
		echo "create database appdb; create user appuser with superuser encrypted password 'p4ssw0rd'; grant all privileges on database appdb to appuser;" | run_psql -d postgres
	fi

	# create test database "app" and dump schema because db/structure.sql is not checked in
	execute_quiet "time bundle exec rails db:migrate db:schema:dump zeitwerk:check openproject:plugins:register_frontend"
fi

if [ "$1" == "run-units" ]; then
	shift
	reset_dbs
	execute_quiet "cp -f /cache/turbo_runtime_units.log spec/support/ || true"
	# turbo_tests cannot yet exclude specific directories, so copying spec/features elsewhere (temporarily)
	execute_quiet "mv spec/features tmp/"
	execute "time bundle exec turbo_tests --verbose -n $JOBS --runtime-log spec/support/turbo_runtime_units.log spec"
	execute_quiet "cp -f spec/support/turbo_runtime_units.log /cache/ || true"
	cleanup
fi

if [ "$1" == "run-features" ]; then
	shift
	reset_dbs
	execute_quiet "time bundle exec rails assets:precompile webdrivers:chromedriver:update webdrivers:geckodriver:update"
	execute_quiet "cp -f /cache/turbo_runtime_features.log spec/support/ || true"
	execute_quiet "cp -rp config/frontend_assets.manifest.json public/assets/frontend_assets.manifest.json"
	execute "time bundle exec turbo_tests --verbose -n $JOBS --runtime-log spec/support/turbo_runtime_features.log spec/features"
	execute_quiet "cp -f spec/support/turbo_runtime_features.log /cache/ || true"
	cleanup
fi

if [ "$1" == "run-all" ]; then
	shift
	reset_dbs
	execute_quiet "time bundle exec rails assets:precompile webdrivers:chromedriver:update webdrivers:geckodriver:update"
	execute_quiet "cp -f /cache/turbo_runtime_all.log spec/support/ || true"
	execute_quiet "cp -rp config/frontend_assets.manifest.json public/assets/frontend_assets.manifest.json"
	execute "time bundle exec turbo_tests --verbose -n $JOBS --runtime-log spec/support/turbo_runtime_all.log spec"
	execute_quiet "cp -f spec/support/turbo_runtime_all.log /cache/ || true"
	cleanup
fi

if [ ! -z "$1" ] ; then
	exec "$@"
fi
