#!/bin/bash

set -eo pipefail

export PATH="/usr/lib/postgresql/$PGVERSION/bin:$PATH"
export JOBS="${CI_JOBS:=$(nproc)}"
# for parallel rspec
export PARALLEL_TEST_PROCESSORS=$JOBS
export PARALLEL_TEST_FIRST_IS_1=true
export DISABLE_DATABASE_ENVIRONMENT_CHECK=1
# export NODE_OPTIONS="--max-old-space-size=8192"
export LOG_FILE=/tmp/op-output.log
export PGUSER=${PGUSER:=appuser}
export PGHOST=${PGHOST:=127.0.0.1}
export PGPASSWORD=${PGPASSWORD:=p4ssw0rd}
export DATABASE_URL="postgres://$PGUSER:$PGPASSWORD@$PGHOST/appdb"
# Hocuspocus will not start without a secret and it needs to be the same in OpenProject
export OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET=secret12345

run_psql() {
	psql -v ON_ERROR_STOP=1 "$@"
}

cleanup() {
	exit_code=$?
	echo "CLEANUP"
	rm -rf tmp/cache/parallel*

	# kill hocuspocus running in background:
	killall node || true
	if [ ! $exit_code -eq "0" ]; then
		echo "ERROR: exit code $exit_code"
		tail -n 1000 $LOG_FILE
	fi
	rm -f $LOG_FILE
}

trap cleanup INT TERM EXIT

declare -a pids=()

run_background() {
	# Run the command in the background
	"$@" &

	# Store the PID of the background process
	local pid=$!
	pids+=("$pid")

	echo "[background] Started background process $pid: $@"
}

wait_for_background() {
	# Make a copy of the pids array
	local waiting_pids=("${pids[@]}")
	echo "[background] Waiting for background processes ${waiting_pids[@]} to finish..."
	# Reset the global pids array to empty
	pids=()

	for pid in "${waiting_pids[@]}"; do
		wait "$pid"
		# Check the exit status of each background process
		if [ $? -ne 0 ]; then
			echo "[background] Command with PID $pid failed"
			exit 1
		fi
	done
	echo "[background] All background processes ${waiting_pids[@]} finished"
}

execute() {
	BANNER=${BANNER:="[execute]"}
	echo "$BANNER $@" >&2
	eval "$@"
}

execute_quiet() {
	if ! BANNER="[execute_quiet]" execute "$@" >"$LOG_FILE" ; then
		return 1
	else
		return 0
	fi
}
create_db_cluster() {
	if [ ! -d "/tmp/nulldb" ]; then
		execute_quiet "initdb -E UTF8 -D /tmp/nulldb -U $PGUSER"
		execute_quiet "cp docker/ci/postgresql.conf /tmp/nulldb/"
		execute_quiet "pg_ctl -D /tmp/nulldb -l /dev/null -w start"
	fi
}

reset_dbs() {
	create_db_cluster
	# must reset main db because for some reason the users table is not empty, after running db:migrate
	execute_quiet "echo 'drop database if exists appdb ; create database appdb' | run_psql -d postgres"
	execute_quiet "cat db/structure.sql | run_psql -d appdb"
	# create and load schema for test databases "appdb1" to "appdb$JOBS", far faster than using parallel_rspec tasks for that
	for i in $(seq 1 $JOBS); do
		execute_quiet "echo 'drop database if exists appdb$i ; create database appdb$i with template appdb owner $PGUSER;' | run_psql -d postgres"
	done
}

setup_hocuspocus() {
  if [ -d "extensions/op-blocknote-hocuspocus" ]; then
    cd extensions/op-blocknote-hocuspocus
    npm install --omit=dev
    cd -
  else
    echo 'Could not find Hocuspocus in extensions/op-blocknote-hocuspocus!'
  fi
}

