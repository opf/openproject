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

require File.expand_path('../../../../spec_helper', __FILE__)

describe Api::Experimental::UsersController, type: :controller do
  let(:current_user) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:project)      { FactoryGirl.create(:project) }
  let(:role)         { FactoryGirl.create(:role, permissions: [:view_work_packages]) }

  before do
    allow(User).to receive(:current).and_return(current_user)
    allow(Project).to receive(:find).and_return(project)
  end

  describe '#index' do
    context 'without a project' do
      before do
        get 'index', format: 'json'
      end

      context 'with the necessary permissions' do
        it 'should respond with 200' do
          expect(response.response_code).to eql(200)
        end
      end

      context 'without the necessary permissions' do
        let(:role) { FactoryGirl.create(:role, permissions: []) }

        it 'should respond with 403' do
          expect(response.response_code).to eql(403)
        end
      end
    end

    context 'with a project' do
      before do
        get 'index', project_id: project.id, format: 'json'
      end

      context 'with the necessary permissions' do
        it 'should respond with 200' do
          expect(response.response_code).to eql(200)
        end
      end

      context 'without the necessary permissions' do
        let(:role) { FactoryGirl.create(:role, permissions: []) }

        it 'should respond with 403' do
          expect(response.response_code).to eql(403)
        end
      end
    end
  end
end
