# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Gantt sidebar navigation",
               :js do
  let(:user) { create(:admin) }
  let(:enabled_module_names) { %i[work_package_tracking gantt] }
  let(:project) { create(:project, enabled_module_names:) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(project) }

  let!(:work_package) do
    create(:work_package,
           project:,
           start_date: Date.current,
           due_date: Date.current + 5.days)
  end

  before do
    login_as(user)
  end

  it "renders the gantt chart when navigating there from the work packages list via the sidebar (#DREAM-1055)" do
    wp_table.visit!
    loading_indicator_saveguard

    find(".main-menu--arrow-left-to-project").click

    gantt_link = page.find_by_id("main-menu-gantt")

    # The gantt entry disables Turbo Drive (data-turbo="false") so that navigating to it
    # always performs a full page load instead of a Turbo visit, which previously left the
    # gantt chart missing/blank next to the table.
    expect(gantt_link["data-turbo"]).to eq("false")

    gantt_link.click
    loading_indicator_saveguard

    wp_timeline.expect_timeline!(open: true)
    wp_timeline.expect_work_package_listed work_package
  end
end
