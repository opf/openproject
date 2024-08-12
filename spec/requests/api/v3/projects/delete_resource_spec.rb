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

RSpec.describe "API v3 Project resource delete", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) do
    create(:project, public: false)
  end
  let(:role) { create(:project_role) }
  let(:path) { api_v3_paths.project(project.id) }
  let(:setup) do
    # overwritten in some examples
  end
  let(:member_user) { create(:user, member_with_roles: { project => role }) }

  current_user { create(:admin) }

  before do
    setup
    member_user

    delete path

    # run the deletion job
    perform_enqueued_jobs
  end

  subject { last_response }

  context "with required permissions (admin)" do
    it "responds with HTTP No Content" do
      expect(subject.status).to eq 204
    end

    it "deletes the project" do
      expect(Project).not_to exist(project.id)
    end

    context "for a project with work packages" do
      let(:work_package) { create(:work_package, project:) }
      let(:setup) { work_package }

      it "deletes the work packages" do
        expect(WorkPackage).not_to exist(work_package.id)
      end
    end

    context "for a project with members" do
      let(:member) do
        create(:member,
               project:,
               principal: current_user,
               roles: [create(:project_role)])
      end
      let(:member_role) { member.member_roles.first }
      let(:setup) do
        member
        member_role
      end

      it "deletes the member" do
        expect(Member).not_to exist(member.id)
      end

      it "deletes the MemberRole" do
        expect(MemberRole).not_to exist(member_role.id)
      end
    end

    context "for a project with a forum" do
      let(:forum) do
        create(:forum,
               project:)
      end
      let(:setup) do
        forum
      end

      it "deletes the forum" do
        expect(Forum).not_to exist(forum.id)
      end
    end

    context "for a non-existent project" do
      let(:path) { api_v3_paths.project 0 }

      it_behaves_like "not found"
    end

    context "for a project which has a version foreign work packages refer to" do
      let(:version) { create(:version, project:) }
      let(:work_package) { create(:work_package, version:) }

      let(:setup) { work_package }

      it "responds with 422" do
        expect(subject.status).to eq 422
      end

      it "explains the error" do
        expect(subject.body)
          .to be_json_eql(I18n.t(:"activerecord.errors.models.project.foreign_wps_reference_version").to_json)
                .at_path("message")
      end
    end
  end

  context "without required permissions" do
    current_user { member_user }

    it "responds with 403" do
      expect(subject.status).to eq 403
    end
  end
end
