#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

feature 'MySQL deprecation spec', js: true do
  let(:user) { FactoryBot.create :admin }

  before do
    Capybara.reset!
    login_as user


  end

  it 'renders a warning in admin areas', with_config: { show_warning_bars: true } do
    if OpenProject::Database.postgresql?
      # Does not render
      visit info_admin_index_path
      expect(page).to have_no_selector('#mysql-db-warning')
    else
      visit home_path
      expect(page).to have_no_selector('#mysql-db-warning')

      visit info_admin_index_path
      expect(page).to have_selector('#mysql-db-warning')

      # Hides in localstorage
      find('.warning-bar--disable-on-hover').click
      expect(page).to have_no_selector('#mysql-db-warning')

      visit info_admin_index_path
      expect(page).to have_no_selector('#mysql-db-warning')
    end
  end
end
