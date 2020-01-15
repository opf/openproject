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

require 'spec_helper'

describe 'Logout', type: :feature, js: true do
  let(:user_password) { 'b0B' * 4 }
  let(:user) do
    FactoryBot.create(:user,
                      password: user_password,
                      password_confirmation: user_password)
  end

  before do
    login_with(user.login, user_password)
  end

  it 'prevents the user from making any more changes' do
    visit my_page_path

    within '.top-menu-items-right' do
      page.find("a[title='#{user.name}']").click

      click_link I18n.t(:label_logout)
    end

    expect(page)
      .to have_current_path home_path

    # Can not access the my page but is redirected
    # to login instead.
    visit my_page_path

    expect(page)
      .to have_field('Username')
  end
end
