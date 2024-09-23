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

RSpec.describe "API v3 versions available projects resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    create(:user)
  end
  let(:own_member) do
    create(:member,
           roles: [create(:project_role, permissions:)],
           project:,
           user: current_user)
  end
  let(:permissions) { %i[view_versions manage_versions] }
  let(:manage_project) do
    create(:project).tap do |p|
      create(:member,
             roles: [create(:project_role, permissions:)],
             project: p,
             user: current_user)
    end
  end
  let(:view_project) do
    create(:project).tap do |p|
      create(:member,
             roles: [create(:project_role, permissions: [:view_versions])],
             project: p,
             user: current_user)
    end
  end
  # let(:membered_project) do
  #  create(:project).tap do |p|
  #    create(:member,
  #                      roles: [create(:project_role, permissions: permissions)],
  #                      project: p,
  #                      user: current_user)

  #    create(:member,
  #                      roles: [create(:project_role, permissions: permissions)],
  #                      project: p,
  #                      user: other_user)
  #  end
  # end
  let(:unauthorized_project) do
    create(:public_project)
  end

  subject(:response) { last_response }

  describe "GET api/v3/versions/available_projects" do
    let(:projects) { [manage_project, view_project, unauthorized_project] }
    let(:path) { api_v3_paths.versions_available_projects }

    before do
      projects
      login_as(current_user)

      get path
    end

    context "without params" do
      it "responds 200 OK" do
        expect(subject.status).to eq(200)
      end

      it "returns a collection of projects containing only the ones for which the user has :manage_versions permission" do
        expect(subject.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("1")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql(manage_project.id.to_json)
          .at_path("_embedded/elements/0/id")
      end
    end

    context "without permissions" do
      let(:permissions) { [:view_versions] }

      it "returns a 403" do
        expect(subject.status)
          .to eq(403)
      end
    end
  end
end
