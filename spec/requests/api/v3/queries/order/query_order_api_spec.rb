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

require "spec_helper"
require "rack/test"

RSpec.describe "/api/v3/queries/:id/order" do
  let(:user) { create(:admin) }
  let(:query) { create(:query, name: "A Query", user:) }
  let(:path) { "/api/v3/queries/#{query.id}/order" }

  subject(:body) { JSON.parse(last_response.body) }

  before do
    login_as user
    header "Content-Type", "application/json"
  end

  describe "with order present" do
    let(:wp1) { create(:work_package) }
    let(:wp2) { create(:work_package) }

    before do
      query.ordered_work_packages.create(work_package_id: wp1.id, position: 0)
      query.ordered_work_packages.create(work_package_id: wp2.id, position: 8192)
    end

    it "returns the order" do
      get path

      expect(last_response).to have_http_status :ok
      expect(body).to be_a Hash
      expect(body).to eq({ wp1.id => 0, wp2.id => 8192 }.stringify_keys)
    end
  end

  describe "#patch" do
    let!(:wp1) { create(:work_package) }
    let!(:wp2) { create(:work_package) }

    let(:timestamp) { API::V3::Utilities::DateTimeFormatter.format_datetime(query.updated_at) }

    before do
      query.ordered_work_packages.create(work_package_id: wp1.id, position: 0)
    end

    it "allows inserting a delta" do
      patch path, { delta: { wp2.id.to_s => 1234 } }.to_json
      expect(last_response).to have_http_status :ok

      query.reload
      expect(body).to eq("t" => timestamp)
      expect(query.ordered_work_packages.find_by(work_package: wp2).position).to eq 1234
    end

    it "allows removing an item" do
      patch path, { delta: { wp1.id.to_s => -1 } }.to_json
      expect(last_response).to have_http_status :ok

      query.reload
      expect(body).to eq("t" => timestamp)
      expect(query.ordered_work_packages.to_a).to be_empty
    end
  end
end
