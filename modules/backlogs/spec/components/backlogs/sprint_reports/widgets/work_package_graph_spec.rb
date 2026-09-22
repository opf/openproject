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

RSpec.describe Backlogs::SprintReports::Widgets::WorkPackageGraph, type: :component do
  let(:project) { build_stubbed(:project) }
  let(:sprint) { build_stubbed(:sprint, project:) }
  let(:user) { build_stubbed(:user) }

  subject(:rendered_component) { render_inline(described_class.new(sprint, project, current_user: user)) }

  before do
    mock_permissions_for(user) do |mock|
      mock.allow_in_project(:view_sprints, project:)
    end
  end

  it "renders the work package graph element" do
    expect(rendered_component).to have_element(:"opce-wp-overview-graph")
  end

  it "scopes the graph to the sprint and project, and hides the group-by select" do
    element = rendered_component.at("opce-wp-overview-graph")

    expect(element["global-scope"]).to eq("false")
    expect(element["show-group-by-options"]).to eq("false")

    filters = JSON.parse(element["initial-filters"])
    expect(filters).to contain_exactly(
      { "sprint" => { "operator" => "=", "values" => [sprint.id] } },
      { "project" => { "operator" => "=", "values" => [project.id] } }
    )
  end

  context "when the user lacks view_sprints" do
    before do
      mock_permissions_for(user, &:forbid_everything)
    end

    it "does not render" do
      expect(rendered_component).to have_no_element(:"opce-wp-overview-graph")
    end
  end
end
