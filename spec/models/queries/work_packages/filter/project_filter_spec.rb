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

RSpec.describe Queries::WorkPackages::Filter::ProjectFilter do
  it_behaves_like "basic query filter" do
    let(:type) { :list }
    let(:class_key) { :project_id }
    let(:visible_projects) { build_stubbed_list(:project, 2) }

    before do
      scope = class_double(Project)

      allow(Project)
        .to receive(:visible)
              .and_return(scope)

      allow(scope)
        .to receive(:active)
              .and_return(visible_projects)

      without_partial_double_verification do
        allow(visible_projects)
          .to receive(:exists?)
                .and_return(visible_projects.any?)

        allow(visible_projects)
          .to receive(:where) do |args|
          ids = args[:id]
          visible_projects.select { |p| ids.include?(p.id) }
        end
      end
    end

    describe "#available?" do
      shared_examples_for "filter availability" do
        context "when able to see projects" do
          it "is true" do
            expect(instance).to be_available
          end
        end

        context "when not able to see projects" do
          let(:visible_projects) { [] }

          it "is true" do
            expect(instance).not_to be_available
          end
        end
      end

      context "when inside a project" do
        # Used to be always false hence still checking.
        it_behaves_like "filter availability"
      end

      context "when outside of a project" do
        let(:project) { nil }

        it_behaves_like "filter availability"
      end
    end

    describe "#allowed_values" do
      let(:project) { nil }
      let(:parent) { build_stubbed(:project, id: 1) }
      let(:child) { build_stubbed(:project, parent:, id: 2) }
      let(:visible_projects) { [parent, child] }

      it "is an array of group values" do
        allow(Project)
          .to receive(:project_tree)
          .with(visible_projects)
          .and_yield(parent, 0)
          .and_yield(child, 1)

        expect(instance.allowed_values)
          .to contain_exactly([parent.name, parent.id.to_s], ["-- #{child.name}", child.id.to_s])
      end
    end

    describe "#ar_object_filter?" do
      it "is true" do
        expect(instance)
          .to be_ar_object_filter
      end
    end

    describe "#value_objects" do
      let(:selected) { visible_projects.first }
      let(:visible_descendants) { [] }
      let(:descendants) { double("Project", visible: visible_descendants) } # rubocop:disable RSpec/VerifiedDoubles

      before do
        allow(selected).to receive(:descendants).and_return(descendants)

        instance.values = [selected.id.to_s]
      end

      it "returns an array of projects" do
        expect(instance.value_objects)
          .to contain_exactly(selected)
      end

      context "with a visible child" do
        # No explicit id: the point is only that the child is a different project from
        # its parent, and a hardcoded one can collide with the id the parent was stubbed
        # with, which makes the two compare equal and the example prove nothing.
        let(:child) { build_stubbed(:project, parent: selected) }
        let(:visible_descendants) { [child] }

        it "still only returns the parent object" do
          expect(instance.value_objects)
            .to contain_exactly(selected)
        end
      end
    end
  end

  describe "with project identifiers as values" do
    let(:project) { create(:project, identifier: "current_id") }
    let(:other_project) { create(:project) }
    let(:invisible_project) { create(:project) }
    let(:instance) do
      described_class.create!(name: :project_id, context: build_stubbed(:query, project: nil), operator: "=", values:)
    end

    before do
      allow(Project).to receive(:visible).and_return(Project.where(id: [project, other_project]))
    end

    context "with an identifier and an id" do
      let(:values) { ["CURRENT_ID", other_project.id.to_s] }

      it "resolves the identifier and keeps the values as given" do
        expect(instance.project_ids).to eq([project.id.to_s, other_project.id.to_s])
        expect(instance.values).to eq(["CURRENT_ID", other_project.id.to_s])
      end

      it { expect(instance).to be_valid }

      it "returns the projects" do
        expect(instance.value_objects).to contain_exactly(project, other_project)
      end
    end

    context "with a former identifier" do
      let(:values) { %w[former_id] }

      before do
        FriendlyId::Slug.create!(sluggable: project, slug: "former_id")
      end

      it "resolves the identifier" do
        expect(instance.project_ids).to eq([project.id.to_s])
      end
    end

    context "with the identifier of a project the user cannot see" do
      let(:values) { [project.identifier, invisible_project.identifier] }

      it { expect(instance).not_to be_valid }

      it "drops only that identifier when reduced to the valid values" do
        instance.valid_values!

        expect(instance.values).to eq([project.identifier])
      end
    end
  end
end
