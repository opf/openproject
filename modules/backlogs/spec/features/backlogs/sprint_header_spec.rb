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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_relative "../../support/pages/backlog"

RSpec.describe "Sprint header", :js do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_sprints view_work_packages] }) }
  shared_let(:sprint) do
    create(:sprint, project:,
                    start_date: Date.new(2025, 9, 1),
                    finish_date: Date.new(2025, 9, 14))
  end

  let(:backlog_page) { Pages::Backlog.new(project) }

  before { login_as(user) }

  describe "sprint header" do
    shared_let(:wp_in_project) { create(:work_package, project:, sprint:, story_points: 5) }
    shared_let(:wp_in_project2) { create(:work_package, project:, sprint:, story_points: 3) }
    shared_let(:wp_in_other_project) { create(:work_package, project: other_project, sprint:, story_points: 10) }

    it "only counts work packages belonging to the viewed project" do
      backlog_page.visit!

      backlog_page.expect_sprint_story_points(sprint, 8)
      backlog_page.expect_sprint_work_package_count(sprint, 2)
    end
  end
end
