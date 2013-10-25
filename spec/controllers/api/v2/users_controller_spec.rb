#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe Api::V2::UsersController do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    User.stub(:current).and_return current_user
  end

  describe 'index.json' do
    describe 'with 3 visible users' do

      before do
        3.times do
          FactoryGirl.create(:user)
        end

        get 'index', :format => 'json'
      end

      it 'returns 3 users' do
        assigns(:users).size.should eql 3+1 # the admin is also available, when all users are selected
      end

      it 'renders the index template' do
        response.should render_template('api/v2/users/index', :formats => ["api"])
      end
    end

    describe 'search for ids' do
      let (:user_1) {FactoryGirl.create(:user)}
      let (:user_2) {FactoryGirl.create(:user)}

      it 'returns the users for requested ids' do
        get 'index', ids: "#{user_1.id},#{user_2.id}", :format => 'json'

        found_users = assigns(:users)

        found_users.size.should eql 2
        found_users.should include user_1,user_2


      end

    end



  end
end
