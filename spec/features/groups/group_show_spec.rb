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

feature 'group show page', type: :feature do
  let!(:member) { FactoryBot.create :user }
  let!(:group) { FactoryBot.create :group, lastname: "Bob's Team", members: [member] }

  before do
    login_as current_user
  end

  context 'as an admin' do
    shared_let(:admin) { FactoryBot.create :admin }
    let(:current_user) { admin }

    scenario 'I can visit the group page' do
      visit show_group_path(group)
      expect(page).to have_selector('h2', text: "Bob's Team")
      expect(page).to have_selector('.toolbar-item', text: 'Edit')
      expect(page).to have_selector('li', text: member.name)
    end
  end

  context 'as a regular user' do
    let(:current_user) { FactoryBot.create :user }

    scenario 'I can visit the group page' do
      visit show_group_path(group)
      expect(page).to have_selector('h2', text: "Bob's Team")
      expect(page).to have_no_selector('.toolbar-item')
      expect(page).to have_no_selector('li', text: member.name)
    end
  end
end
