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
#++

require "httpx/adapters/webmock"
require "webmock/rspec"

RSpec.configure do |config|
  config.before(:suite) do
    # As we're using WebMock to mock and test remote HTTP requests,
    # we require specs to selectively enable mocking of Net::HTTP et al. when the example desires.
    # Otherwise, all requests are being mocked by default.
    WebMock.disable!
  end

  config.around(:example, :webmock) do |example|
    # When we enable webmock, no connections other than stubbed ones are allowed.
    # We will exempt:
    # * local connections, since selenium etc. uses localhost to communicate with the browser.
    #   Leaving this off will randomly fail some specs with WebMock::NetConnectNotAllowedError
    # * chromedriver, since it might need to be downloaded
    WebMock.disable_net_connect!(
      allow_localhost: true, allow: [
        "selenium-hub",
        Capybara.server_host,
        "chromedriver.storage.googleapis.com",
        "openproject-ci-public-logs.s3.eu-west-1.amazonaws.com",
        "cuprite-chrome"
      ]
    )
    WebMock.enable!
    example.run
  ensure
    WebMock.allow_net_connect!
    WebMock.disable!
  end
end
