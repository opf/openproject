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

RSpec.describe ResourcePlanners::IndexSubHeaderComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }

  let(:current_user) { user }

  subject(:rendered) do
    login_as(current_user)
    render_inline(described_class.new(project:))
    page
  end

  context "when the user can view resource planners" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners] })
    end

    it "renders the create button" do
      expect(rendered).to have_link(text: I18n.t("resource_management.label_resource_planner"))
    end
  end

  context "when the user lacks view_resource_planners" do
    let(:user) { create(:user) }

    it "hides the create button" do
      expect(rendered).to have_no_link(text: I18n.t("resource_management.label_resource_planner"))
    end
  end
end
