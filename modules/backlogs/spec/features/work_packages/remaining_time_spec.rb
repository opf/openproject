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

describe 'Work packages remaining time', js: true do
  before do
    allow(User).to receive(:current).and_return current_user
    allow(Setting).to receive(:plugin_openproject_backlogs).and_return('points_burn_direction' => 'down',
                                                                       'wiki_template' => '',
                                                                       'card_spec' => 'Sattleford VM-5040',
                                                                       'story_types' => [story_type.id.to_s],
                                                                       'task_type' => task_type.id.to_s)
  end

  let(:current_user) { create(:admin) }
  let(:project) do
    create(:project,
           enabled_module_names: %w(work_package_tracking backlogs))
  end
  let(:status) { create :default_status }
  let(:story_type) { create(:type_feature) }
  let(:task_type) { create(:type_feature) }

  let(:work_package) do
    create :story,
           type: task_type,
           author: current_user,
           project:,
           status:
  end

  it 'can set and edit the remaining time in hours (Regression #43549)' do
    wp_page = Pages::FullWorkPackage.new(work_package)

    wp_page.visit!
    wp_page.expect_subject

    wp_page.expect_attributes remainingTime: '-'

    wp_page.update_attributes remainingTime: '125' # rubocop:disable Rails/ActiveRecordAliases

    wp_page.expect_attributes remainingTime: '125 h'

    work_package.reload

    expect(work_package.remaining_hours).to eq 125.0
  end

  it 'displays the remaining time sum properly in hours (Regression #43833)' do
    work_package
    wp_table_page = Pages::WorkPackagesTable.new(project)

    query_props = JSON.dump(c: %w(id subject remainingTime),
                            s: true)

    wp_table_page.visit_with_params("query_props=#{query_props}")

    wp_table_page.expect_work_package_with_attributes work_package, remainingTime: '-'

    wp_table_page.update_work_package_attributes work_package, remainingTime: '125'

    wp_table_page.expect_work_package_with_attributes work_package, remainingTime: '125 h'

    wp_table_page.expect_sums_row_with_attributes remainingTime: '125 h'

    work_package.reload
    expect(work_package.remaining_hours).to eq 125.0
  end
end
