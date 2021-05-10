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

describe 'Protected settings', type: :feature do
  current_user { FactoryBot.create(:admin) }

  after do
    Setting.clear_cache
  end

  context "when not overwritten" do
    it 'is the default value and can be altered' do
      visit admin_settings_general_path

      expect(page)
        .to have_field("Application title", with: 'OpenProject')

      fill_in("Application title", with: 'New app title')

      click_button 'Save'

      expect(page)
        .to have_content I18n.t(:notice_successful_update)

      expect(Setting.app_title)
        .to eql 'New app title'
    end
  end

  context "when overwritten" do
    let!(:setting) { Settings::Definition['app_title'] }
    let!(:setting_value) { setting.value.dup }

    before do
      stub_const('ENV', { 'OPENPROJECT_APP__TITLE' => 'Overwritten' })

      Settings::Definition.send(:override_config)
    end

    after do
      setting.value = setting_value
      setting.writable = true
    end

    it 'is the overwritten value and cannot be altered' do
      visit admin_settings_general_path

      expect(page)
        .to have_field("Application title", with: 'Overwritten', disabled: true)
    end
  end
end
