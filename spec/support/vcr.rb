#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'vcr'
VCR.configure do |config|
  config.cassette_library_dir = 'spec/support/fixtures/vcr_cassettes'
  # https://benoittgt.github.io/vcr/#/test_frameworks/rspec_metadata
  config.configure_rspec_metadata!
  config.before_record do |i|
    i.response.body.force_encoding('UTF-8')
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    # As we're using VCR to record and test remote HTTP requests,
    # we require specs to selectively enable recording of HTTP interations.
    # Otherwise, VCR would attempt to intercept all HTTP requests by default.
    VCR.configuration.clear_hooks
    VCR.turn_off!
  end

  config.around(:example, :vcr) do |example|
    VCR.configure do |c|
      # Only enable VCR's webmock integration for tests tagged with :vcr otherwise interferes with WebMock
      c.hook_into :webmock
    end

    VCR.turn_on!
    example.run
  ensure
    # Clear all VCR hooks to prevent VCR from interfering with other tests
    VCR.configuration.clear_hooks
    VCR.turn_off!
  end
end
