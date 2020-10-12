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

require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController, type: :controller do
  before(:each) do
    allow(@controller).to receive(:require_admin).and_return(true)
    allow(@controller).to receive(:check_if_login_required)
    allow(@controller).to receive(:set_localization)
    @global_roles = [mock_model(GlobalRole), mock_model(GlobalRole)]
    allow(GlobalRole).to receive(:all).and_return(@global_roles)
    user_mock = mock_model User
    allow(user_mock).to receive(:logged?).and_return(true)
    allow(User).to receive(:find).with(any_args).and_return(user_mock)

    disable_log_requesting_user
  end

  describe 'get' do
    before :each do
      get 'edit', params: { id: 1 }
    end

    it { expect(response).to be_successful }
    it { expect(assigns(:global_roles)).to eql @global_roles }
    it { expect(response).to render_template 'users/edit' }
  end
end
