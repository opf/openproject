# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"
require_relative "../../support/pages/backlog"

RSpec.describe "Show burndown chart", :js do
  include Redmine::I18n

  shared_let(:project) { create(:project, enabled_module_names: %w(backlogs)) }
  shared_let(:sprint) { create(:sprint, status: "active", project:, start_date: 1.week.ago, finish_date: 1.week.from_now) }

  let(:planning_page) { Pages::Backlog.new(project) }
  let(:role) do
    create(:project_role,
           permissions: %i[view_work_packages view_sprints])
  end

  current_user { create(:user, member_with_roles: { project => role }) }

  it "lists burndown in the menu by which the user can navigate to the burndown chart" do
    planning_page.visit!

    planning_page.click_in_sprint_menu(sprint, "Burndown chart")

    expect(page)
      .to have_heading(sprint.name, level: 2)
    expect(page)
      .to have_text "#{sprint.start_date.strftime('%m/%d/%Y')} – #{sprint.finish_date.strftime('%m/%d/%Y')}"
    expect(page)
      .to have_element :"opce-burndown-chart"
  end
end
