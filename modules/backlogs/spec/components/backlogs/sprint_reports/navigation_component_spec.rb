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
require "rails_helper"

RSpec.describe Backlogs::SprintReports::NavigationComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project) }
  shared_let(:active_sprint) do
    create(:sprint, project:, name: "Active", status: :active,
                    start_date: Date.yesterday, finish_date: Date.tomorrow)
  end
  shared_let(:planned_sprint) do
    create(:sprint, project:, name: "Planned", status: :in_planning,
                    start_date: 10.days.from_now, finish_date: 20.days.from_now)
  end
  shared_let(:recent_sprint) do
    create(:sprint, project:, name: "Recent", status: :completed,
                    start_date: 20.days.ago, finish_date: 10.days.ago)
  end
  shared_let(:oldest_sprint) do
    create(:sprint, project:, name: "Oldest", status: :completed,
                    start_date: 40.days.ago, finish_date: 30.days.ago)
  end

  current_user { create(:user, member_with_permissions: { project => %i[view_sprints] }) }

  subject(:rendered_component) { render_inline(described_class.new(sprint:, project:)) }

  context "for a sprint in the middle of the chronological order" do
    let(:sprint) { active_sprint }

    it "links to the previous sprint's report" do
      expect(rendered_component)
        .to have_link("Previous", href: project_backlogs_sprint_report_path(project, recent_sprint))
    end

    it "links to the next sprint's report" do
      expect(rendered_component)
        .to have_link("Next", href: project_backlogs_sprint_report_path(project, planned_sprint))
    end

    it "shows the neighboring sprint names as plain text" do
      expect(rendered_component).to have_test_selector("sprint-report-previous-name", text: "Recent")
      expect(rendered_component).to have_test_selector("sprint-report-next-name", text: "Planned")
      expect(rendered_component).to have_no_link("Recent")
      expect(rendered_component).to have_no_link("Planned")
    end
  end

  context "for the earliest sprint" do
    let(:sprint) { oldest_sprint }

    it "renders only the next link" do
      expect(rendered_component)
        .to have_link("Next", href: project_backlogs_sprint_report_path(project, recent_sprint))

      expect(rendered_component).to have_no_test_selector("sprint-report-previous")
      expect(rendered_component).to have_no_test_selector("sprint-report-previous-name")
    end
  end

  context "for the latest sprint" do
    let(:sprint) { planned_sprint }

    it "renders only the previous link" do
      expect(rendered_component)
        .to have_link("Previous", href: project_backlogs_sprint_report_path(project, active_sprint))

      expect(rendered_component).to have_no_test_selector("sprint-report-next")
      expect(rendered_component).to have_no_test_selector("sprint-report-next-name")
    end
  end

  context "for the only sprint of a project" do
    let(:project) { create(:project) }
    let(:sprint) { create(:sprint, project:) }

    it "renders nothing" do
      expect(rendered_component.to_html).to be_blank
    end
  end
end
