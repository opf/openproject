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

RSpec.describe Project::PhaseDefinitions::Scopes::WithProjectCount do
  let!(:definition_a) { create(:project_phase_definition, name: "foo") }
  let!(:definition_b) { create(:project_phase_definition, name: "bar") }
  let!(:definition_c) { create(:project_phase_definition, name: "baz") }

  before do
    create(:project).tap do |project|
      create(:project_phase, project:, definition: definition_a)
      create(:project_phase, project:, definition: definition_b)
    end

    create(:project).tap do |project|
      create(:project_phase, project:, definition: definition_a)
      create(:project_phase, project:, definition: definition_b, active: false)
    end
  end

  describe ".with_project_count" do
    it "queries project counts alongside definitions" do
      expect(Project::PhaseDefinition.with_project_count).to contain_exactly(
        having_attributes(id: definition_a.id, name: "foo", project_count: 2),
        having_attributes(id: definition_b.id, name: "bar", project_count: 1),
        having_attributes(id: definition_c.id, name: "baz", project_count: 0)
      )
    end
  end
end
