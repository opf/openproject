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
require 'features/work_packages/work_packages_page'
require_relative '../../support/pages/ifc_models/show_default'

RSpec.describe 'Manual sorting of WP table', :js, with_config: { edition: 'bim' } do
  let(:user) { create(:admin) }
  let(:wp_table) { Pages::IfcModels::ShowDefault.new(project) }

  let(:project) { create(:project, types: [type_task, type_bug]) }
  let(:work_package1) do
    create(:work_package, subject: 'WP1', project:, created_at: Time.zone.now)
  end
  let(:work_package2) do
    create(:work_package,
           subject: 'WP2',
           project:,
           parent: work_package1,
           created_at: 1.minute.ago)
  end
  let(:work_package3) do
    create(:work_package,
           subject: 'WP3',
           project:,
           parent: work_package2,
           created_at: 2.minutes.ago)
  end

  let(:sort_by) { Components::WorkPackages::SortBy.new }
  let(:hierarchies) { Components::WorkPackages::Hierarchies.new }

  def expect_query_order(query, expected)
    retry_block do
      query.reload

      # work_package4 was not positioned
      found = query.ordered_work_packages.pluck(:work_package_id)

      raise "Backend order is incorrect: #{found} != #{expected}" unless found == expected
    end
  end

  before do
    login_as(user)

    work_package1
    work_package2
    work_package3
    wp_table.visit!
    hierarchies.disable_via_header
    wp_table.expect_work_package_order work_package1, work_package2, work_package3

    wp_table.switch_view 'Cards'
    loading_indicator_saveguard
  end

  context 'when view is card' do
    let(:wp_card) { Pages::WorkPackageCards.new(project) }

    it 'can sort cards via DragNDrop' do
      wp_card.drag_and_drop_work_package from: 0, to: 3

      wp_card.expect_work_package_order work_package2, work_package3, work_package4, work_package1

      wp_card.expect_and_dismiss_toaster message: 'Successful creation.'

      query = Query.last
      expect(query.name).to eq 'New manually sorted query'
      expect_query_order(query, [work_package2.id, work_package3.id, work_package4.id, work_package1.id])

      wp_card.drag_and_drop_work_package from: 0, to: 2

      expect_query_order(query, [work_package3.id, work_package4.id, work_package1.id, work_package2.id])
    end
  end
end
