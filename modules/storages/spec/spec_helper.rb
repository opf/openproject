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

# This is the RSpec main include file that is included in basically every test case below.
# See also: https://rspec.info/

# Loads spec_helper from OpenProject core
# This will include any support file from OpenProject core
require "spec_helper"
require "dry/container/stub"

STORAGES_CASSETTE_LIBRARY_DIR = "modules/storages/spec/support/fixtures/vcr_cassettes"

# Record Storages Cassettes in module
VCR.configure do |config|
  config.filter_sensitive_data("<ACCESS_TOKEN>") do
    ENV.fetch("ONE_DRIVE_TEST_OAUTH_CLIENT_ACCESS_TOKEN", "MISSING_ONE_DRIVE_TEST_OAUTH_CLIENT_ACCESS_TOKEN")
  end
  config.filter_sensitive_data("<ACCESS_TOKEN>") do
    ENV.fetch("NEXTCLOUD_LOCAL_OAUTH_CLIENT_ACCESS_TOKEN", "MISSING_NEXTCLOUD_LOCAL_OAUTH_CLIENT_ACCESS_TOKEN")
  end
end

def use_storages_vcr_cassette(name, options = {}, &)
  WebMock.enable! && VCR.turn_on!
  VCR.configure do |vcr_config|
    vcr_config.cassette_library_dir = STORAGES_CASSETTE_LIBRARY_DIR
  end
  VCR.use_cassette(name, options, &)
ensure
  VCR.turn_off! && WebMock.disable!
end

# Loads files from relative support/ directory
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.prepend_before { Storages::Peripherals::Registry.enable_stubs! }
  config.append_after { Storages::Peripherals::Registry.unstub }

  config.define_derived_metadata(file_path: %r{/modules/storages/spec}) do |metadata|
    metadata[:vcr_cassette_library_dir] = STORAGES_CASSETTE_LIBRARY_DIR
  end
end
