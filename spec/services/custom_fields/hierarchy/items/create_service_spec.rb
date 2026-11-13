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

RSpec.describe CustomFields::Hierarchy::Items::CreateService, with_ee: %i[custom_field_hierarchies] do
  subject(:result) { described_class.new(user:).call(parent: root, label: "bob", **attributes) }

  let(:user) { create(:admin) }
  let(:custom_field) { create(:wp_custom_field, :hierarchy) }
  let(:root) { custom_field.hierarchy_root }
  let!(:luke) { create(:hierarchy_item, parent: root, label: "luke", short: "LS") }
  let!(:mara) { create(:hierarchy_item, parent: luke, label: "mara") }
  let!(:leia) { create(:hierarchy_item, parent: root, label: "leia") }
  let(:attributes) { {} }

  it "appends the item to the parent" do
    expect(result).to be_success
    expect(root.reload.children.to_a).to eq([luke, leia, result.result])
  end

  context "with a sort order" do
    let(:attributes) { { sort_order: 1 } }

    it "inserts the item at that position" do
      expect(result).to be_success
      expect(root.reload.children.to_a).to eq([luke, result.result, leia])
    end

    it "rebuilds the position cache" do
      expect(result).to be_success

      preordered_labels = root.reload.self_and_descendants_preordered.pluck(:label)
      expect(root.self_and_descendants.reorder(:position_cache).pluck(:label)).to eq(preordered_labels)
    end
  end

  context "without a label" do
    subject(:result) { described_class.new(user:).call(parent: root, label: "") }

    it "does not create the item" do
      expect(result).to be_failure
      expect(root.reload.children.to_a).to eq([luke, leia])
    end
  end

  context "with project items" do
    let(:project) { create(:project) }
    let!(:jedi) { create(:hierarchy_item, parent: root, label: "jedi", project:) }

    before { custom_field.update!(allow_additional_project_values: true) }

    it "keeps a global item before the project items" do
      expect(result).to be_success
      expect(root.reload.children.to_a).to eq([luke, leia, result.result, jedi])
    end

    context "with a global item positioned within the project items" do
      let(:attributes) { { sort_order: jedi.sort_order } }

      it "places it before the project items" do
        expect(result).to be_success
        expect(root.reload.children.to_a).to eq([luke, leia, result.result, jedi])
      end
    end

    context "with a project item" do
      let(:attributes) { { project: } }

      it "assigns the project" do
        expect(result).to be_success
        expect(result.result.project).to eq(project)
      end

      it "appends it after the project items" do
        expect(result).to be_success
        expect(root.reload.children.to_a).to eq([luke, leia, jedi, result.result])
      end
    end

    context "with a project item positioned within the global items" do
      let(:attributes) { { project:, sort_order: luke.sort_order } }

      it "appends it after the project items" do
        expect(result).to be_success
        expect(root.reload.children.to_a).to eq([luke, leia, jedi, result.result])
      end
    end

    context "with a project item positioned within the project items" do
      let(:attributes) { { project:, sort_order: jedi.sort_order } }

      it "honors the position" do
        expect(result).to be_success
        expect(root.reload.children.to_a).to eq([luke, leia, result.result, jedi])
      end
    end

    context "when the custom field does not allow additional project values" do
      let(:attributes) { { project: } }

      before { custom_field.update!(allow_additional_project_values: false) }

      it "does not create the item" do
        expect(result).to be_failure
        expect(root.reload.children.to_a).to eq([luke, leia, jedi])
      end
    end
  end
end
