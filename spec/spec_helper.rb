require 'rubygems'

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require 'coveralls'
Coveralls.wear_merged!('rails')

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

require 'rspec/autorun'
require 'rspec/example_disabler'
require 'capybara/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

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
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true

  config.after(:suite) do
    [User, Project, Issue].each do |cls|
      raise "your specs leave a #{cls} in the DB\ndid you use before(:all) instead of before or forget to kill the instances in a after(:all)?" if cls.count > 0
    end
  end
end

# load disable_specs.rbs from plugins
Rails.application.config.plugins_to_test_paths.each do |dir|
  disable_specs_file = File.join(dir, 'spec', 'disable_specs.rb')
  if File.exists?(disable_specs_file)
    puts 'Loading ' + disable_specs_file
    require disable_specs_file
  end
end
