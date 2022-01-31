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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe 'Homescreen index', type: :feature do
  let!(:user) { build_stubbed(:user) }
  let!(:project) { create(:public_project, identifier: 'public-project') }

  before do
    login_as user
    visit root_url
  end

  describe 'with a dynamic URL in the welcome text',
           with_settings: {
             welcome_text: "With [a link to the public project]({{opSetting:base_url}}/projects/public-project)",
             welcome_on_homescreen?: true
           } do
    it 'renders the correct link' do
      expect(page)
        .to have_selector("a[href=\"#{OpenProject::Application.root_url}/projects/public-project\"]")

      click_link "a link to the public project"
      expect(page).to have_current_path project_path(project)
    end
  end
end
