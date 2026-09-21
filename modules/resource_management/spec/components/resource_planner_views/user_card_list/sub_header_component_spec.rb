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

RSpec.describe ResourcePlannerViews::UserCardList::SubHeaderComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners] })
  end
  shared_let(:resource_planner) { create(:resource_planner, project:, principal: user) }

  let(:manual) { false }
  let(:view) do
    create(:resource_user_card, parent: resource_planner, project:, principal: user,
                                query: create(:user_query, project:, principal: user, manual_elements: manual))
  end

  subject(:rendered) do
    render_inline(described_class.new(project:, resource_planner:, view:))
    page
  end

  before { login_as(user) }

  it "links the settings action to the edit dialog" do
    expect(rendered).to have_link(
      href: edit_project_resource_planner_view_path(project, resource_planner, view)
    )
  end

  context "with an automatic view" do
    let(:manual) { false }

    it "offers no add resource button" do
      expect(rendered).to have_no_text(I18n.t("resource_management.user_card_list.subheader.resource"))
    end
  end

  context "with a manual view" do
    let(:manual) { true }

    it "offers the add resource button" do
      expect(rendered).to have_text(I18n.t("resource_management.user_card_list.subheader.resource"))
      expect(rendered).to have_link(
        href: new_user_project_resource_planner_view_path(project, resource_planner, view)
      )
    end
  end
end
