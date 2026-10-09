# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module RackTestHelper
  include Rack::Test::Methods

  def app
    Rails.application
  end
end

module CapybaraPage
  def page
    Capybara.string(response.body)
  end
end

RSpec.configure do |config|
  # Use Rack::Test for regular request specs (esp. API requests)
  config.include RackTestHelper, type: :request

  # If desired, we can use the Rails IntegrationTest request spec
  # (more like a feature spec) with this type.
  config.include RSpec::Rails::RequestExampleGroup, type: :rails_request
  config.include Capybara::RSpecMatchers, type: :rails_request
  config.include CapybaraPage, type: :rails_request
end
