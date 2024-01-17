#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
require_relative '../../support/pages/ifc_models/show_default'

RSpec.describe 'Switching work package view',
               :js,
               with_ee: %i[conditional_highlighting],
               with_config: { edition: 'bim' } do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:wp_page) { Pages::IfcModels::ShowDefault.new(project) }
  let(:highlighting) { Components::WorkPackages::Highlighting.new }
  let(:cards) { Pages::WorkPackageCards.new(project) }

  let(:priority1) { create(:issue_priority, color: create(:color, hexcode: '#123456')) }
  let(:priority2) { create(:issue_priority, color: create(:color, hexcode: '#332211')) }
  let(:status) { create(:status, color: create(:color, hexcode: '#654321')) }

  let(:wp_1) do
    create(:work_package,
           project:,
           priority: priority1,
           status:)
  end
  let(:wp_2) do
    create(:work_package,
           project:,
           priority: priority2,
           status:)
  end

  before do
    wp_1
    wp_2
    allow(EnterpriseToken).to receive(:show_banners?).and_return(false)

    login_as(user)
    wp_page.visit!
    wp_page.expect_work_package_listed wp_1, wp_2
  end

  context 'switching to card view' do
    before do
      # Enable card representation
      wp_page.switch_view 'Cards'
      cards.expect_work_package_listed wp_1, wp_2
    end

    it 'can switch the representations and keep the configuration settings' do
      # Enable highlighting
      highlighting.switch_entire_row_highlight "Priority"
      within "wp-single-card[data-work-package-id='#{wp_1.id}']" do
        expect(page).to have_css(".op-wp-single-card--highlighting.__hl_background_priority_#{priority1.id}")
      end
      within "wp-single-card[data-work-package-id='#{wp_2.id}']" do
        expect(page).to have_css(".op-wp-single-card--highlighting.__hl_background_priority_#{priority2.id}")
      end

      # Switch back to list representation & Highlighting is kept
      wp_page.switch_view 'Table'
      wp_page.expect_work_package_listed wp_1, wp_2
      expect(page).to have_css("#{wp_page.row_selector(wp_1)}.__hl_background_priority_#{priority1.id}")
      expect(page).to have_css("#{wp_page.row_selector(wp_2)}.__hl_background_priority_#{priority2.id}")

      # Change attribute
      highlighting.switch_entire_row_highlight "Status"
      expect(page).to have_css("#{wp_page.row_selector(wp_1)}.__hl_background_status_#{status.id}")
      expect(page).to have_css("#{wp_page.row_selector(wp_2)}.__hl_background_status_#{status.id}")

      # Switch back to card representation & Highlighting is kept, too
      wp_page.switch_view 'Card'
      within "wp-single-card[data-work-package-id='#{wp_1.id}']" do
        expect(page).to have_css(".op-wp-single-card--highlighting.__hl_background_status_#{status.id}")
      end
      within "wp-single-card[data-work-package-id='#{wp_2.id}']" do
        expect(page).to have_css(".op-wp-single-card--highlighting.__hl_background_status_#{status.id}")
      end
    end

    it 'saves the representation in the query' do
      # After refresh the WP are still displayed as cards
      page.driver.browser.navigate.refresh
      cards.expect_work_package_listed wp_1, wp_2
    end
  end

  context 'when reordering an unsaved query' do
    it 'retains that order' do
      wp_page.expect_work_package_order wp_1, wp_2

      wp_page.drag_and_drop_work_package from: 1, to: 0

      wp_page.expect_work_package_order wp_2, wp_1

      wp_page.switch_view 'Cards'

      cards.expect_work_package_order wp_2, wp_1
    end
  end
end
