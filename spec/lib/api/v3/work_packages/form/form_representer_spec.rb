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
#++

require 'spec_helper'

describe ::API::V3::WorkPackages::Form::FormRepresenter do
  let(:work_package) {
    FactoryGirl.build(:work_package,
                      id: 42,
                      created_at: DateTime.now,
                      updated_at: DateTime.now)
  }
  let(:current_user) {
    FactoryGirl.build(:user, member_in_project: work_package.project)
  }
  let(:representer)  { described_class.new(work_package, current_user: current_user) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { is_expected.to be_json_eql('Form'.to_json).at_path('_type') }

    describe '_links' do
      it { is_expected.to have_json_path('_links') }

      it { is_expected.to have_json_path('_links/self/href') }

      describe 'validate' do
        it { is_expected.to have_json_path('_links/validate/href') }

        it { is_expected.to be_json_eql(:post.to_json).at_path('_links/validate/method') }
      end

      describe 'preview markup' do
        it { is_expected.to have_json_path('_links/previewMarkup/href') }

        it { is_expected.to be_json_eql(:post.to_json).at_path('_links/previewMarkup/method') }

        it 'contains link to work package' do
          body = parse_json(subject)
          preview_markup_wp_link = body['_links']['previewMarkup']['href'].split('?')[1]
          wp_self_link = body['_links']['commit']['href']

          expect(preview_markup_wp_link).to eq(wp_self_link)
        end
      end

      describe 'commit' do
        context 'valid work package' do
          it { is_expected.to have_json_path('_links/commit/href') }

          it { is_expected.to be_json_eql(:patch.to_json).at_path('_links/commit/method') }
        end

        context 'invalid work package' do
          before { allow(work_package.errors).to receive(:empty?).and_return(false) }

          it { is_expected.not_to have_json_path('_links/commit/href') }
        end

        context 'user with insufficient permissions' do
          let(:role) { FactoryGirl.create(:role, permissions: []) }
          let(:current_user) {
            FactoryGirl.build(:user,
                              member_in_project: work_package.project,
                              member_through_role: role)
          }

          before { allow(work_package.errors).to receive(:empty?).and_return(true) }

          it { is_expected.not_to have_json_path('_links/commit/href') }
        end
      end
    end

    describe 'validation errors' do
      context 'w/o errors' do
        it { is_expected.to be_json_eql({}.to_json).at_path('_embedded/validationErrors') }
      end

      context 'with errors' do
        let(:subject_error_message) { 'Subject can\'t be blank!' }
        let(:status_error_message) { 'Status can\'t be blank!' }
        let(:errors) {
          { subject: [subject_error_message], status: [status_error_message] }
        }
        let(:subject_error) { ::API::Errors::Validation.new(subject_error_message) }
        let(:status_error) { ::API::Errors::Validation.new(status_error_message) }
        let(:api_subject_error) { ::API::V3::Errors::ErrorRepresenter.new(subject_error) }
        let(:api_status_error) { ::API::V3::Errors::ErrorRepresenter.new(status_error) }
        let(:api_errors) { { subject: api_subject_error, status: api_status_error } }

        before do
          allow(work_package).to receive(:errors).and_return(errors)
          allow(work_package.errors).to receive(:full_message).with(:subject, anything)
                                                              .and_return(subject_error_message)
          allow(work_package.errors).to receive(:full_message).with(:status, anything)
                                                              .and_return(status_error_message)
        end

        it { is_expected.to be_json_eql(api_errors.to_json).at_path('_embedded/validationErrors') }
      end
    end
  end
end
