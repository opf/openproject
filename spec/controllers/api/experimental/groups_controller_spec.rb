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

describe Api::Experimental::GroupsController, type: :controller do
  let(:current_user) do
    FactoryGirl.create(:user, member_in_project: project,
                              member_through_role: role)
  end
  let(:project)      { FactoryGirl.create(:project) }
  let(:role)         { FactoryGirl.create(:role, permissions: [:view_work_packages]) }

  before do
    allow(User).to receive(:current).and_return(current_user)
  end

  describe '#index' do
    context 'with no groups available' do
      before do
        get 'index', format: 'xml'
      end

      it 'assigns an empty groups array' do
        expect(assigns(:groups)).to eq []
      end

      it 'renders the index template' do
        expect(response).to render_template('api/experimental/groups/index', formats: ['api'])
      end

      it 'should respond with 200' do
        expect(response.response_code).to eql(200)
      end
    end

    context 'with groups available' do
      before do
        allow(Group).to receive(:all).and_return(FactoryGirl.build_list(:group, 2))
        get 'index', format: 'xml'
      end

      it 'assigns an array with 2 groups' do
        expect(assigns(:groups).size).to eq 2
      end

      it 'should respond with 200' do
        expect(response.response_code).to eql(200)
      end
    end

    context 'without the necessary permissions' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      before do
        get 'index', format: 'xml'
      end

      it 'should respond with 403' do
        expect(response.response_code).to eql(403)
      end
    end
  end
end
