#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++require 'rspec'

require 'spec_helper'

describe ::API::V3::WorkPackages::CreateFormRepresenter do
  include API::V3::Utilities::PathHelper

  let(:errors) { [] }
  let(:project) {
    FactoryGirl.build_stubbed(:project)
  }
  let(:work_package) do
    wp = FactoryGirl.build_stubbed(:work_package, project: project)
    allow(wp).to receive(:assignable_versions).and_return []
    wp
  end
  let(:current_user) {
    FactoryGirl.build_stubbed(:user)
  }
  let(:representer) {
    described_class.new(work_package, current_user: current_user, errors: errors)
  }

  context 'generation' do
    subject(:generated) { representer.to_json }

    describe '_links' do
      it 'links to the create form api' do
        is_expected
          .to be_json_eql(api_v3_paths.create_work_package_form.to_json)
          .at_path('_links/self/href')
      end

      it 'is a post' do
        is_expected
          .to be_json_eql(:post.to_json)
          .at_path('_links/self/method')
      end

      describe 'validate' do
        it 'links to the create form api' do
          is_expected
            .to be_json_eql(api_v3_paths.create_work_package_form.to_json)
            .at_path('_links/validate/href')
        end

        it 'is a post' do
          is_expected
            .to be_json_eql(:post.to_json)
            .at_path('_links/validate/method')
        end
      end

      describe 'preview markup' do
        it 'links to the markup api' do
          path = api_v3_paths.render_markup(link: api_v3_paths.project(work_package.project_id))
          is_expected
            .to be_json_eql(path.to_json)
            .at_path('_links/previewMarkup/href')
        end

        it 'is a post' do
          is_expected
            .to be_json_eql(:post.to_json)
            .at_path('_links/previewMarkup/method')
        end

        it 'contains link to work package' do
          expected_preview_link =
            api_v3_paths.render_markup(format: 'textile',
                                       link: "/api/v3/projects/#{work_package.project_id}")
          expect(subject)
            .to be_json_eql(expected_preview_link.to_json)
            .at_path('_links/previewMarkup/href')
        end
      end

      describe 'commit' do
        before do
          allow(current_user)
            .to receive(:allowed_to?)
            .and_return(false)
          allow(current_user)
            .to receive(:allowed_to?)
            .with(:edit_work_packages, project)
            .and_return(true)
        end

        context 'valid work package' do
          it 'links to the work package create api' do
            is_expected
              .to be_json_eql(api_v3_paths.work_packages.to_json)
              .at_path('_links/commit/href')
          end

          it 'is a post' do
            is_expected
              .to be_json_eql(:post.to_json)
              .at_path('_links/commit/method')
          end
        end

        context 'invalid work package' do
          let(:errors) { [::API::Errors::Validation.new(:subject, 'it is broken')] }

          it 'has no link' do
            is_expected.not_to have_json_path('_links/commit/href')
          end
        end

        context 'user with insufficient permissions' do
          before do
            allow(current_user)
              .to receive(:allowed_to?)
              .with(:edit_work_packages, project)
              .and_return(false)
          end

          it 'has no link' do
            is_expected.not_to have_json_path('_links/commit/href')
          end
        end
      end

      describe 'customFields' do
        before do
          allow(current_user).to receive(:allowed_to?).and_return(true)
        end

        context 'with project admin priviliges' do
          it 'has a link to set the custom fields for that project' do
            expected = {
              href: "/projects/#{work_package.project.identifier}/settings/custom_fields",
              type: "text/html",
              title: "Custom fields"
            }

            is_expected.to be_json_eql(expected.to_json).at_path('_links/customFields')
          end
        end

        context 'without project admin priviliges' do
          before do
            allow(current_user).to receive(:allowed_to?)
              .with(:edit_project, work_package.project)
              .and_return(false)
          end

          it 'has no link to set the custom fields for that project' do
            is_expected.to_not have_json_path('_links/customFields')
          end
        end

        context 'with project and general admin priviliges' do
          let(:current_user) { FactoryGirl.build_stubbed(:admin) }

          before do
            allow(current_user).to receive(:allowed_to?)
              .with(:edit_project, work_package.project)
              .and_return(false)
          end

          it 'has a link to set the custom fields for that project' do
            expected = {
              href: "/projects/#{work_package.project.identifier}/settings/custom_fields",
              type: "text/html",
              title: "Custom fields"
            }

            is_expected
              .to be_json_eql(expected.to_json)
              .at_path('_links/customFields')
          end
        end
      end

      describe 'configureForm' do
        before do
          allow(current_user).to receive(:allowed_to?).and_return(true)
        end

        context "as admin" do
          let(:current_user) { FactoryGirl.build_stubbed(:admin) }

          context 'with type' do
            let(:type) { FactoryGirl.build_stubbed(:type) }
            let(:work_package) do
              FactoryGirl.build(:work_package,
                                id: 42,
                                created_at: DateTime.now,
                                updated_at: DateTime.now,
                                type: type)
            end

            before do
              allow(current_user).to receive(:allowed_to?)
                .with(:edit_project, work_package.project)
                .and_return(false)
            end

            it 'has a link to configure the form' do
              expected = {
                href: "/types/#{type.id}/edit?tab=form_configuration",
                type: "text/html",
                title: "Configure form"
              }

              is_expected
                .to be_json_eql(expected.to_json)
                .at_path('_links/configureForm')
            end
          end

          context 'without type' do
            before do
              allow(work_package).to receive(:type).and_return(nil)
              allow(work_package).to receive(:type_id).and_return(nil)
            end

            it 'has no link to configure the form' do
              is_expected.to_not have_json_path('_links/configureForm')
            end
          end
        end

        context 'not being admin' do
          it 'has no link to configure the form' do
            is_expected.to_not have_json_path('_links/configureForm')
          end
        end
      end
    end
  end
end
