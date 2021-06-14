#!/bin/bash
set -e

export PGBIN="/usr/lib/postgresql/$PGVERSION/bin"
export JOBS="${CI_JOBS:=$(nproc)}"
# for parallel rspec
export PARALLEL_TEST_PROCESSORS=$JOBS

# if from within docker
if [ $(id -u) -eq 0 ]; then
	if [ ! -d "/tmp/nulldb" ]; then
		su - postgres -c "$PGBIN/initdb -E UTF8 -D /tmp/nulldb"
		su - postgres -c "$PGBIN/pg_ctl -D /tmp/nulldb -l /dev/null -w start"
		echo "create database app; create user app with superuser encrypted password 'p4ssw0rd'; grant all privileges on database app to app;" | su - postgres -c $PGBIN/psql
	fi

	mkdir -p /usr/local/bundle
	mkdir -p /home/$USER/openproject/frontend/node_modules
	mkdir -p /home/$USER/openproject/tmp
	chown $USER:$USER /usr/local/bundle
	chown $USER:$USER /home/$USER/openproject/frontend/node_modules
	chown $USER:$USER /home/$USER/openproject/tmp
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
}

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
	execute "TEST_ENV_NUMBER=0 time bundle exec rake db:create db:migrate db:schema:dump webdrivers:chromedriver:update webdrivers:geckodriver:update openproject:plugins:register_frontend"
	execute "time bundle exec rake parallel:create parallel:load_schema"
fi

if [ "$1" == "run-units" ]; then
	shift
	execute "cd frontend && npm install && npm run test"
	execute "time bundle exec rspec -I spec_legacy spec_legacy"
	if ! execute "time bundle exec rake parallel:units" ; then
		execute "cat tmp/parallel_summary.log"
		cleanup
		exit 1
	else
		cleanup
		exit 0
	fi
fi

if [ "$1" == "run-features" ]; then
	shift
	execute "cd frontend; npm install ; cd -"
	execute "bundle exec rake assets:precompile"
	execute "cp -rp config/frontend_assets.manifest.json public/assets/frontend_assets.manifest.json"
	if ! execute "time bundle exec rake parallel:features" ; then
		execute "cat tmp/parallel_summary.log"
		cleanup
		exit 1
	else
		cleanup
		exit 0
	fi
fi

if [ ! -z "$1" ] ; then
	exec "$@"
fi
