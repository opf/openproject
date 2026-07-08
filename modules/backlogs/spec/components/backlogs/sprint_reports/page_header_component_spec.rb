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

require "rails_helper"

RSpec.describe Backlogs::SprintReports::PageHeaderComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) { create(:project, name: "Test Project") }
  let(:sprint) { create(:sprint, project:, name: "Sprint 42") }

  subject(:rendered_component) { render_inline(described_class.new(sprint:, project:)) }

  it "shows the sprint report title" do
    expect(rendered_component).to have_css(".PageHeader-title", text: "Sprint 42 report")
  end

  describe "breadcrumbs" do
    it "links to the project overview" do
      expect(rendered_component).to have_link("Test Project", href: project_overview_path(project))
    end

    it "links to the backlogs" do
      expect(rendered_component).to have_link("Backlogs", href: project_backlogs_backlog_path(project))
    end

    it "links to the sprints list" do
      expect(rendered_component).to have_link("Sprint 42", href: project_backlogs_sprints_path(project))
    end

    it "shows 'Report' as the current page" do
      expect(rendered_component).to have_css(".PageHeader-breadcrumbs", text: "Report")
    end
  end
end
