#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

ENV['RAILS_ENV'] = 'test'

require File.expand_path('../../config/environment', __FILE__)

require 'fileutils'
require 'rspec/mocks'
require 'factory_bot_rails'

require_relative './support/legacy_file_helpers'
require_relative './support/legacy_assertions'

require 'rspec/rails'
require 'shoulda/matchers'

# Required shared support helpers from spec/
Dir[Rails.root.join('spec/support/shared/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec, :minitest

  config.fixture_path = "#{::Rails.root}/spec_legacy/fixtures"

  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false

  config.include LegacyAssertionsAndHelpers
  config.include ActiveSupport::Testing::Assertions
  config.include Shoulda::Context::Assertions
  # included in order to use #fixture_file_upload
  config.include ActionDispatch::TestProcess

  config.include RSpec::Rails::RequestExampleGroup,   file_path: %r(spec_legacy/integration)
  config.include Shoulda::Matchers::ActionController, file_path: %r(spec_legacy/integration)
  config.extend Shoulda::Matchers::ActionController, file_path: %r(spec_legacy/integration)

  config.include(Module.new do
    extend ActiveSupport::Concern

    # FIXME: hack to ensure subject is an ActionDispatch::TestResponse (RSpec-port)
    included do
      subject { self }
    end
  end, file_path: %r(spec_legacy/integration))

  config.before(:suite) do |_example|
    Delayed::Worker.delay_jobs = false

    OpenProject::Configuration['attachments_storage_path'] = 'tmp/files'
  end

  config.before(:each) do
    reset_global_state!

    initialize_attachments

    I18n.locale = 'en'
  end

  # colorized rspec output
  config.color = true
  config.formatter = 'progress'
end
