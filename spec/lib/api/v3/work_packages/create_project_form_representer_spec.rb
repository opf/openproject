#-- encoding: UTF-8
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
#++require 'rspec'

require 'spec_helper'

describe ::API::V3::WorkPackages::CreateProjectFormRepresenter do
  include API::V3::Utilities::PathHelper

  let(:errors) { [] }
  let(:project) { work_package.project }
  let(:permissions) { %i(edit_work_packages) }
  let(:type) { FactoryBot.build_stubbed(:type) }
  let(:work_package) do
    FactoryBot.build_stubbed(:stubbed_work_package,
                             type: type)
  end
  include_context 'user with stubbed permissions'
  let(:representer) do
    described_class.new(work_package, current_user: user, errors: errors)
  end

  context 'generation' do
    subject(:generated) { representer.to_json }

    describe '_links' do
      it do
        is_expected.to be_json_eql(
          api_v3_paths.create_project_work_package_form(work_package.project_id).to_json)
          .at_path('_links/self/href')
      end

      it do
        is_expected.to be_json_eql(:post.to_json).at_path('_links/self/method')
      end

      describe 'validate' do
        it do
          is_expected.to be_json_eql(
            api_v3_paths.create_project_work_package_form(work_package.project_id).to_json)
            .at_path('_links/validate/href')
        end

        it do
          is_expected.to be_json_eql(:post.to_json).at_path('_links/validate/method')
        end
      end

      describe 'preview markup' do
        it do
          is_expected.to be_json_eql(
            api_v3_paths.render_markup(
              link: api_v3_paths.project(work_package.project_id)).to_json)
            .at_path('_links/previewMarkup/href')
        end

        it do
          is_expected.to be_json_eql(:post.to_json).at_path('_links/previewMarkup/method')
        end

        it 'contains link to work package' do
          expected_preview_link =
            api_v3_paths.render_markup(link: "/api/v3/projects/#{work_package.project_id}")
          expect(subject).to be_json_eql(expected_preview_link.to_json)
            .at_path('_links/previewMarkup/href')
        end
      end

      describe 'commit' do
        context 'valid work package' do
          it do
            is_expected.to be_json_eql(
              api_v3_paths.work_packages_by_project(work_package.project_id).to_json)
              .at_path('_links/commit/href')
          end

          it do
            is_expected.to be_json_eql(:post.to_json).at_path('_links/commit/method')
          end
        end

        context 'invalid work package' do
          let(:errors) { [::API::Errors::Validation.new(:subject, 'it is broken')] }

          it do
            is_expected.not_to have_json_path('_links/commit/href')
          end
        end

        context 'user with insufficient permissions' do
          let(:permissions) { [] }

          it do
            is_expected.not_to have_json_path('_links/commit/href')
          end
        end
      end

      describe 'customFields' do
        shared_examples_for 'links to project custom field admin' do
          it 'has a link to set the custom fields for that project' do
            expected = {
              href: "/projects/#{work_package.project.identifier}/settings/custom_fields",
              type: "text/html",
              title: "Custom fields"
            }

            is_expected.to be_json_eql(expected.to_json).at_path('_links/customFields')
          end
        end

        context 'with admin privileges' do
          include_context 'user with stubbed permissions', admin: true

          it_behaves_like 'links to project custom field admin'
        end

        context 'without project admin priviliges' do
          it 'has no link to set the custom fields for that project' do
            is_expected.to_not have_json_path('_links/customFields')
          end
        end

        context 'with project admin privileges' do
          let(:permissions) { [:edit_project] }

          it_behaves_like 'links to project custom field admin'
        end
      end

      describe 'configureForm' do
        context "as admin" do
          include_context 'user with stubbed permissions', admin: true

          context 'with type' do
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
            let(:type) { nil }

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
