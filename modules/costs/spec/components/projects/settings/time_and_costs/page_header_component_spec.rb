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
require_module_spec_helper

RSpec.describe Projects::Settings::TimeAndCosts::PageHeaderComponent, type: :component do
  let(:project) { create(:project, enabled_module_names: %i[costs]) }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  current_user { user }

  subject(:rendered_component) { render_inline(described_class.new(project:, selected: :time_tracking)) }

  context "with both permissions" do
    let(:permissions) { %i[edit_project manage_project_activities] }

    it "renders all tabs" do
      expect(rendered_component).to have_link("Time tracking")
      expect(rendered_component).to have_link("Activities")
      expect(rendered_component).to have_link("Cost types")
    end
  end

  context "when the user can only edit the project" do
    let(:permissions) { %i[edit_project] }

    it "renders only the time tracking tab" do
      expect(rendered_component).to have_link("Time tracking")
      expect(rendered_component).to have_no_link("Activities")
      expect(rendered_component).to have_no_link("Cost types")
    end
  end

  context "when the user can only manage activities" do
    let(:permissions) { %i[manage_project_activities] }

    it "renders the activities and cost types tabs" do
      expect(rendered_component).to have_no_link("Time tracking")
      expect(rendered_component).to have_link("Activities")
      expect(rendered_component).to have_link("Cost types")
    end
  end
end
