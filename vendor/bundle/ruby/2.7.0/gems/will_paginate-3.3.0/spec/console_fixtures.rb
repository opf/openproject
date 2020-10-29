require 'bundler'
Bundler.setup

require 'will_paginate/active_record'
require 'finders/activerecord_test_connector'

ActiverecordTestConnector.setup

windows = RUBY_PLATFORM =~ /(:?mswin|mingw)/
# used just for the `color` method
log_subscriber = ActiveSupport::LogSubscriber.log_subscribers.first

IGNORE_SQL = /\b(sqlite_master|sqlite_version)\b|^(CREATE TABLE|PRAGMA)\b/

ActiveSupport::Notifications.subscribe(/^sql\./) do |*args|
  data = args.last
  unless data[:name] =~ /^Fixture/ or data[:sql] =~ IGNORE_SQL
    if windows
      puts data[:sql]
    else
      puts log_subscriber.send(:color, data[:sql], :cyan)
    end
  end
end

# load all fixtures
ActiverecordTestConnector::Fixtures.create_fixtures \
  ActiverecordTestConnector::FIXTURES_PATH, ActiveRecord::Base.connection.tables
