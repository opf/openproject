#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
require "factory_bot"
require "factory_bot_rails"
require "rspec/rails"
require "shoulda/matchers"

# Require test_prof helpers for better performance around factories/specs
# see https://test-prof.evilmartians.io for all options.
require "test_prof/recipes/rspec/before_all"
require "test_prof/recipes/rspec/let_it_be"
require "test_prof/recipes/rspec/factory_default"
# Encourages fixing factories as soon as possible
require "test_prof/factory_prof/nate_heckler"
# Allows sampling a random set of specs or example groups for profiling.
require "test_prof/recipes/rspec/sample"

# Add PaperTrail integration so that it is disabled by default
# https://github.com/paper-trail-gem/paper_trail#7b-rspec
require "paper_trail/frameworks/rspec"

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# The files are sorted before requiring them to ensure the load order is the same
# everywhere. There are certain helpers that depend on a expected order.
# The CI may load the files in a different order than what you see locally which
# may lead to broken specs on the CI, if we don't sort here
# (example: with_config.rb has to precede with_direct_uploads.rb).
#
require_relative "support/parallel_helper"
require_relative "support/download_list"
require_relative "support/capybara"
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require_relative f }
Dir[Rails.root.join("spec/features/support/**/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("spec/lib/api/v3/support/**/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("spec/requests/api/v3/support/**/*.rb")].sort.each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema! unless ENV["CI"]

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [Rails.root.join("spec/fixtures").to_s]

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  # Add helpers to parse json-responses
  config.include JsonSpec::Helpers

  # Add job helper
  # Only the ActiveJob::TestHelper is actually used but it in turn requires
  # e.g. assert_nothing_raised
  config.include ActiveSupport::Testing::Assertions
  config.include ActiveJob::TestHelper

  OpenProject::Configuration["attachments_storage_path"] = "tmp/files"
end
