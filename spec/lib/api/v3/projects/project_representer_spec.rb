#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Projects::ProjectRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:project) do
    FactoryBot.build_stubbed(:project,
                             parent: parent_project,
                             description: 'some description',
                             status: status).tap do |p|
      allow(p)
        .to receive(:available_custom_fields)
        .and_return([int_custom_field, version_custom_field])

      allow(p)
        .to receive(:"custom_field_#{int_custom_field.id}")
        .and_return(int_custom_value.value)

      allow(p)
        .to receive(:custom_value_for)
        .with(version_custom_field)
        .and_return(version_custom_value)
    end
  end
  let(:status) do
    FactoryBot.build_stubbed(:project_status)
  end
  let(:parent_project) { FactoryBot.build_stubbed(:project) }
  let(:representer) { described_class.create(project, current_user: user) }

  let(:user) do
    FactoryBot.build_stubbed(:user).tap do |u|
      allow(u)
        .to receive(:allowed_to?) do |permission, context|
        permissions.include?(permission) && context == project
      end
    end
  end

  let(:int_custom_field) { FactoryBot.build_stubbed(:int_project_custom_field, visible: false) }
  let(:version_custom_field) { FactoryBot.build_stubbed(:version_project_custom_field, visible: true) }
  let(:int_custom_value) do
    CustomValue.new(custom_field: int_custom_field,
                    value: '1234',
                    customized: nil)
  end
  let(:version) { FactoryBot.build_stubbed(:version) }
  let(:version_custom_value) do
    CustomValue.new(custom_field: version_custom_field,
                    value: version.id,
                    customized: nil).tap do |cv|
                      allow(cv)
                        .to receive(:typed_value)
                        .and_return(version)
                    end
  end

  let(:permissions) { %i[add_work_packages view_members] }

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { is_expected.to include_json('Project'.to_json).at_path('_type') }

    describe 'properties' do
      it_behaves_like 'property', :_type do
        let(:value) { 'Project' }
      end

      it_behaves_like 'property', :id do
        let(:value) { project.id }
      end

      it_behaves_like 'property', :identifier do
        let(:value) { project.identifier }
      end

      it_behaves_like 'property', :name do
        let(:value) { project.name }
      end

      it_behaves_like 'property', :active do
        let(:value) { project.active }
      end

      it_behaves_like 'property', :public do
        let(:value) { project.public }
      end

      it_behaves_like 'formattable property', :description do
        let(:value) { project.description }
      end

      context 'status' do
        it_behaves_like 'formattable property', 'statusExplanation' do
          let(:value) { status.explanation }
        end

        it 'includes the project status code' do
          expect(subject)
            .to be_json_eql(status.code.tr('_', ' ').to_json)
            .at_path('status')
        end

        context 'if the status is nil' do
          let(:status) { nil }

          it_behaves_like 'formattable property', 'statusExplanation' do
            let(:value) { nil }
          end

          it 'includes the project status code' do
            expect(subject)
              .to be_json_eql(nil.to_json)
              .at_path('status')
          end
        end
      end

      it_behaves_like 'has UTC ISO 8601 date and time' do
        let(:date) { project.created_at }
        let(:json_path) { 'createdAt' }
      end

      it_behaves_like 'has UTC ISO 8601 date and time' do
        let(:date) { project.updated_at }
        let(:json_path) { 'updatedAt' }
      end

      context 'int custom field' do
        context 'if the user is admin' do
          before do
            allow(user)
              .to receive(:admin?)
              .and_return(true)
          end

          it "has a property for the int custom field" do
            is_expected
              .to be_json_eql(int_custom_value.value.to_json)
              .at_path("customField#{int_custom_field.id}")
          end
        end

        context 'if the user is no admin' do
          it "has no property for the int custom field" do
            is_expected
              .not_to have_json_path("customField#{int_custom_field.id}")
          end
        end
      end
    end

    describe '_links' do
      it { is_expected.to have_json_type(Object).at_path('_links') }

      it 'links to self' do
        expect(subject).to have_json_path('_links/self/href')
      end
      it 'has a title for link to self' do
        expect(subject).to have_json_path('_links/self/title')
      end

      describe 'create work packages' do
        context 'user allowed to create work packages' do
          it 'has the correct path for a create form' do
            is_expected
              .to be_json_eql(api_v3_paths.create_project_work_package_form(project.id).to_json)
              .at_path('_links/createWorkPackage/href')
          end

          it 'has the correct path to create a work package' do
            is_expected.to be_json_eql(api_v3_paths.work_packages_by_project(project.id).to_json)
              .at_path('_links/createWorkPackageImmediately/href')
          end
        end

        context 'user not allowed to create work packages' do
          let(:permissions) { [] }

          it_behaves_like 'has no link' do
            let(:link) { 'createWorkPackage' }
          end

          it_behaves_like 'has no link' do
            let(:link) { 'createWorkPackageImmediately' }
          end
        end
      end

      describe 'parent' do
        before do
          allow(parent_project)
            .to receive(:visible?)
            .and_return(visible)
        end
        let(:visible) { true }

        it_behaves_like 'has a titled link' do
          let(:link) { 'parent' }
          let(:href) { api_v3_paths.project(parent_project.id) }
          let(:title) { parent_project.name }
        end

        context 'if lacking the permissions to see the parent' do
          let(:visible) { false }

          it_behaves_like 'has a titled link' do
            let(:link) { 'parent' }
            let(:href) { nil }
            let(:title) { nil }
          end
        end
      end

      describe 'categories' do
        it 'has the correct link to its categories' do
          is_expected.to be_json_eql(api_v3_paths.categories_by_project(project.id).to_json)
            .at_path('_links/categories/href')
        end
      end

      describe 'versions' do
        context 'with only manage_versions permission' do
          let(:permissions) { [:manage_versions] }

          it_behaves_like 'has an untitled link' do
            let(:link) { 'versions' }
            let(:href) { api_v3_paths.versions_by_project(project.id) }
          end
        end

        context 'with only view_work_packages permission' do
          let(:permissions) { [:view_work_packages] }

          it_behaves_like 'has an untitled link' do
            let(:link) { 'versions' }
            let(:href) { api_v3_paths.versions_by_project(project.id) }
          end
        end

        context 'without both permissions' do
          let(:permissions) { [:add_work_packages] }

          it_behaves_like 'has no link' do
            let(:link) { 'versions' }
          end
        end
      end

      describe 'types' do
        context 'for a user having the view_work_packages permission' do
          let(:permissions) { [:view_work_packages] }

          it 'links to the types active in the project' do
            is_expected.to be_json_eql(api_v3_paths.types_by_project(project.id).to_json)
              .at_path('_links/types/href')
          end

          it 'links to the work packages in the project' do
            is_expected.to be_json_eql(api_v3_paths.work_packages_by_project(project.id).to_json)
                             .at_path('_links/workPackages/href')
          end
        end

        context 'for a user having the manage_types permission' do
          let(:permissions) { [:manage_types] }

          it 'links to the types active in the project' do
            is_expected.to be_json_eql(api_v3_paths.types_by_project(project.id).to_json)
                             .at_path('_links/types/href')
          end
        end

        context 'for a user not having the necessary permissions' do
          let(:permission) { [] }

          it 'has no types link' do
            is_expected.to_not have_json_path('_links/types/href')
          end

          it 'has no work packages link' do
            is_expected.to_not have_json_path('_links/workPackages/href')
          end
        end
      end

      describe 'memberships' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'memberships' }
          let(:href) { api_v3_paths.path_for(:memberships, filters: [{ project: { operator: "=", values: [project.id.to_s] } }]) }
        end

        context 'without the view_members permission' do
          let(:permissions) { [] }

          it_behaves_like 'has no link' do
            let(:link) { 'memberships' }
          end
        end
      end

      context 'link custom field' do
        context 'if the user is admin and the field is invisible' do
          before do
            allow(user)
              .to receive(:admin?)
              .and_return(true)

            version_custom_field.visible = false
          end

          it 'links custom fields' do
            is_expected
              .to be_json_eql(api_v3_paths.version(version.id).to_json)
              .at_path("_links/customField#{version_custom_field.id}/href")
          end
        end

        context 'if the user is no admin and the field is invisible' do
          before do
            version_custom_field.visible = false
          end

          it "has no property for the int custom field" do
            is_expected
              .not_to have_json_path("links/customField#{version_custom_field.id}")
          end
        end

        context 'if the user is no admin and the field is visible' do
          it 'links custom fields' do
            is_expected
              .to be_json_eql(api_v3_paths.version(version.id).to_json)
                    .at_path("_links/customField#{version_custom_field.id}/href")
          end
        end
      end

      describe 'update' do
        context 'for a user having the edit_project permission' do
          let(:permissions) { [:edit_project] }

          it_behaves_like 'has an untitled link' do
            let(:link) { 'update' }
            let(:href) { api_v3_paths.project_form project.id }
          end
        end

        context 'for a user lacking the edit_project permission' do
          let(:permissions) { [] }

          it_behaves_like 'has no link' do
            let(:link) { 'update' }
          end
        end
      end

      describe 'updateImmediately' do
        context 'for a user having the edit_project permission' do
          let(:permissions) { [:edit_project] }

          it_behaves_like 'has an untitled link' do
            let(:link) { 'updateImmediately' }
            let(:href) { api_v3_paths.project project.id }
          end
        end

        context 'for a user lacking the edit_project permission' do
          let(:permissions) { [] }

          it_behaves_like 'has no link' do
            let(:link) { 'updateImmediately' }
          end
        end
      end

      describe 'delete' do
        context 'for a user being admin' do
          before do
            allow(user)
              .to receive(:admin?)
              .and_return(true)
          end

          it_behaves_like 'has an untitled link' do
            let(:link) { 'delete' }
            let(:href) { api_v3_paths.project project.id }
          end
        end

        context 'for a non admin user' do
          let(:permissions) { [] }

          it_behaves_like 'has no link' do
            let(:link) { 'delete' }
          end
        end
      end
    end

    describe 'caching' do
      it 'is based on the representer\'s cache_key' do
        expect(OpenProject::Cache)
          .to receive(:fetch)
          .with(representer.json_cache_key)
          .and_call_original

        representer.to_json
      end

      describe '#json_cache_key' do
        let!(:former_cache_key) { representer.json_cache_key }

        it 'includes the name of the representer class' do
          expect(representer.json_cache_key)
            .to include('API', 'V3', 'Projects', 'ProjectRepresenter')
        end

        it 'changes when the locale changes' do
          I18n.with_locale(:fr) do
            expect(representer.json_cache_key)
              .not_to eql former_cache_key
          end
        end

        it 'changes when the project is updated' do
          project.updated_at = Time.now + 20.seconds

          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end

        it 'changes when the project status is updated' do
          project.status.updated_at = Time.now + 20.seconds

          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end
    end
  end

  describe '.checked_permissions' do
    it 'lists add_work_packages' do
      expect(described_class.checked_permissions).to match_array([:add_work_packages])
    end
  end
end
