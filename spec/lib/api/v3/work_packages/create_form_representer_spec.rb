#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
    end
  end
end
