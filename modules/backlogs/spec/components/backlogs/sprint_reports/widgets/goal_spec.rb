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

RSpec.describe Backlogs::SprintReports::Widgets::Goal, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:sprint) { create(:sprint, project:) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_sprints] }) }

  current_user { user }

  subject(:rendered_component) { render_inline(described_class.new(sprint, project)) }

  context "when the sprint has a goal for the project" do
    before { create(:sprint_goal, sprint:, project:, text: "Add sprint goal widget") }

    it "renders the goal text under the widget title" do
      expect(rendered_component).to have_text(Sprint.human_attribute_name(:goal))
      expect(rendered_component).to have_text("Add sprint goal widget")
    end
  end

  context "when the sprint has no goal for the project" do
    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  context "when the sprint only has a goal for another project" do
    shared_let(:other_project) { create(:project) }

    before { create(:sprint_goal, sprint:, project: other_project, text: "Goal of the other project") }

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  context "when the user lacks the view_sprints permission" do
    let(:user) { create(:user, member_with_permissions: { project => [] }) }

    before { create(:sprint_goal, sprint:, project:, text: "Add sprint goal widget") }

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end
end
