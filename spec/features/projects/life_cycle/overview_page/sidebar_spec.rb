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
require_relative "shared_context"

RSpec.describe "Show project life cycles on project overview page", :js do
  include_context "with seeded projects and phases"

  let(:overview_page) { Pages::Projects::Show.new(project) }

  current_user { admin }

  it "does show the sidebar" do
    overview_page.visit_page
    overview_page.expect_visible_sidebar
  end

  context "when all phases are disabled for this project" do
    before do
      project_life_cycles.each { |p| p.toggle!(:active) }
    end

    it "does not show the sidebar" do
      overview_page.visit_page
      overview_page.expect_no_visible_sidebar
    end
  end

  describe "with correct order and scoping" do
    it "shows the project phases in the correct order" do
      overview_page.visit_page

      overview_page.within_life_cycle_sidebar do
        expected_stages = [
          "Initiating",
          "Planning",
          "Executing",
          "Closing"
        ]
        fields = page.all(".op-project-life-cycle-container > div:first-child")
        expect(fields.map(&:text)).to eq(expected_stages)
      end

      life_cycle_executing_definition.move_to_bottom

      overview_page.visit_page

      overview_page.within_life_cycle_sidebar do
        expected_stages = [
          "Initiating",
          "Planning",
          "Closing",
          "Executing"
        ]
        fields = page.all(".op-project-life-cycle-container > div:first-child")
        expect(fields.map(&:text)).to eq(expected_stages)
      end
    end

    it "shows a hover card when you hover over a gate" do
      overview_page.visit_page

      overview_page.within_life_cycle_sidebar do
        page.find_test_selector("phase-#{life_cycle_planning.id}-start-gate").hover
      end

      expect(page).to have_test_selector("phase-gate-hover-card-name", text: life_cycle_planning.start_gate_name)

      overview_page.within_life_cycle_sidebar do
        page.find_test_selector("phase-#{life_cycle_planning.id}-finish-gate").hover
      end

      expect(page).to have_test_selector("phase-gate-hover-card-name", text: life_cycle_planning.finish_gate_name)
    end

    it "does not show phases not enabled for this project in a sidebar" do
      life_cycle_executing.toggle!(:active)

      overview_page.visit_page

      overview_page.within_life_cycle_sidebar do
        expect(page).to have_no_text life_cycle_executing.name
      end
    end
  end

  describe "with correct values" do
    describe "with values set" do
      it "shows the correct value for the project custom field if given" do
        overview_page.visit_page

        overview_page.within_life_cycle_sidebar do
          project_life_cycles.each do |life_cycle|
            overview_page.within_life_cycle_container(life_cycle) do
              expected_date = [
                life_cycle.start_date.strftime("%m/%d/%Y"),
                life_cycle.finish_date.strftime("%m/%d/%Y")
              ].join("\n-\n")

              expect(page).to have_text expected_date
            end
          end
        end
      end
    end

    describe "with no values" do
      before do
        Project::Phase.update_all(start_date: nil, finish_date: nil)
      end

      it "shows the correct value for the project custom field if given" do
        overview_page.visit_page

        overview_page.within_life_cycle_sidebar do
          project_life_cycles.each do |life_cycle|
            overview_page.within_life_cycle_container(life_cycle) do
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end
      end
    end
  end
end
