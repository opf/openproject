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

RSpec.describe Meetings::Widgets::Meetings, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  shared_let(:project_red) { create(:project, name: "Red", enabled_module_names: [:meetings]) }
  shared_let(:project_blue) { create(:project, name: "Blue", enabled_module_names: [:meetings]) }
  shared_let(:author) { create(:user) }
  shared_let(:admin) { create(:admin) }

  let(:project) { nil }

  let(:user) { admin }

  current_user { user }

  subject(:rendered_component) { render_component(project) }

  shared_examples "empty-state without action" do
    it "renders empty blankslate without action" do
      expect(rendered_component).to have_test_selector("meetings-widget-empty")
      expect(rendered_component).to have_text("No upcoming meetings")
      expect(rendered_component).to have_no_test_selector("meetings-widget-add-button")
    end
  end

  shared_examples "empty-state with action" do
    it "renders empty blankslate with add action" do
      expect(rendered_component).to have_test_selector("meetings-widget-empty")
      expect(rendered_component).to have_text("No upcoming meetings")
      expect(rendered_component).to have_test_selector("meetings-widget-add-button")
    end
  end

  context "for root" do
    context "with no meetings" do
      it_behaves_like "empty-state with action"
    end

    context "with meetings" do
      let!(:meeting_red) do
        create(:meeting, project: project_red, author:, start_time: 1.week.from_now, duration: 1).tap do |meeting|
          create(:meeting_participant, meeting:, user: admin, invited: true)
        end
      end
      let!(:meeting_blue) do
        create(:meeting, project: project_blue, author:, start_time: 2.weeks.from_now, duration: 2).tap do |meeting|
          create(:meeting_participant, meeting:, user: admin, invited: true)
        end
      end

      context "with a meeting the user is not participating in" do
        let!(:meeting_other) { create(:meeting, project: project_red, author:, start_time: 3.weeks.from_now) }

        it "does not render meetings the user is not participating in" do
          expect(rendered_component).to have_list_item(count: 2)
          expect(rendered_component).to have_no_link href: project_meeting_path(project_red, meeting_other)
        end
      end

      it "renders meetings items from all projects", :aggregate_failures do
        expect(rendered_component).to have_list_item(count: 2)
        expect(rendered_component).to have_link href: project_meeting_path(project_red, meeting_red)
        expect(rendered_component).to have_list_item(position: 2) do |item|
          expect(item).to have_link href: project_meeting_path(project_blue, meeting_blue)
          expect(item).to have_text("2 hrs")
          expect(item).to have_text("Project: #{project_blue.name}")
        end

        expect(rendered_component).to have_css(".op-widget-box--footer") do |footer|
          expect(footer).to have_link "View all meetings", href: meetings_path
        end
      end
    end
  end

  context "with project" do
    let(:project) { project_red }
    # this meeting from another project should not be visible
    let!(:other_project_meeting) do
      create(:meeting, project: project_blue, author:, start_time: 1.week.from_now, duration: 1) do |meeting|
        create(:meeting_participant, meeting:, user: admin, invited: true)
      end
    end

    context "with no meetings in this project" do
      it_behaves_like "empty-state with action"
    end

    context "with meetings" do
      let!(:meeting_red) do
        create(:meeting, project: project_red, author:, start_time: 1.week.from_now, duration: 1).tap do |meeting|
          create(:meeting_participant, meeting:, user: admin, invited: true)
        end
      end

      it "renders only this project’s meetings which the user participates in" do
        expect(rendered_component).to have_list_item(count: 1)
        expect(rendered_component).to have_list_item(position: 1) do |item|
          expect(item).to have_link href: project_meeting_path(project_red, meeting_red)
          expect(item).to have_text("1 hr")
          expect(item).to have_no_text("Project: #{project_red.name}") # Project is not repeated
        end

        expect(rendered_component).to have_css(".op-widget-box--footer") do |footer|
          expect(footer).to have_link "View all meetings", href: project_meetings_path(project_red)
        end
      end
    end
  end

  context "when the project does not have the meetings module enabled" do
    let(:project) { project_red }
    let!(:meeting_item) { create(:meeting, project:, author:) }

    before do
      project.enabled_module_names -= %w[meetings]
    end

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  context "when the user does not have permission to manage meetings" do
    let(:project) { project_red }
    let(:user) { create(:user) }

    # User has only view_meetings permission now
    it_behaves_like "empty-state without action"
  end
end