start_hocuspocus() {
  if [ -d "extensions/op-blocknote-hocuspocus" ]; then
    cd extensions/op-blocknote-hocuspocus
    execute "SECRET=$OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET npm run start"
    cd -
  else
    echo 'Could not find Hocuspocus in extensions/op-blocknote-hocuspocus!'
  fi
}

backend_stuff() {
	# create test database "app" and dump schema because db/structure.sql is not checked in
	execute_quiet "time bundle exec rails db:create db:migrate db:schema:dump zeitwerk:check"
}

frontend_stuff() {
	execute_quiet "DATABASE_URL=nulldb://db time bin/rails openproject:plugins:register_frontend assets:precompile"
	execute_quiet "cp -rp config/frontend_assets.manifest.json public/assets/frontend_assets.manifest.json"
}

setup_tests() {
	echo "Preparing environment for running tests..."
	for i in $(seq 1 $JOBS); do
		folder="$CAPYBARA_DOWNLOADED_FILE_DIR/$i"
		execute_quiet "rm -rf '$folder' ; mkdir -p '$folder' ; chmod 1777 '$folder'"
	done

	execute_quiet "mkdir -p spec/support/runtime-logs/"
	execute_quiet "cp docker/ci/database.yml config/"
	create_db_cluster

	execute "gem install bundler --no-document"

	run_background execute "BUNDLE_JOBS=8 bundle install --quiet && bundle clean --force && echo BUNDLE DONE"
	run_background execute "JOBS=8 time npm install --quiet && npm prune --quiet && echo NPM DONE"
	wait_for_background

	setup_hocuspocus
	run_background backend_stuff
	run_background frontend_stuff
	# pre-cache browsers and their drivers binaries
	run_background $(bundle show selenium-webdriver)/bin/linux/selenium-manager --browser chrome --debug
	run_background $(bundle show selenium-webdriver)/bin/linux/selenium-manager --browser firefox --debug
	wait_for_background
}

run_units() {
	shopt -s extglob globstar nullglob
	reset_dbs
	execute "time bundle exec turbo_tests --verbose -n $JOBS --runtime-log spec/support/runtime-logs/turbo_runtime_units.log {,modules/*/}spec/{!(features)/**/,}*_spec.rb"
	cleanup
}

run_features() {
	shopt -s globstar nullglob
	run_background start_hocuspocus
	reset_dbs

	if ! execute "time bundle exec turbo_tests --verbose -n $JOBS --runtime-log spec/support/runtime-logs/turbo_runtime_features.log {,modules/*/}spec/features/**/*_spec.rb"; then
		failed_count=$(grep --count ' failed ' tmp/spec_examples.txt 2>/dev/null || echo 0)
		if [ "$failed_count" -eq 0 ]; then
			echo "failed to find failing examples, unexpected"
			exit 1
		elif [ "$failed_count" -le 10 ]; then
			echo "retrying $failed_count failed examples"
			execute "bundle exec rspec --only-failures --format documentation {,modules/*/}spec/features/**/*_spec.rb"
		else
			echo "too many failures ($failed_count), not retrying"
			exit 1
		fi
	fi

	cleanup
}

run_all() {
	shopt -s globstar nullglob
	reset_dbs
	execute "time bundle exec turbo_tests --verbose -n $JOBS --runtime-log spec/support/runtime-logs/turbo_runtime_all.log {,modules/*/}spec/**/*_spec.rb"
	cleanup
}

export -f cleanup execute execute_quiet run_psql create_db_cluster reset_dbs setup_tests setup_hocuspocus start_hocuspocus backend_stuff frontend_stuff run_units run_features run_all

if [ "$1" == "setup-tests" ]; then
	shift
	setup_tests
fi

if [ "$1" == "run-units" ]; then
	shift
	run_units
fi

if [ "$1" == "run-features" ]; then
	shift
	run_features
fi

if [ "$1" == "run-all" ]; then
	shift
	run_all
fi

if [ ! -z "$1" ] ; then
	exec "$@"
fi
