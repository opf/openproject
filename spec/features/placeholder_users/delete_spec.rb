#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'placeholder user deletion: ', type: :feature, js: true do
  let!(:placeholder_user) { FactoryBot.create :placeholder_user }
  let(:current_user) do
    FactoryBot.create(:admin)
  end

  before do
    login_as(current_user)
  end

  context 'admin user' do
    before do
      visit placeholder_users_path
    end

    it 'can delete placeholder users from index page', selenium: true do
      expect(page).to have_content placeholder_user.name

      page.find('.icon-delete').click
      page.accept_alert

      expect(page).to have_content 'Account successfully deleted'
      expect(current_path).to eq '/placeholder_users'

      # TODO: Make the background jobs to work off.
      # expect(page).to_not have_content placeholder_user.name
    end
  end
end

