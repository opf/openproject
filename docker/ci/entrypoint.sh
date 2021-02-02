#!/bin/bash
set -e

export PGBIN="$(pg_config --bindir)"
# for parallel rspec
export PARALLEL_TEST_PROCESSORS=$JOBS

# if from within docker
if [ $(id -u) -eq 0 ]; then
	if [ ! -d "/tmp/nulldb" ]; then
		su - postgres -c "$PGBIN/initdb -E UTF8 -D /tmp/nulldb"
		su - postgres -c "$PGBIN/pg_ctl -D /tmp/nulldb -l /dev/null -w start"
		echo "create database app; create user app with superuser encrypted password 'p4ssw0rd'; grant all privileges on database app to app;" | su - postgres -c psql
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

if [ "$1" == "setup-tests" ]; then
	echo "Preparing environment for running tests..."
	shift

	execute "cp docker/ci/database.yml config/"

	for i in $(seq 0 $JOBS); do
		folder="$CAPYBARA_DOWNLOADED_FILE_DIR/$i"
		echo "Creating folder $folder..."
		rm -rf "$folder"
		mkdir -p "$folder"
		chmod 1777 "$folder"
	done

	execute "time bundle install -j$JOBS"
	execute "TEST_ENV_NUMBER=0 time bundle exec rake db:create db:migrate db:schema:dump webdrivers:chromedriver:update webdrivers:geckodriver:update"
	execute "time bundle exec rake parallel:create parallel:load_schema"
fi

if [ "$1" == "run-units" ]; then
	shift
	execute "cd frontend && npm install && npm run test"
	execute "time bundle exec rspec -I spec_legacy spec_legacy"
	execute "time bundle exec rake parallel:units"
	if [ ! $? -eq 0 ]; then
		execute "cat tmp/spec_examples.txt | grep -Ev 'passed|unknown|pending'"
		exit 1
	fi
fi

if [ "$1" == "run-features" ]; then
	shift
	execute "cd frontend; npm install ; cd -"
	execute "bundle exec rake assets:precompile assets:clean"
	execute "cp -rp config/frontend_assets.manifest.json public/assets/frontend_assets.manifest.json"
	execute "time bundle exec rake parallel:features"
	if [ ! $? -eq 0 ]; then
		execute "cat tmp/spec_examples.txt | grep -Ev 'passed|unknown|pending'"
		exit 1
	fi
fi

if [ ! -z "$1" ] ; then
	exec "$@"
fi
