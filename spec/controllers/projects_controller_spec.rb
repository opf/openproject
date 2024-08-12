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

RSpec.describe ProjectsController do
  shared_let(:admin) { create(:admin) }
  let(:non_member) { create(:non_member) }

  before do
    allow(controller).to receive(:set_localization)

    login_as admin
  end

  describe "#new" do
    it "renders 'new'" do
      get "new"
      expect(response).to be_successful
      expect(response).to render_template "new"
    end

    context "by non-admin user with add_project permission" do
      let(:non_member_user) { create(:user) }

      before do
        non_member.add_permission! :add_project
        login_as non_member_user
      end

      it "accepts get" do
        get :new
        expect(response).to be_successful
        expect(response).to render_template "new"
      end
    end
  end

  describe "index.html" do
    shared_let(:project_a) { create(:project, name: "Project A", public: false, active: true) }
    shared_let(:project_b) { create(:project, name: "Project B", public: false, active: true) }
    shared_let(:project_c) { create(:project, name: "Project C", public: true, active: true) }
    shared_let(:project_d) { create(:project, name: "Project D", public: true, active: false) }

    before do
      ProjectRole.anonymous
      ProjectRole.non_member

      login_as(user)
      get "index"
    end

    shared_examples_for "successful index" do
      it "is success" do
        expect(response).to be_successful
      end

      it "renders the index template" do
        expect(response).to render_template "index"
      end
    end
  end

  describe "#destroy" do
    render_views

    let(:project) { build_stubbed(:project) }
    let(:request) { delete :destroy, params: { id: project.id } }

    let(:service_result) { ServiceResult.new(success:) }

    before do
      allow(Project).to receive(:find).and_return(project)
      deletion_service = instance_double(Projects::ScheduleDeletionService,
                                         call: service_result)

      allow(Projects::ScheduleDeletionService)
        .to receive(:new)
              .with(user: admin, model: project)
              .and_return(deletion_service)
    end

    context "when service call succeeds" do
      let(:success) { true }

      it "prints success" do
        request
        expect(response).to be_redirect
        expect(flash[:notice]).to be_present
      end
    end

    context "when service call fails" do
      let(:success) { false }

      it "prints fail" do
        request
        expect(response).to be_redirect
        expect(flash[:error]).to be_present
      end
    end
  end

  describe "with an existing project" do
    let(:project) { create(:project, identifier: "blog") }

    it "gets destroy info" do
      get :destroy_info, params: { id: project.id }
      expect(response).to be_successful
      expect(response).to render_template "destroy_info"

      expect { project.reload }.not_to raise_error
    end
  end

  describe "#copy" do
    let(:project) { create(:project, identifier: "blog") }

    it "renders 'copy'" do
      get "copy", params: { id: project.id }
      expect(response).to be_successful
      expect(response).to render_template "copy"
    end

    context "as non authorized user" do
      let(:user) { build_stubbed(:user) }

      before do
        login_as user
      end

      it "shows an error" do
        get "copy", params: { id: project.id }
        expect(response).to have_http_status :forbidden
      end
    end
  end
end
