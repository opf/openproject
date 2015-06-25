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
require 'simplecov'

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'
require 'rspec/example_disabler'
require 'capybara/rails'
require 'capybara-screenshot/rspec'

Capybara.register_driver :selenium do |app|
  require 'selenium/webdriver'
  Selenium::WebDriver::Firefox::Binary.path = ENV['FIREFOX_BINARY_PATH'] ||
    Selenium::WebDriver::Firefox::Binary.path
  Capybara::Selenium::Driver.new(app, browser: :firefox)
end

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
                                 # truncations seem to fail more often + they are slower
                                 :deletion
                               else
                                 # No JS/Devise => run with Rack::Test => transactions are ok
                                 :transaction
                               end

    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

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
    [User, Project, WorkPackage].each do |cls|
      raise "your specs leave a #{cls} in the DB\ndid you use before(:all) instead of before or forget to kill the instances in a after(:all)?" if cls.count > 0
    end
  end

  config.mock_with :rspec do |c|
    c.yield_receiver_to_any_instance_implementation_blocks = true
  end

  # include spec/api for API request specs
  config.include RSpec::Rails::RequestExampleGroup, type: :request
end

# load disable_specs.rbs from plugins
Rails.application.config.plugins_to_test_paths.each do |dir|
  disable_specs_file = File.join(dir, 'spec', 'disable_specs.rb')
  if File.exists?(disable_specs_file)
    puts 'Loading ' + disable_specs_file
    require disable_specs_file
  end
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
