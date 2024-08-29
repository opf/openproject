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

RSpec.describe "API v3 time entries available projects resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    create(:user)
  end
  let(:other_user) do
    create(:user)
  end
  let(:project_with_log_permission) do
    create(:project).tap do |p|
      create(:member,
             roles: [create(:project_role, permissions: [:log_own_time])],
             project: p,
             user: current_user)
      create(:work_package, project: p, author: current_user)
    end
  end
  let(:project_with_edit_permission) do
    create(:project).tap do |p|
      create(:member,
             roles: [create(:project_role, permissions: [:edit_time_entries])],
             project: p,
             user: current_user)
    end
  end
  let(:project_with_edit_own_permission) do
    create(:project).tap do |p|
      create(:member,
             roles: [create(:project_role, permissions: [:edit_own_time_entries])],
             project: p,
             user: current_user)
      create(:work_package, project: p, author: current_user)
    end
  end
  let(:project_with_view_permission) do
    create(:project).tap do |p|
      create(:member,
             roles: [create(:project_role, permissions: [:view_time_entries])],
             project: p,
             user: current_user)
    end
  end
  let(:project_without_permission) do
    create(:project).tap do |p|
      create(:member,
             roles: [create(:project_role, permissions: [])],
             project: p,
             user: current_user)
    end
  end
  let(:project_without_membership) do
    create(:project)
  end

  subject(:response) { last_response }

  describe "GET api/v3/time_entries/available_projects" do
    let(:projects) do
      [project_with_log_permission,
       project_with_edit_permission,
       project_with_edit_own_permission,
       project_with_view_permission,
       project_without_permission,
       project_without_membership]
    end
    let(:path) { api_v3_paths.path_for(:time_entries_available_projects, sort_by: [%w(id asc)]) }

    before do
      projects

      login_as(current_user)

      get path
    end

    it "responds 200 OK" do
      expect(subject.status).to eq(200)
    end

    it "returns a collection of projects containing only the ones for which the user has the necessary permissions" do
      expect(subject.body)
        .to be_json_eql("Collection".to_json)
        .at_path("_type")

      expect(subject.body)
        .to be_json_eql("3")
        .at_path("total")

      expect(subject.body)
        .to be_json_eql(project_with_log_permission.id.to_json)
        .at_path("_embedded/elements/0/id")

      expect(subject.body)
        .to be_json_eql(project_with_edit_permission.id.to_json)
        .at_path("_embedded/elements/1/id")

      expect(subject.body)
        .to be_json_eql(project_with_edit_own_permission.id.to_json)
        .at_path("_embedded/elements/2/id")
    end

    context "without permissions" do
      let(:projects) do
        [project_with_view_permission,
         project_without_permission,
         project_without_membership]
      end

      it "returns a 403" do
        expect(subject.status)
          .to eq(403)
      end
    end
  end
end
