#-- encoding: UTF-8
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

require 'legacy_spec_helper'

describe 'Layout' do
  fixtures :all

  specify 'browsing to a missing page should render the base layout' do
    get '/users/100000000'

    assert_response :not_found

    # UsersController uses the admin layout by default
    assert_select '#main-menu', count: 0
  end

  it 'should top menu navigation not visible when login required' do
    with_settings login_required: '1' do
      get '/'
      assert_select '#account-nav-left', 0
    end
  end

  it 'should top menu navigation visible when login not required' do
    with_settings login_required: '0' do
      get '/'
      assert_select '#account-nav-left'
    end
  end

  specify 'page titles should be properly escaped' do
    project = Project.generate(name: 'C&A', is_public: true)

    with_settings app_title: '<3' do
      get "/projects/#{project.to_param}"

      html_node = HTML::Document.new(response.body)

      assert_select html_node.root, 'title', /C&amp;A/
      assert_select html_node.root, 'title', /&lt;3/
    end
  end
end
