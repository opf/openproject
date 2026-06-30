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

RSpec.describe ResourcePlannerViews::UserTimeline::ContentComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:user) do
    create(:user, firstname: "Mary", lastname: "Member",
                  member_with_permissions: { project => %i[view_resource_planners] })
  end
  shared_let(:planner) { create(:resource_planner, project:, principal: user) }

  let(:manual) { false }
  let(:view) do
    create(:resource_user_timeline, parent: planner, project:, principal: user,
                                    query: create(:user_query, project:, principal: user, manual_elements: manual))
  end

  subject(:rendered) do
    render_inline(described_class.new(view:, project:, resource_planner: planner))
    page
  end

  before { login_as(user) }

  context "with selected users" do
    # An automatic view resolves to the project members, so `user` shows up.
    it "renders one swimlane per user" do
      expect(rendered).to have_css("[data-test-selector='resource-user-timeline']")
      expect(rendered).to have_css("[data-test-selector='user-swimlane'][data-user-id='#{user.id}']", text: user.name)
    end
  end

  context "with no users" do
    context "with an automatically filtered view" do
      let(:manual) { false }

      before do
        # Remove the only member so the automatic query resolves to no users.
        Member.where(project:, principal: user).destroy_all
      end

      it "shows a blankslate offering to configure the view" do
        expect(rendered).to have_css(".blankslate")
        expect(rendered).to have_text("No users to display")
        expect(rendered).to have_css(
          "a[data-controller='async-dialog']" \
          "[href='#{edit_project_resource_planner_view_path(project, planner, view)}']",
          text: "Configure view"
        )
      end
    end

    context "with a manually hand-picked view" do
      let(:manual) { true }

      it "invites adding a user through the add dialog" do
        expect(rendered).to have_text("Add users to this view to see their allocation over time.")
        expect(rendered).to have_css(
          "a[data-controller='async-dialog']" \
          "[href='#{new_user_project_resource_planner_view_path(project, planner, view)}']",
          text: "Add user"
        )
      end
    end
  end
end
