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

require "spec_helper"

RSpec.describe SecurityBadgeHelper do
  describe "#security_badge_url" do
    before do
      # can't use with_settings since Setting.installation_uuid has a custom implementation
      allow(Setting).to receive(:installation_uuid).and_return "abcd1234"
    end

    it "generates a URL with the release API path and the details of the installation" do
      uri = URI.parse(helper.security_badge_url)
      query = Rack::Utils.parse_nested_query(uri.query)
      expect(uri.host).to eq("releases.openproject.com")
      expect(query.keys).to contain_exactly("uuid", "type", "version", "db", "lang", "ee")
      expect(query["uuid"]).to eq("abcd1234")
      expect(query["version"]).to eq(OpenProject::VERSION.to_semver)
      expect(query["type"]).to eq("manual")
      expect(query["ee"]).to eq("false")
    end
  end
end
