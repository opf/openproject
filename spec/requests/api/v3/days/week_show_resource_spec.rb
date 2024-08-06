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

RSpec.describe API::V3::Days::WeekAPI,
               "show",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:path) { api_v3_paths.days_week_day(1) }

  current_user { user }
  subject { last_response.body }

  before do
    get path
  end

  context "for an admin user" do
    let(:user) { build(:admin) }

    it_behaves_like "successful response"

    it "responds with the correct day" do
      expect(subject).to be_json_eql("WeekDay".to_json).at_path("_type")
      expect(subject).to be_json_eql(1.to_json).at_path("day")
    end

    context "when requesting nonexistent day" do
      let(:path) { api_v3_paths.days_week_day(0) }

      it_behaves_like "not found"
    end
  end

  context "for a not logged in user" do
    let(:user) { build(:anonymous) }

    context "when login_required", with_settings: { login_required: true } do
      it_behaves_like "unauthenticated access"
    end

    context "when not login_required", with_settings: { login_required: false } do
      it_behaves_like "successful response"

      it "responds with the correct day", :aggregate_failures do
        expect(subject).to be_json_eql("WeekDay".to_json).at_path("_type")
        expect(subject).to be_json_eql(1.to_json).at_path("day")
      end
    end
  end
end
