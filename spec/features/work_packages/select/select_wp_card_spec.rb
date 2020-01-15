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

describe 'Select work package card', type: :feature, js: true, selenium: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.create(:project) }
  let(:work_package_1) { FactoryBot.create(:work_package, project: project) }
  let(:work_package_2) { FactoryBot.create(:work_package, project: project) }
  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:wp_card_view) { ::Pages::WorkPackageCards.new(project) }

  let(:display_representation) { ::Components::WorkPackages::DisplayRepresentation.new }

  before do
    login_as(user)

    work_package_1
    work_package_2

    wp_table.visit!
    wp_table.expect_work_package_listed(work_package_1)
    wp_table.expect_work_package_listed(work_package_2)

    display_representation.switch_to_card_layout
  end

  describe 'opening' do
    it 'the full screen view via double click' do
      wp_card_view.open_full_screen_by_doubleclick(work_package_1)
      expect(page).to have_selector('.work-packages--details--subject',
                                    text: work_package_1.subject)
    end

    it 'the split screen of the selected WP' do
      wp_card_view.select_work_package(work_package_2)
      find('#work-packages-details-view-button').click
      split_wp = Pages::SplitWorkPackage.new(work_package_2)
      split_wp.expect_attributes Subject: work_package_2.subject

      find('#work-packages-details-view-button').click
      expect(page).to have_no_selector('.work-packages--details')
    end
  end
end
