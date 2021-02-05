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

describe 'edit placeholder users', type: :feature, js: true do
  using_shared_fixtures :admin
  let(:current_user) { admin }
  let(:placeholder_user) { FactoryBot.create :placeholder_user, name: 'UX Developer' }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  context 'as admin' do
    before do
      visit edit_placeholder_user_path(placeholder_user)
    end

    it 'can edit name' do
      expect(page).to have_selector '#placeholder_user_name'

      fill_in 'placeholder_user[name]', with: 'NewName', fill_options: { clear: :backspace }

      click_on 'Save'

      expect(page).to have_selector('.flash.notice', text: 'Successful update.')

      placeholder_user.reload

      expect(placeholder_user.name).to eq 'NewName'
    end
  end
end
