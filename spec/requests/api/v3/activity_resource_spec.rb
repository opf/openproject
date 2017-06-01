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
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 Activity resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) {
    FactoryGirl.create(:user, member_in_project: project, member_through_role: role)
  }
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:work_package) { FactoryGirl.create(:work_package, author: current_user, project: project) }
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:permissions) { [:view_work_packages, :edit_work_package_notes] }
  let(:activity) { work_package.journals.first }

  before do
    allow(User).to receive(:current).and_return current_user
    work_package.save!
  end

  describe '#get' do
    subject(:response) { last_response }

    context 'logged in user' do
      let(:get_path) { api_v3_paths.activity activity.id }
      before do
        get get_path
      end

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it 'should respond with correct activity' do
        expect(subject.body).to include_json('Activity'.to_json).at_path('_type')
        expect(subject.body).to be_json_eql(activity.id.to_json).at_path('id')
      end

      context 'requesting nonexistent activity' do
        let(:get_path) { api_v3_paths.activity 9999 }

        it_behaves_like 'not found' do
          let(:id) { 9999 }
          let(:type) { 'Journal' }
        end
      end

      context 'requesting activity without sufficient permissions' do
        let(:another_project) { FactoryGirl.create(:project, is_public: false) }
        let(:another_work_package) { FactoryGirl.create(:work_package, project: another_project) }
        let(:another_activity) { FactoryGirl.create(:work_package_journal, journable: another_work_package) }
        let(:get_path) { api_v3_paths.activity another_activity.id }

        it_behaves_like 'unauthorized access'
      end
    end

    it_behaves_like 'handling anonymous user' do
      let(:project) { FactoryGirl.create(:project, is_public: true) }
      let(:path) { api_v3_paths.activity activity.id }
    end
  end

  describe '#patch' do
    subject(:response) { last_response }
    let(:patch_path) { api_v3_paths.activity activity.id }
    let(:valid_params) {
      {
        comment: 'a fancy comment!'
      }
    }

    context 'authorized user' do
      before do
        patch patch_path, valid_params.to_json, 'CONTENT_TYPE' => 'application/json'
      end

      subject(:response) { last_response }

      it 'should respond with HTTP OK' do
        expect(subject.status).to eq(200)
      end

      it 'changes the comment' do
        activity.reload
        expect(activity.notes).to eql 'a fancy comment!'
      end

      it 'responds with the updated activity' do
        expect(subject.body).to be_json_eql('a fancy comment!'.to_json).at_path('comment/raw')
      end
    end
  end
end
