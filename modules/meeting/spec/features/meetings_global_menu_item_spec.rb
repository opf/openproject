# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
# ++
#

require 'spec_helper'

RSpec.describe 'Meetings global menu item',
               :with_cuprite,
               with_flag: { more_global_index_pages: true } do
  let(:user_without_permissions) { create(:user) }
  let(:admin) { create(:admin) }

  let(:meetings_label) { I18n.t(:label_meeting_plural) }

  before do
    login_as current_user
    visit root_path
  end

  context 'as a user with permissions' do
    let(:current_user) { admin }

    it 'navigates to the global meetings index page' do
      within '#main-menu' do
        click_link meetings_label
      end

      expect(page).to have_current_path('/meetings')

      within '#main-menu' do
        expect(page).to have_selector('.selected', text: meetings_label)
      end
    end
  end

  context 'as a user without permissions' do
    let(:current_user) { user_without_permissions }

    it 'does not render' do
      within '#main-menu' do
        expect(page).not_to have_link(meetings_label)
      end
    end
  end
end
