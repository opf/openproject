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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "vcr"
require "httpx"

module VCRTimeoutHelper
  def stub_request_with_timeout(method, path_matcher)
    request_mock = OpenProject.httpx.build_request(method.to_s.upcase, "https://example.com")
    error_response_mock = HTTPX::ErrorResponse.new(request_mock,
                                                   HTTPX::ConnectTimeoutError.new(60, "timed out while waiting on select"))
    allow_any_instance_of(HTTPX::Session).to receive(method.to_sym).with(any_args).and_call_original
    allow_any_instance_of(HTTPX::Session).to receive(method.to_sym).with(path_matcher, any_args).and_return(error_response_mock)
  end
end

VCR.configure do |config|
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.before_record do |i|
    i.response.body.force_encoding("UTF-8")
  end

  config.filter_sensitive_data "<BASIC_AUTH>" do |interaction|
    header = interaction.request.headers["Authorization"]&.first&.split

    header.last if header&.first == "Basic"
  end

  config.filter_sensitive_data "<BEARER TOKEN>" do |interaction|
    header = interaction.request.headers["Authorization"]&.first&.split

    header.last if header&.first == "Bearer"
  end

  config.filter_sensitive_data "<ACCESS_TOKEN>" do |interaction|
    header_value = interaction.response.headers["Content-Type"]&.first

    if header_value&.include?("application/json")
      MultiJson.load(interaction.response.body)["access_token"]
    end
  end

  config.default_cassette_options = {
    record: ENV.fetch("VCR_RECORD_MODE", :once).to_sym,
    allow_playback_repeats: true,
    drop_unused_requests: true
  }
end

VCR.turn_off!

RSpec.configure do |config|
  config.include(VCRTimeoutHelper)
  config.around(:example, :vcr) do |example|
    # Only enable VCR's webmock integration for tests tagged with :vcr otherwise interferes with WebMock
    # See: https://github.com/vcr/vcr/issues/146
    #
    VCR.configure do |vcr_config|
      cassette_library_dir = example.metadata[:vcr_cassette_library_dir] || "spec/support/fixtures/vcr_cassettes"
      vcr_config.cassette_library_dir = cassette_library_dir
    end
    VCR.turn_on!
    example.run
  ensure
    # Switch off VCR to prevent VCR from interfering with other tests
    VCR.turn_off!
  end
end
