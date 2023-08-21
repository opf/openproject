#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

RSpec.describe 'Top menu item for boards', :js, :with_cuprite do
  let(:user) { create(:admin) }

  let(:menu) { find(".op-app-menu a[title='#{I18n.t('label_modules')}']") }
  let(:boards) { I18n.t('boards.label_boards') }

  before do
    allow(User).to receive(:current).and_return user
  end

  shared_examples_for 'the boards menu item' do
    it "sends the user to the boards overview when clicked" do
      menu.click

      within '#more-menu' do
        click_on boards
      end

      expect(page).to have_content(boards)
      expect(page).to have_content(I18n.t(:no_results_title_text))
    end
  end

  context 'when in the project settings' do
    let!(:project) { create(:project) }

    before do
      visit "/projects/#{project.identifier}/settings/general"
    end

    it_behaves_like 'the boards menu item'
  end

  context 'on the landing page' do
    before do
      visit root_path
    end

    it_behaves_like 'the boards menu item'

    context 'with missing permissions' do
      let(:user) { create(:user) }

      it "does not display the menu item" do
        within '#more-menu', visible: false do
          expect(page).not_to have_link boards
        end
      end
    end
  end
end
