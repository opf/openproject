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
require "rack/test"

RSpec.describe "API v3 time_entry_activity resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:activity) { create(:time_entry_activity) }
  let(:project) { create(:project) }
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i(view_time_entries) }

  subject(:response) { last_response }

  before do
    login_as(current_user)
  end

  describe "GET /api/v3/time_entries/activities/:id" do
    let(:path) { api_v3_paths.time_entries_activity(activity.id) }

    context "for a visible root activity" do
      before do
        activity

        get path
      end

      it "returns 200 OK" do
        expect(subject.status)
          .to be(200)
      end

      it "returns the time entry" do
        expect(subject.body)
          .to be_json_eql("TimeEntriesActivity".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql(activity.id.to_json)
          .at_path("id")
      end
    end

    context "for non shared activities" do
      before do
        activity.project_id = 234
        activity.save(validate: false)

        get path
      end

      it "returns 404 NOT FOUND" do
        expect(subject.status)
          .to be(404)
      end
    end

    context "when lacking permissions" do
      let(:permissions) { [] }

      before do
        activity

        get path
      end

      it "returns 404 NOT FOUND" do
        expect(subject.status)
          .to be(404)
      end
    end
  end
end
