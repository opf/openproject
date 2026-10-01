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

RSpec.describe Backlogs::SprintPageHeaderComponent, type: :component do
  let(:project) { create(:project, name: "Test Project") }
  let(:start_date) { Date.new(2024, 1, 15) }
  let(:finish_date) { Date.new(2024, 1, 29) }
  let(:sprint) { create(:sprint, project:, name: "Sprint 1", start_date:, finish_date:) }

  def render_component
    render_inline(described_class.new(sprint:, project:))
  end

  describe "rendering" do
    it "renders Primer::OpenProject::PageHeader" do
      render_component

      expect(page).to have_css(".PageHeader")
    end

    it "displays sprint name as title" do
      render_component

      expect(page).to have_css(".PageHeader-title", text: "Sprint 1")
    end

    it "shows date range in description with time tags" do
      render_component

      expect(page).to have_css("time[datetime='2024-01-15']")
      expect(page).to have_css("time[datetime='2024-01-29']")
    end

    it "renders breadcrumbs" do
      render_component

      expect(page).to have_css(".PageHeader-breadcrumbs")
    end

    it "includes project link in breadcrumbs" do
      render_component

      expect(page).to have_link("Test Project")
    end

    it "includes backlogs link in breadcrumbs" do
      render_component

      expect(page).to have_link(I18n.t(:label_backlogs))
    end

    it "includes sprint name as text (not link) in breadcrumbs" do
      render_component

      # The last breadcrumb item should be the sprint name as plain text
      breadcrumbs = page.find(".PageHeader-breadcrumbs")
      expect(breadcrumbs).to have_text("Sprint 1")
    end
  end

  describe "date handling" do
    context "when sprint has only start_date" do
      let(:sprint) { create(:sprint, project:, name: "Sprint 1", start_date:, finish_date: nil) }

      it "renders only start date" do
        render_component

        expect(page).to have_css("time[datetime='2024-01-15']")
        expect(page).to have_no_css("time[datetime='2024-01-29']")
      end
    end

    context "when sprint has only finish_date" do
      let(:sprint) { create(:sprint, project:, name: "Sprint 1", start_date: nil, finish_date:) }

      it "renders only finish date" do
        render_component

        expect(page).to have_no_css("time[datetime='2024-01-15']")
        expect(page).to have_css("time[datetime='2024-01-29']")
      end
    end

    context "when sprint has no dates" do
      let(:sprint) { create(:sprint, project:, name: "Sprint 1", start_date: nil, finish_date: nil) }

      it "renders no time elements" do
        render_component

        expect(page).to have_no_css("time")
      end
    end
  end
end
