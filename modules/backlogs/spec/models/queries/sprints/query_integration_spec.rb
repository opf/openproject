# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Queries::Sprints::Query, "integration" do
  shared_let(:project) { create(:project, public: false) }
  shared_let(:other_project) { create(:project, public: false) }
  shared_let(:project_without_permission) { create(:project, public: false) }
  shared_let(:sprint) { create(:sprint, project:, name: "Alpha Sprint") }
  shared_let(:other_sprint) { create(:sprint, project: other_project, name: "Beta Sprint") }
  shared_let(:sprint_without_permission) { create(:sprint, project: project_without_permission) }

  let(:instance) { described_class.new }
  let(:permissions) { %i[view_sprints] }

  current_user do
    create(:user,
           member_with_permissions: {
             project => permissions,
             other_project => permissions
           })
  end

  context "for a user with view_sprints permission" do
    it "returns only sprints visible to the user" do
      expect(instance.results).to contain_exactly(sprint, other_sprint)
    end
  end

  context "for a user without view_sprints permission" do
    let(:permissions) { [] }

    it "returns no sprints" do
      expect(instance.results).to be_empty
    end
  end

  context "with a defining_workspace filter" do
    context "with the = operator" do
      before { instance.where("defining_workspace", "=", [project.id.to_s]) }

      it "returns only sprints from the given project" do
        expect(instance.results).to contain_exactly(sprint)
      end
    end

    context "with the ! operator" do
      before { instance.where("defining_workspace", "!", [project.id.to_s]) }

      it "returns sprints not belonging to the given project" do
        expect(instance.results).to contain_exactly(other_sprint)
      end
    end
  end

  context "with a name filter" do
    context "when searching by a letter" do
      before { instance.where("name", "~", ["a"]) }

      it "returns all sprints matching the name" do
        expect(instance.results).to contain_exactly(sprint, other_sprint)
      end
    end

    context "when searching more precisely" do
      before { instance.where("name", "~", ["alpha"]) }

      it "returns only sprints matching the name" do
        expect(instance.results).to contain_exactly(sprint)
      end
    end

    context "when searching exactly" do
      before { instance.where("name", "=", ["alpha sprint"]) }

      it "returns only sprints matching the name" do
        expect(instance.results).to contain_exactly(sprint)
      end
    end

    context "when containing SQL intjection attempt" do
      before { instance.where("name", "=", ["'); DROP TABLE sprints; --", "beta sprint"]) }

      it "does not allow it" do
        expect(instance.results).to contain_exactly(other_sprint)
      end
    end
  end

  context "with a typeahead filter" do
    context "when searching by a letter" do
      before { instance.where("typeahead", "**", ["a"]) }

      it "returns only sprints matching the search term" do
        expect(instance.results).to contain_exactly(sprint, other_sprint)
      end
    end

    context "when searching more precisely" do
      before { instance.where("typeahead", "**", ["Beta"]) }

      it "returns only sprints matching the search term" do
        expect(instance.results).to contain_exactly(other_sprint)
      end
    end
  end
end
