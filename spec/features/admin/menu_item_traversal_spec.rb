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

describe 'Menu item traversal', type: :feature, js: true do
  let(:admin) { FactoryBot.create(:admin) }

  describe 'EnterpriseToken management' do
    before do
      login_as(admin)
      visit admin_index_path
    end

    it 'correctly maps the menu items for controllers in their namespace (Regression #30859)' do
      expect(page).to have_selector('.admin-overview-menu-item.selected', text: 'Overview')

      find('.plugin-webhooks-menu-item').click

      # using `controller_name` in `menu_controller.rb` has broken this example,
      # due to the plugin controller also being named 'admin' thus falling back to 'admin#index' => overview selected
      expect(page).to have_selector('.plugin-webhooks-menu-item.selected', text: 'Webhooks', wait: 5)
      expect(page).to have_no_selector('.admin-overview-menu-item.selected')
    end
  end
end
