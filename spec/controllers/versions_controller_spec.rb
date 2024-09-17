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

RSpec.describe VersionsController do
  let(:user) { create(:admin) }
  let(:project) { create(:public_project) }
  let(:version1) { create(:version, project:, effective_date: nil) }
  let(:version2) { create(:version, project:) }
  let(:version3) { create(:version, project:, effective_date: (Date.today - 14.days)) }

  describe "#index" do
    render_views

    before do
      version1
      version2
      version3
    end

    context "without additional params" do
      before do
        login_as(user)
        get :index, params: { project_id: project.id }
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template("index") }

      subject { assigns(:versions) }

      it "shows Version with no date set" do
        expect(subject.include?(version1)).to be_truthy
      end

      it "shows Version with date set" do
        expect(subject.include?(version2)).to be_truthy
      end

      it "not shows Completed version" do
        expect(subject.include?(version3)).to be_falsey
      end
    end

    context "with showing selected types" do
      let(:type_a) { create(:type) }
      let(:type_b) { create(:type) }

      let(:wp_a) { create(:work_package, type: type_a, project:, version: version1) }
      let(:wp_b) { create(:work_package, type: type_b, project:, version: version1) }

      before do
        project.types = [type_a, type_b]
        project.save!

        [wp_a, wp_b] # create work packages

        login_as(user)
      end

      describe "with all types" do
        before do
          get :index, params: { project_id: project, completed: "1" }
        end

        it { expect(response).to be_successful }
        it { expect(response).to render_template("index") }

        it "shows all work packages" do
          issues_by_version = assigns(:wps_by_version)
          work_packages = issues_by_version[version1]

          expect(work_packages).to include wp_a
          expect(work_packages).to include wp_b
        end
      end

      describe "with selected types" do
        before do
          get :index, params: { project_id: project, completed: "1", type_ids: [type_b.id] }
        end

        it { expect(response).to be_successful }
        it { expect(response).to render_template("index") }

        it "shows only work packages of the selected type" do
          issues_by_version = assigns(:wps_by_version)
          work_packages = issues_by_version[version1]

          expect(work_packages).not_to include wp_a
          expect(work_packages).to include wp_b
        end
      end
    end

    context "with showing completed versions" do
      before do
        login_as(user)
        get :index, params: { project_id: project, completed: "1" }
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template("index") }

      subject { assigns(:versions) }

      it "shows Version with no date set" do
        expect(subject.include?(version1)).to be_truthy
      end

      it "shows Version with date set" do
        expect(subject.include?(version2)).to be_truthy
      end

      it "not shows Completed version" do
        expect(subject.include?(version3)).to be_truthy
      end
    end

    describe "Sub Project Versions" do
      let!(:sub_project) { create(:public_project, parent_id: project.id) }
      let!(:sub_project_version) { create(:version, project: sub_project) }

      current_user { user }

      before do
        get :index, params:
      end

      subject { assigns(:versions) }

      shared_examples "is successful" do
        it { expect(response).to be_successful }
        it { expect(response).to render_template("index") }
      end

      shared_examples "shows versions with and without a date set" do
        it do
          expect(subject).to include(version1, version2)
        end
      end

      shared_examples "shows sub project's' version" do
        it "sets @with_subprojects to true" do
          expect(assigns(:with_subprojects)).to be_truthy
        end

        it "shows sub project's version" do
          expect(subject).to include(sub_project_version)
        end
      end

      shared_examples "does not show sub project's versions" do
        it "sets @with_subprojects to false" do
          expect(assigns(:with_subprojects)).to be_falsey
        end

        it "does not show sub project's version" do
          expect(subject).not_to include(sub_project_version)
        end
      end

      context "when with_subprojects param is set to 1" do
        let(:params) { { project_id: project.id, with_subprojects: 1 } }

        include_examples "is successful"
        include_examples "shows sub project's' version"
      end

      context "when with_subprojects param is set to 0" do
        let(:params) { { project_id: project.id, with_subprojects: 0 } }

        include_examples "is successful"
        include_examples "does not show sub project's versions"
      end

      context "with sub projects included by default",
              with_settings: { display_subprojects_work_packages: true } do
        context "and with_subprojects is not a param" do
          let(:params) { { project_id: project.id } }

          include_examples "is successful"
          include_examples "shows sub project's' version"
        end

        context "and with_subprojects is set to 0" do
          let(:params) { { project_id: project.id, with_subprojects: 0 } }

          include_examples "is successful"
          include_examples "does not show sub project's versions"
        end
      end
    end
  end

  describe "#show" do
    render_views

    before do
      login_as(user)
      version2
      get :show, params: { id: version2.id }
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template("show") }
    it { assert_select "h2", content: version2.name }

    subject { assigns(:version) }

    it { is_expected.to eq(version2) }
  end

  describe "#new" do
    # This spec is here because at one point the `new` action was requiring
    # the `version` key in params, so visiting it without one failed.
    it "renders correctly" do
      login_as(user)
      get :new, params: { project_id: project.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "#create" do
    context "with valid attributes" do
      before do
        login_as(user)
        post :create, params: { project_id: project.id, version: { name: "test_add_version" } }
      end

      it { expect(response).to redirect_to(project_settings_versions_path(project)) }

      it "generates the new version" do
        version = Version.find_by(name: "test_add_version")
        expect(version).not_to be_nil
        expect(version.project).to eq(project)
      end
    end
  end

  describe "#edit" do
    render_views

    before do
      login_as(user)
      version2
      get :edit, params: { id: version2.id }
    end

    context "when resource is found" do
      it { expect(response).to be_successful }
      it { expect(response).to render_template("edit") }
    end
  end

  describe "#close_completed" do
    before do
      login_as(user)
      version1.update_attribute :status, "open"
      version2.update_attribute :status, "open"
      version3.update_attribute :status, "open"
      put :close_completed, params: { project_id: project.id }
    end

    it { expect(response).to redirect_to(project_settings_versions_path(project)) }
    it { expect(Version.find_by(status: "closed")).to eq(version3) }
  end

  describe "#update" do
    context "with valid params" do
      let(:params) do
        {
          id: version1.id,
          version: {
            name: "New version name",
            effective_date: Date.today.strftime("%Y-%m-%d")
          }
        }
      end

      before do
        login_as(user)
        patch :update, params:
      end

      it { expect(response).to redirect_to(project_settings_versions_path(project)) }
      it { expect(Version.find_by(name: "New version name")).to eq(version1) }
      it { expect(version1.reload.effective_date).to eq(Date.today) }
    end

    context "with valid params with a redirect url" do
      before do
        login_as(user)
        patch :update,
              params: {
                id: version1.id,
                version: { name: "New version name",
                           effective_date: Date.today.strftime("%Y-%m-%d") },
                back_url: home_path
              }
      end

      it { expect(response).to redirect_to(home_path) }
    end

    context "with invalid params" do
      before do
        login_as(user)
        patch :update,
              params: {
                id: version1.id,
                version: { name: "",
                           effective_date: Date.today.strftime("%Y-%m-%d") }
              }
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template("edit") }
      it { expect(assigns(:version).errors.symbols_for(:name)).to contain_exactly(:blank) }
    end
  end

  describe "#destroy" do
    before do
      login_as(user)
      @deleted = version3.id
      delete :destroy, params: { id: @deleted }
    end

    it "redirects to projects versions and the version is deleted" do
      expect(response).to redirect_to(project_settings_versions_path(project))
      expect { Version.find(@deleted) }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
