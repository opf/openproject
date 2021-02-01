#!/bin/bash
set -e

export RUBYOPT="-W0"
export PGBIN="$(pg_config --bindir)"
export JOBS=${JOBS:=$(nproc)}
export RAILS_ENV=test
export CI=true
export OPENPROJECT_DISABLE_DEV_ASSET_PROXY=1
export CAPYBARA_DYNAMIC_HOSTNAME=0
export CAPYBARA_DOWNLOADED_FILE_DIR=${CAPYBARA_DOWNLOADED_FILE_DIR:="/tmp"}
export DATABASE_URL=${DATABASE_URL:="postgres://app:p4ssw0rd@127.0.0.1/app"}
# for parallel rspec
export PARALLEL_TEST_PROCESSORS=$JOBS

CHROME_SOURCE_URL=https://dl.google.com/dl/linux/direct/google-chrome-stable_current_amd64.deb

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

if [ "$1" == "setup-system" ]; then
	echo "Downloading and installing required browsers..."
	shift
	apt install -y imagemagick default-jre-headless postgresql libpq-dev sudo
	wget --no-verbose -O /tmp/$(basename $CHROME_SOURCE_URL) $CHROME_SOURCE_URL && \
	  sudo apt install -y /tmp/$(basename $CHROME_SOURCE_URL) && rm -f /tmp/$(basename $CHROME_SOURCE_URL)
fi

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
	execute "TEST_ENV_NUMBER=0 time bundle exec rake db:create db:migrate webdrivers:chromedriver:update webdrivers:geckodriver:update"
	execute "time bundle exec rake parallel:setup"
fi

if [ "$1" == "run-units" ]; then
	shift
	execute "cd frontend && npm install && npm run test"
	execute "time bundle exec rspec -I spec_legacy spec_legacy"
	execute "time bundle exec rake parallel:units"
fi

if [ "$1" == "run-units" ]; then
	shift
	execute "time bundle exec rake parallel:units"
fi

if [ "$1" == "run-features" ]; then
	shift
	execute "cd frontend; npm install ; cd -"
	execute "bundle exec rake assets:precompile assets:clean"
	execute "cp -rp config/frontend_assets.manifest.json public/assets/frontend_assets.manifest.json"
	execute "time bundle exec rake parallel:features"
fi

if [ ! -z "$1" ] ; then
	exec "$@"
fi
