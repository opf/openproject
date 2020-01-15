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

describe ::API::V3::WorkPackages::FormRepresenter do
  include API::V3::Utilities::PathHelper

  let(:errors) { [] }
  let(:work_package) {
    FactoryBot.build(:work_package,
                      id: 42,
                      created_at: DateTime.now,
                      updated_at: DateTime.now)
  }
  let(:current_user) {
    FactoryBot.build(:user, member_in_project: work_package.project)
  }
  let(:representer) {
    described_class.new(work_package, current_user: current_user, errors: errors)
  }

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { is_expected.to be_json_eql('Form'.to_json).at_path('_type') }

    describe 'validation errors' do
      context 'w/o errors' do
        it { is_expected.to be_json_eql({}.to_json).at_path('_embedded/validationErrors') }
      end

      context 'with errors' do
        let(:subject_error_message) { 'Subject can\'t be blank!' }
        let(:status_error_message) { 'Status can\'t be blank!' }
        let(:errors) { [subject_error, status_error] }
        let(:subject_error) { ::API::Errors::Validation.new(:subject, subject_error_message) }
        let(:status_error) { ::API::Errors::Validation.new(:status, status_error_message) }
        let(:api_subject_error) { ::API::V3::Errors::ErrorRepresenter.new(subject_error) }
        let(:api_status_error) { ::API::V3::Errors::ErrorRepresenter.new(status_error) }
        let(:api_errors) { { subject: api_subject_error, status: api_status_error } }

        it { is_expected.to be_json_eql(api_errors.to_json).at_path('_embedded/validationErrors') }
      end
    end

    it { is_expected.to have_json_path('_embedded/payload') }
    it { is_expected.to have_json_path('_embedded/schema') }
  end
end
