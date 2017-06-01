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

module InsertUserSetupCallback
  def user_setup
    current_user_before User.current

    super
  end

  def current_user_before(user)
    ResetCurrentUserCallback.current_user_before(user)
  end
end

module ResetCurrentUserCallback
  class << self
    def current_user_before(user)
      user
    end
  end
end

describe ResetCurrentUser, type: :request do
  let!(:user) { FactoryGirl.create :user }

  before do
    ApplicationController.prepend InsertUserSetupCallback

    allow_any_instance_of(ApplicationController)
      .to receive(:find_current_user).and_return(user)
  end

  it 'resets User.current between requests' do
    expect(ResetCurrentUserCallback).to receive(:current_user_before).with(User.anonymous)
    get '/my/page'
    expect(response.body).to include (user.name)

    # without the ResetCurrentUser middleware the following expectation
    # fails as User.current still has the value from the last request

    expect(ResetCurrentUserCallback).to receive(:current_user_before).with(User.anonymous)
    get '/my/page'
    expect(response.body).to include (user.name)
  end
end
