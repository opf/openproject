#-- encoding: UTF-8
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

require_relative '../legacy_spec_helper'

describe 'Layout' do
  fixtures :all

  def document_root_element
    html_document.root
  end

  context 'with login required', with_settings: { login_required?: true } do
    it 'should top menu navigation not visible when login required' do
      get '/'
      assert_select '#account-nav-left', 0
    end
  end

  context 'with login required', with_settings: { login_required?: false } do
    it 'should top menu navigation visible when login not required' do
      get '/'
      assert_select '#account-nav-left'
    end
  end

  specify 'browsing to a missing page should render the base layout' do
    get '/users/100000000'

    assert_response :not_found

    # UsersController uses the admin layout by default
    assert_select '#main-menu', count: 0
  end

  specify 'page titles should be properly escaped',
          with_settings: { app_title: '<3' } do
    project = FactoryGirl.create(:project, name: 'C&A', is_public: true)
    get "/projects/#{project.to_param}"

    def title_html
      title = document_root_element.at('//title') and title.inner_html
    end

    expect(title_html).to match /C&amp;A/
    expect(title_html).to match /&lt;3/
  end
end
