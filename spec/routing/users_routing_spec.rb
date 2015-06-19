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

describe UsersController, type: :routing do
  describe 'routing' do
    describe 'users' do
      it {
        expect(get('/users/1/deletion_info')).to route_to(controller: 'users',
                                                          action: 'deletion_info',
                                                          id: '1')
      }

      it {
        expect(delete('/users/1')).to route_to(controller: 'users',
                                               action: 'destroy',
                                               id: '1')
      }
    end

    describe 'my' do
      let(:user) { FactoryGirl.create(:user) }

      before do
        allow(User).to receive(:current).and_return(user)
      end

      it {
        expect(get('/my/deletion_info')).to route_to(controller: 'users',
                                                     action: 'deletion_info')
      }
    end
  end
end
