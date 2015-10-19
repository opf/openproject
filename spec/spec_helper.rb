#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'rubygems'

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start 'rails'
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'
require 'rspec/example_disabler'
require 'capybara/rails'
require 'capybara-screenshot/rspec'
require 'factory_girl_rails'
require 'webmock/rspec'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
Dir[Rails.root.join('spec/features/support/**/*.rb')].each { |f| require f }
Dir[Rails.root.join('spec/lib/api/v3/support/**/*.rb')].each { |f| require f }
Dir[Rails.root.join('spec/requests/api/v3/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  #
  # Taken from http://stackoverflow.com/questions/21922046/deadlock-detected-with-capybara-webkit
  # which replaces the one we had before taken from http://stackoverflow.com/a/13234966
  # Thanks a lot!
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation
  end

  config.before(:each) do |example|
    DatabaseCleaner.strategy = if example.metadata[:js]
                                 # JS => doesn't share connections => can't use transactions
                                 # as of database_cleaner 1.4 'deletion' causes error:
                                 # 'column "table_rows" does not exist'
                                 # https://github.com/DatabaseCleaner/database_cleaner/issues/345
                                 :truncation
                               else
                                 # No JS/Devise => run with Rack::Test => transactions are ok
                                 :transaction
                               end

    DatabaseCleaner.start
    ActionMailer::Base.deliveries.clear
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # As we're using WebMock to mock and test remote HTTP requests,
  # we require specs to selectively enable mocking of Net::HTTP et al. when the example desires.
  # Otherwise, all requests are being mocked by default.
  WebMock.disable!

  # When we enable webmock, no connections other than stubbed ones are allowed.
  # We will exempt local connections from this block, since selenium etc.
  # uses localhost to communicate with the browser.
  # Leaving this off will randomly fail some specs with WebMock::NetConnectNotAllowedError
  WebMock.disable_net_connect!(allow_localhost: true)

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.run_all_when_everything_filtered = true

  # add helpers to parse json-responses
  config.include JsonSpec::Helpers

  config.include ::Angular::DSL

  Capybara.default_wait_time = 4

  config.after(:each) do
    OpenProject::RspecCleanup.cleanup
  end

  config.after(:suite) do
    # We don't want this to be reported on CI as it breaks the build
    unless ENV['CI']
      [User, Project, WorkPackage].each do |cls|
        raise "your specs left a #{cls} in the DB\ndid you use before(:all) instead of before or forget to kill the instances in a after(:all)?" if cls.count > 0
      end
    end
  end

  config.mock_with :rspec do |c|
    c.yield_receiver_to_any_instance_implementation_blocks = true
  end

  # include spec/api for API request specs
  config.include RSpec::Rails::RequestExampleGroup, type: :request

  # colorized rspec output
  config.color = true
end

# Loads two files automatically from plugins:
#
# 1. `spec/disable_specs.rbs` to disable specs which don't work in conjunction with the
# respective plugin.
# 2. The config spec helper in `spec/config_spec_helper` makes sure that the core specs
# (and other plugins' specs) keep working with this plugin in an OpenProject configuration
# even if it changes things which would otherwise break existing specs.
Rails.application.config.plugins_to_test_paths.each do |dir|
  ['disable_specs.rb', 'config_spec_helper.rb'].each do |file_name|
    file = File.join(dir, 'spec', file_name)

    if File.exists?(file)
      puts "Loading #{file}"
      require file
    end
  end
end

require 'rack_session_access/capybara'
Rails.application.config do
  config.middleware.use RackSessionAccess::Middleware
end

module OpenProject::RspecCleanup
  def self.cleanup
    # Cleanup after specs changing locale explicitly or
    # by calling code in the app setting changing the locale.
    I18n.locale = :en

    # Set the class instance variable @current_user to nil
    # to avoid having users from one spec present in the next
    ::User.instance_variable_set(:@current_user, nil)
  end
end

OpenProject::Configuration['attachments_storage_path'] = 'tmp/files'
