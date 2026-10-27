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

RSpec.describe ResourcePlanners::ShowPageHeaderComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:owner) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners] })
  end
  shared_let(:public_manager) do
    create(:user,
           member_with_permissions: { project => %i[view_resource_planners manage_public_resource_planners] })
  end

  let(:resource_planner) { create(:resource_planner, project:, principal: owner, public: false, name: "My planner") }
  let(:current_user) { owner }

  subject(:rendered) do
    login_as(current_user)
    render_inline(described_class.new(resource_planner:))
    page
  end

  it "renders the planner title" do
    expect(rendered).to have_text("My planner")
  end

  describe "the timeframe" do
    context "when the planner has a range" do
      let(:resource_planner) do
        create(:resource_planner, project:, principal: owner, name: "My planner",
                                  start_date: Date.new(2026, 8, 1), end_date: Date.new(2026, 8, 14))
      end

      it "is described in the header" do
        expect(rendered).to have_text(
          I18n.t("resource_management.timeframe.full",
                 start: I18n.l(Date.new(2026, 8, 1)),
                 end: I18n.l(Date.new(2026, 8, 14)))
        )
      end
    end

    context "when the planner has no range" do
      it "is omitted from the header" do
        expect(rendered).to have_no_text(/From .* to /)
      end
    end
  end

  context "as the owner" do
    it "renders the edit and delete actions" do
      expect(rendered).to have_css("[data-test-selector='resource-planner-edit']")
      expect(rendered).to have_css("[data-test-selector='resource-planner-delete']")
    end

    it "renders the favorite toggle" do
      expect(rendered).to have_css("[data-test-selector='resource-planner-favorite']")
    end
  end

  context "when the planner is favorited by the user" do
    before { resource_planner.add_favoriting_user(owner) }

    it "renders the unfavorite toggle" do
      expect(rendered).to have_css("[data-test-selector='resource-planner-unfavorite']")
      expect(rendered).to have_no_css("[data-test-selector='resource-planner-favorite']")
    end
  end

  context "as a user who cannot manage the planner" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners] })
    end
    let(:resource_planner) do
      create(:resource_planner, project:, principal: public_manager, public: true, name: "Shared planner")
    end

    it "hides the edit and delete actions" do
      expect(rendered).to have_no_css("[data-test-selector='resource-planner-edit']")
      expect(rendered).to have_no_css("[data-test-selector='resource-planner-delete']")
    end

    it "still offers the favorite toggle" do
      expect(rendered).to have_css("[data-test-selector='resource-planner-favorite']")
    end
  end
end
