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

RSpec.describe Backlogs::SprintsComponent, type: :component do
  shared_let(:sprints) { [] }
  shared_let(:work_packages_by_sprint_id) { WorkPackage.all.group_by(&:sprint_id) }
  shared_let(:active_sprint_ids) { [] }

  let(:permissions) { %i[create_sprints] }
  let(:project) { create(:project) }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  current_user { user }

  def render_component
    render_inline(
      described_class.new(
        sprints:, work_packages_by_sprint_id:, active_sprint_ids:, project:, current_user:
      )
    )
  end

  before { render_component }

  it "renders the sprints heading" do
    expect(page).to have_css("h3", text: "Sprints")
  end

  describe "new sprint button" do
    context "when the user can create sprints and the project does not receive shared sprints" do
      let(:project) { create(:project, sprint_sharing: "no_sharing") }

      it "renders the new sprint button" do
        expect(page).to have_css("[data-test-selector='op-sprints--new-sprint-button']")
      end
    end

    context "when the project receives shared sprints" do
      let(:project) { create(:project, sprint_sharing: "receive_shared") }

      it "does not render the new sprint button" do
        expect(page).to have_no_css("[data-test-selector='op-sprints--new-sprint-button']")
      end
    end

    context "when the user lacks create_sprints permission" do
      let(:permissions) { %i[view_sprints] }

      it "does not render the new sprint button" do
        expect(page).to have_no_css("[data-test-selector='op-sprints--new-sprint-button']")
      end
    end
  end

  describe "with no sprints" do
    it "renders the blankslate title" do
      expect(page).to have_text("No sprints present yet")
    end

    context "when the user can manage sprint sharing" do
      context "when the project receives shared sprints" do
        let(:permissions) { %i[share_sprint] }
        let(:project) { create(:project, sprint_sharing: "receive_shared") }

        it "shows the receive_and_manage description with a settings link" do
          expect(page).to have_text(/This project receives sprints/)
          expect(page).to have_link("project settings")
        end
      end

      context "when the user can create sprints and the project does not receive shared sprints" do
        let(:permissions) { %i[share_sprint create_sprints] }

        it "shows the create_and_manage description with a settings link" do
          expect(page).to have_text(/To start planning your sprint, create one here/)
          expect(page).to have_link("project settings")
        end
      end

      context "when the user cannot create sprints" do
        let(:permissions) { %i[share_sprint] }

        it "shows the manage description with a settings link" do
          expect(page).to have_text(/To start planning your sprint, go to the/)
          expect(page).to have_link("project settings")
        end
      end
    end

    context "when the user cannot manage sprint sharing" do
      context "when the project receives shared sprints" do
        let(:permissions) { %i[view_sprints] }
        let(:project) { create(:project, sprint_sharing: "receive_shared") }

        it "shows the receive description without a settings link" do
          expect(page).to have_text(/This project receives shared sprints/)
          expect(page).to have_no_link("project settings")
        end
      end

      context "when the user can create sprints" do
        let(:permissions) { %i[create_sprints] }

        it "shows the create description without a settings link" do
          expect(page).to have_text("To start planning your sprint, create one here.")
          expect(page).to have_no_link("project settings")
        end
      end

      context "when the user cannot create sprints" do
        let(:permissions) { %i[view_sprints] }

        it "shows the no_actions description" do
          expect(page).to have_text("No sprints are available for this project yet.")
        end
      end
    end
  end

  describe "with sprints" do
    let(:sprints) { create_list(:sprint, 2, project:) }

    it "does not render the blankslate" do
      expect(page).to have_no_text("No sprints present yet")
    end

    it "renders a SprintComponent for each sprint" do
      sprints.each do |sprint|
        expect(page).to have_css(".Box#sprint_#{sprint.id}")
      end
    end
  end
end
