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

RSpec.describe API::V3::Projects::ProjectRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  subject(:generated) { representer.to_json }

  let(:project) do
    build_stubbed(:project,
                  :with_status,
                  parent: parent_project,
                  description: "some description").tap do |p|
      allow(p).to receive_messages(available_custom_fields: [int_custom_field, version_custom_field],
                                   all_available_custom_fields: [int_custom_field, version_custom_field],
                                   ancestors_from_root: ancestors)

      allow(p)
        .to receive(int_custom_field.attribute_getter)
              .and_return(int_custom_value.value)

      allow(p)
        .to receive(:custom_value_for)
              .with(version_custom_field)
              .and_return(version_custom_value)
    end
  end

  let(:int_custom_field) { build_stubbed(:integer_project_custom_field, admin_only: true) }
  let(:version_custom_field) { build_stubbed(:version_project_custom_field, admin_only: false) }
  let(:int_custom_value) do
    CustomValue.new(custom_field: int_custom_field,
                    value: "1234",
                    customized: nil)
  end
  let(:version) { build_stubbed(:version) }
  let(:version_custom_value) do
    CustomValue.new(custom_field: version_custom_field,
                    value: version.id,
                    customized: nil).tap do |cv|
      allow(cv)
        .to receive(:typed_value)
              .and_return(version)
    end
  end
  let(:permissions) { %i[view_project add_work_packages view_members] }
  let(:parent_project) do
    build_stubbed(:project).tap do |parent|
      allow(parent)
        .to receive(:visible?)
              .and_return(parent_visible)
    end
  end
  let(:representer) { described_class.create(project, current_user: user, embed_links: true) }
  let(:parent_visible) { true }
  let(:ancestors) { [parent_project] }

  let(:user) { build_stubbed(:user) }

  before do
    mock_permissions_for(user) do |mock|
      mock.allow_in_project *permissions, project:
    end
  end

  it { is_expected.to include_json("Project".to_json).at_path("_type") }

  describe "properties" do
    it_behaves_like "property", :_type do
      let(:value) { "Project" }
    end

    it_behaves_like "property", :id do
      let(:value) { project.id }
    end

    it_behaves_like "property", :identifier do
      let(:value) { project.identifier }
    end

    it_behaves_like "property", :name do
      let(:value) { project.name }
    end

    it_behaves_like "property", :active do
      let(:value) { project.active }
    end

    it_behaves_like "property", :public do
      let(:value) { project.public }
    end

    it_behaves_like "formattable property", :description do
      let(:value) { project.description }
    end

    it_behaves_like "formattable property", "statusExplanation" do
      let(:value) { project.status_explanation }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { project.created_at }
      let(:json_path) { "createdAt" }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { project.updated_at }
      let(:json_path) { "updatedAt" }
    end

    context "when the user does not have the view_project permission" do
      let(:permissions) { [] }

      it_behaves_like "no property", "statusExplanation"
      it_behaves_like "no property", :description
    end

    describe "int custom field" do
      context "if the user is admin" do
        before do
          allow(user)
            .to receive(:admin?)
                  .and_return(true)
        end

        it "has a property for the int custom field" do
          expect(subject).to be_json_eql(int_custom_value.value.to_json)
                               .at_path("customField#{int_custom_field.id}")
        end
      end

      context "if the user is no admin" do
        it "has no property for the int custom field" do
          expect(subject).not_to have_json_path("customField#{int_custom_field.id}")
        end
      end

      context "if the user is no admin and the field is visible" do
        before do
          int_custom_field.admin_only = false
        end

        it "has a property for the int custom field" do
          expect(subject).to be_json_eql(int_custom_value.value.to_json)
                               .at_path("customField#{int_custom_field.id}")
        end
      end

      context "if the user lacks the :view_project permission" do
        let(:permissions) { [] }

        before do
          int_custom_field.admin_only = false
        end

        it "has no property for the int custom field" do
          expect(subject).not_to have_json_path("customField#{int_custom_field.id}")
        end
      end
    end
  end

  describe "_links" do
    it { is_expected.to have_json_type(Object).at_path("_links") }

    it "links to self" do
      expect(subject).to have_json_path("_links/self/href")
    end

    it "has a title for link to self" do
      expect(subject).to have_json_path("_links/self/title")
    end

    describe "create work packages" do
      context "if user is allowed to create work packages" do
        it "has the correct path for a create form" do
          expect(subject).to be_json_eql(api_v3_paths.create_project_work_package_form(project.id).to_json)
                               .at_path("_links/createWorkPackage/href")
        end

        it "has the correct path to create a work package" do
          expect(subject).to be_json_eql(api_v3_paths.work_packages_by_project(project.id).to_json)
                               .at_path("_links/createWorkPackageImmediately/href")
        end
      end

      context "if user is not allowed to create work packages" do
        let(:permissions) { [] }

        it_behaves_like "has no link" do
          let(:link) { "createWorkPackage" }
        end

        it_behaves_like "has no link" do
          let(:link) { "createWorkPackageImmediately" }
        end
      end
    end

    describe "parent" do
      let(:link) { "parent" }

      it_behaves_like "has a titled link" do
        let(:href) { api_v3_paths.project(parent_project.id) }
        let(:title) { parent_project.name }
      end

      context "if lacking the permissions to see the parent" do
        let(:parent_visible) { false }

        it_behaves_like "has a titled link" do
          let(:href) { API::V3::URN_UNDISCLOSED }
          let(:title) { I18n.t(:"api_v3.undisclosed.parent") }
        end
      end

      context "if lacking the permissions to see the parent but being an admin (archived project)" do
        let(:parent_visible) { false }

        before do
          allow(user)
            .to receive(:admin?)
                  .and_return(true)
        end

        it_behaves_like "has a titled link" do
          let(:href) { api_v3_paths.project(parent_project.id) }
          let(:title) { parent_project.name }
        end
      end

      context "without a parent" do
        let(:parent_project) { nil }
        let(:ancestors) { [] }

        it_behaves_like "has an untitled link" do
          let(:href) { nil }
        end
      end
    end

    describe "ancestors" do
      let(:link) { "ancestors" }
      let(:grandparent_project) do
        build_stubbed(:project).tap do |p|
          allow(p)
            .to receive(:visible?)
                  .and_return(true)
        end
      end
      let(:root_project) do
        build_stubbed(:project).tap do |p|
          allow(p)
            .to receive(:visible?)
                  .and_return(true)
        end
      end
      let(:ancestors) { [root_project, grandparent_project, parent_project] }

      it_behaves_like "has a link collection" do
        let(:hrefs) do
          [
            {
              href: api_v3_paths.project(root_project.id),
              title: root_project.name
            },
            {
              href: api_v3_paths.project(grandparent_project.id),
              title: grandparent_project.name
            },
            {
              href: api_v3_paths.project(parent_project.id),
              title: parent_project.name
            }
          ]
        end
      end

      context "if lacking the permissions to see the parent but being allowed to see the other ancestors" do
        let(:parent_visible) { false }

        it_behaves_like "has a link collection" do
          let(:hrefs) do
            [
              {
                href: api_v3_paths.project(root_project.id),
                title: root_project.name
              },
              {
                href: api_v3_paths.project(grandparent_project.id),
                title: grandparent_project.name
              },
              {
                href: API::V3::URN_UNDISCLOSED,
                title: I18n.t(:"api_v3.undisclosed.ancestor")
              }
            ]
          end
        end
      end

      context "if lacking the permissions to see the parent but being an admin (archived project)" do
        let(:parent_visible) { false }

        before do
          allow(user)
            .to receive(:admin?)
                  .and_return(true)
        end

        it_behaves_like "has a link collection" do
          let(:hrefs) do
            [
              {
                href: api_v3_paths.project(root_project.id),
                title: root_project.name
              },
              {
                href: api_v3_paths.project(grandparent_project.id),
                title: grandparent_project.name
              },
              {
                href: api_v3_paths.project(parent_project.id),
                title: parent_project.name
              }
            ]
          end
        end
      end

      context "without an ancestor" do
        let(:parent_project) { nil }
        let(:ancestors) { [] }

        it_behaves_like "has an empty link collection"
      end
    end

    describe "status" do
      it_behaves_like "has a titled link" do
        let(:link) { "status" }
        let(:status_code) { project.status_code }
        let(:href) { api_v3_paths.project_status(status_code) }
        let(:title) { I18n.t(:"activerecord.attributes.project.status_codes.#{status_code}") }
      end

      context "if the status_code is nil" do
        before { project.status_code = nil }

        it_behaves_like "has an untitled link" do
          let(:link) { "status" }
          let(:href) { nil }
        end
      end

      context "if the user does not have the view_project permission" do
        let(:permissions) { [] }

        it_behaves_like "has no link" do
          let(:link) { "status" }
        end
      end
    end

    describe "categories" do
      it "has the correct link to its categories" do
        expect(subject).to be_json_eql(api_v3_paths.categories_by_project(project.id).to_json)
                             .at_path("_links/categories/href")
      end
    end

    describe "versions" do
      context "with only manage_versions permission" do
        let(:permissions) { [:manage_versions] }

        it_behaves_like "has an untitled link" do
          let(:link) { "versions" }
          let(:href) { api_v3_paths.versions_by_project(project.id) }
        end
      end

      context "with only view_work_packages permission" do
        let(:permissions) { [:view_work_packages] }

        it_behaves_like "has an untitled link" do
          let(:link) { "versions" }
          let(:href) { api_v3_paths.versions_by_project(project.id) }
        end
      end

      context "without both permissions" do
        let(:permissions) { [:add_work_packages] }

        it_behaves_like "has no link" do
          let(:link) { "versions" }
        end
      end
    end

    describe "types" do
      context "for a user having the view_work_packages permission" do
        let(:permissions) { [:view_work_packages] }

        it "links to the types active in the project" do
          expect(subject).to be_json_eql(api_v3_paths.types_by_project(project.id).to_json)
                               .at_path("_links/types/href")
        end

        it "links to the work packages in the project" do
          expect(subject).to be_json_eql(api_v3_paths.work_packages_by_project(project.id).to_json)
                               .at_path("_links/workPackages/href")
        end
      end

      context "for a user having the manage_types permission" do
        let(:permissions) { [:manage_types] }

        it "links to the types active in the project" do
          expect(subject).to be_json_eql(api_v3_paths.types_by_project(project.id).to_json)
                               .at_path("_links/types/href")
        end
      end

      context "for a user not having the necessary permissions" do
        let(:permission) { [] }

        it "has no types link" do
          expect(subject).not_to have_json_path("_links/types/href")
        end

        it "has no work packages link" do
          expect(subject).not_to have_json_path("_links/workPackages/href")
        end
      end
    end

    describe "memberships" do
      it_behaves_like "has an untitled link" do
        let(:link) { "memberships" }
        let(:href) { api_v3_paths.path_for(:memberships, filters: [{ project: { operator: "=", values: [project.id.to_s] } }]) }
      end

      context "without the view_members permission" do
        let(:permissions) { [] }

        it_behaves_like "has no link" do
          let(:link) { "memberships" }
        end
      end
    end

    describe "storages" do
      let(:storage) { build_stubbed(:nextcloud_storage) }
      let(:permissions) { %i[view_file_links] }

      before do
        allow(project).to receive(:storages).and_return([storage])
      end

      it_behaves_like "has a link collection" do
        let(:link) { "storages" }
        let(:hrefs) do
          [
            {
              href: api_v3_paths.storage(storage.id),
              title: storage.name
            }
          ]
        end
      end

      context "if user has no permission to view file links" do
        let(:permissions) { [] }

        it_behaves_like "has no link" do
          let(:link) { "storages" }
        end
      end
    end

    describe "link custom field" do
      context "if the user is admin and the field is invisible" do
        before do
          allow(user)
            .to receive(:admin?)
                  .and_return(true)

          version_custom_field.admin_only = true
        end

        it "links custom fields" do
          expect(subject).to be_json_eql(api_v3_paths.version(version.id).to_json)
                               .at_path("_links/customField#{version_custom_field.id}/href")
        end
      end

      context "if the user is no admin and the field is invisible" do
        before do
          version_custom_field.admin_only = true
        end

        it "does not link the custom field" do
          expect(subject).not_to have_json_path("links/customField#{version_custom_field.id}")
        end
      end

      context "if the user is no admin and the field is visible" do
        it "links custom fields" do
          expect(subject).to be_json_eql(api_v3_paths.version(version.id).to_json)
                               .at_path("_links/customField#{version_custom_field.id}/href")
        end
      end

      context "if the user lacks the :view_project permission" do
        let(:permissions) { [] }

        it "does not link the custom field" do
          expect(subject).not_to have_json_path("links/customField#{version_custom_field.id}")
        end
      end
    end

    describe "update" do
      context "for a user having the edit_project permission" do
        let(:permissions) { [:edit_project] }

        it_behaves_like "has an untitled link" do
          let(:link) { "update" }
          let(:href) { api_v3_paths.project_form project.id }
        end
      end

      context "for a user lacking the edit_project permission" do
        let(:permissions) { [] }

        it_behaves_like "has no link" do
          let(:link) { "update" }
        end
      end
    end

    describe "updateImmediately" do
      context "for a user having the edit_project permission" do
        let(:permissions) { [:edit_project] }

        it_behaves_like "has an untitled link" do
          let(:link) { "updateImmediately" }
          let(:href) { api_v3_paths.project project.id }
        end
      end

      context "for a user lacking the edit_project permission" do
        let(:permissions) { [] }

        it_behaves_like "has no link" do
          let(:link) { "updateImmediately" }
        end
      end
    end

    describe "delete" do
      context "for a user being admin" do
        before do
          allow(user)
            .to receive(:admin?)
                  .and_return(true)
        end

        it_behaves_like "has an untitled link" do
          let(:link) { "delete" }
          let(:href) { api_v3_paths.project project.id }
        end
      end

      context "for a non admin user" do
        let(:permissions) { [] }

        it_behaves_like "has no link" do
          let(:link) { "delete" }
        end
      end
    end
  end

  describe "_embedded" do
    describe "parent" do
      let(:embedded_path) { "_embedded/parent" }

      before do
        allow(parent_project)
          .to receive(:visible?)
                .and_return(parent_visible)
      end

      context "when the user is allowed to see the parent" do
        let(:parent_visible) { true }

        it "has the parent embedded" do
          expect(generated)
            .to be_json_eql("Project".to_json)
                  .at_path("#{embedded_path}/_type")

          expect(generated)
            .to be_json_eql(parent_project.name.to_json)
                  .at_path("#{embedded_path}/name")
        end
      end

      context "when the user is forbidden to see the parent" do
        let(:parent_visible) { false }

        it "hides the parent" do
          expect(generated)
            .not_to have_json_path(embedded_path)
        end
      end
    end

    describe "status" do
      let(:embedded_path) { "_embedded/status" }

      it "has the status embedded" do
        expect(generated)
          .to be_json_eql("ProjectStatus".to_json)
                .at_path("#{embedded_path}/_type")

        expect(generated)
          .to be_json_eql(I18n.t("activerecord.attributes.project.status_codes.#{project.status_code}").to_json)
                .at_path("#{embedded_path}/name")
      end

      context "if the status_code is nil" do
        before { project.status_code = nil }

        it "has no status embedded" do
          expect(generated)
            .not_to have_json_path(embedded_path)
        end
      end

      context "if the user does not have the view_project permission" do
        let(:permissions) { [] }

        it "has no status embedded" do
          expect(generated)
            .not_to have_json_path(embedded_path)
        end
      end
    end
  end

  describe "caching" do
    it "is based on the representer's cache_key" do
      allow(OpenProject::Cache)
        .to receive(:fetch)
              .and_call_original

      representer.to_json

      expect(OpenProject::Cache)
        .to have_received(:fetch)
              .with(representer.json_cache_key)
    end

    describe "#json_cache_key" do
      let!(:former_cache_key) { representer.json_cache_key }

      it "includes the name of the representer class" do
        expect(representer.json_cache_key)
          .to include("API", "V3", "Projects", "ProjectRepresenter")
      end

      it "changes when the locale changes" do
        I18n.with_locale(:fr) do
          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end

      it "changes when the project is updated" do
        project.updated_at = 20.seconds.from_now

        expect(representer.json_cache_key)
          .not_to eql former_cache_key
      end
    end
  end

  describe ".checked_permissions" do
    it "lists add_work_packages and view_project" do
      expect(described_class.checked_permissions).to contain_exactly(:add_work_packages, :view_project)
    end
  end
end
