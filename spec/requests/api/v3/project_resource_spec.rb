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
require 'rack/test'

describe 'API v3 Project resource' do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:role) { FactoryGirl.create(:role) }

  describe '#get' do
    let(:get_path) { api_v3_paths.project project.id }
    subject(:response) { last_response }

    context 'logged in user' do
      before do
        allow(User).to receive(:current).and_return current_user
        member = FactoryGirl.build(:member, user: current_user, project: project)
        member.role_ids = [role.id]
        member.save!
        get get_path
      end

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it 'should respond with correct project' do
        expect(subject.body).to include_json('Project'.to_json).at_path('_type')
        expect(subject.body).to be_json_eql(project.identifier.to_json).at_path('identifier')
      end

      context 'requesting nonexistent project' do
        let(:get_path) { api_v3_paths.project 9999 }

        it_behaves_like 'not found' do
          let(:id) { 9999 }
          let(:type) { 'Project' }
        end
      end

      context 'requesting project without sufficient permissions' do
        let(:another_project) { FactoryGirl.create(:project, is_public: false) }
        let(:get_path) { api_v3_paths.project another_project.id }

        it_behaves_like 'not found' do
          let(:id) { "#{another_project.id}" }
          let(:type) { 'Project' }
        end
      end
    end

    context 'not logged in user' do
      before do
        get get_path
      end

      it_behaves_like 'not found'
    end
  end
end
