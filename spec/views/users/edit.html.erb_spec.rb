#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe 'users/edit' do
  let(:current_user) { FactoryGirl.build :admin }

  context 'authentication provider' do
    let(:user)  { FactoryGirl.build :user, :id => 1,  # id is required to create route to edit
                                           :identity_url => 'test_provider:veryuniqueid' }

    before do
      assign(:user, user)
      assign(:auth_sources, [])

      allow(view).to receive(:current_user).and_return(current_user)

      render
    end

    it 'shows the authentication provider' do
      expect(response.body).to include('Test Provider')
    end
  end

  context 'with password login disabled' do
    before do
      OpenProject::Configuration.stub(:disable_password_login?).and_return(true)
    end

    context 'if the user has password-based login' do
      let(:user) { FactoryGirl.build :user, id: 42 }

      before do
        assign :user, user
        assign :auth_sources, []

        allow(view).to receive(:current_user).and_return(current_user)

        render
      end

      it 'warns that the user cannot login' do
        expect(response.body).to include('Warning', 'they cannot log in')
      end
    end
  end
end
