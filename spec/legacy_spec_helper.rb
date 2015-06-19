#-- encoding: UTF-8
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

ENV['RAILS_ENV'] = 'test'

require 'simplecov'

require File.expand_path('../../config/environment', __FILE__)

require 'fileutils'
require 'rspec/mocks'
require 'factory_girl_rails'

require_relative './support/file_helpers'
require_relative './legacy/support/legacy_assertions'

require_relative './legacy/support/object_daddy_helpers'
include ObjectDaddyHelpers

require 'rspec/rails'
require 'shoulda/matchers'
require 'rspec/example_disabler'

RSpec.configure do |config|
  config.expect_with :rspec, :minitest

  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false

  config.include LegacyAssertionsAndHelpers
  config.include ActiveSupport::Testing::Assertions
  config.include Shoulda::Context::Assertions
  # included in order to use #fixture_file_upload
  config.include ActionDispatch::TestProcess

  config.include RSpec::Rails::RequestExampleGroup, file_path: %r(spec/legacy/integration)
  config.include Shoulda::Matchers::ActionController, file_path: %r(spec/legacy/integration)
  config.extend Shoulda::Matchers::ActionController, file_path: %r(spec/legacy/integration)
  config.include(Module.new {
    extend ActiveSupport::Concern

    # FIXME: hack to ensure subject is an ActionDispatch::TestResponse (RSpec-port)
    included do
      subject { self }
    end
  }, file_path: %r(spec/legacy/integration))

  config.before(:suite) do |example|
    Delayed::Worker.delay_jobs = false

    OpenProject::Configuration['attachments_storage_path'] = 'tmp/files'
  end

  config.before(:each) do
    reset_global_state!

    initialize_attachments

    I18n.locale = 'en'
  end
end
