#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

ENV["RAILS_ENV"] = "test"

if ENV['CI'] == 'true'
  # we are running on a CI server, report coverage to code climate
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'fileutils'
require 'rspec/mocks'

require File.expand_path(File.dirname(__FILE__) + '/helper_testcase')

require File.expand_path(File.dirname(__FILE__) + '/object_daddy_helpers')
include ObjectDaddyHelpers

require_relative './support/legacy_assertions'

require 'rspec/rails'
require 'rspec/autorun'
require 'rspec/example_disabler'

RSpec.configure do |config|
  config.expect_with :rspec, :stdlib

  config.fixture_path = "#{::Rails.root}/test/fixtures"
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.global_fixtures = :all
  config.include LegacyAssertionsAndHelpers
  config.include ActiveSupport::Testing::Assertions
  config.include Shoulda::Context::Assertions
  # included in order to use #fixture_file_upload
  config.include ActionDispatch::TestProcess
  # config.include RSpec::Rails::ModelExampleGroup, file_path: ''

  config.include RSpec::Rails::ControllerExampleGroup, example_group: { file_path: %r(test/functional) }
  config.include Shoulda::Matchers::ActionController,  example_group: { file_path: %r(test/functional) }
  config.extend  Shoulda::Matchers::ActionController,  example_group: { file_path: %r(test/functional) }

  config.include RSpec::Rails::RequestExampleGroup,   example_group: { file_path: %r(test/integration) }
  config.include Shoulda::Matchers::ActionController, example_group: { file_path: %r(test/integration) }
  config.extend  Shoulda::Matchers::ActionController, example_group: { file_path: %r(test/integration) }
  config.include(Module.new {
    extend ActiveSupport::Concern

    # FIXME: hack to ensure subject is an ActionDispatch::TestResponse (RSpec-port)
    included do
      subject { self }
    end
  }, example_group: { file_path: %r(test/integration) })

  config.before(:suite) do
    Delayed::Worker.delay_jobs = false
  end

end
