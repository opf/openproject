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

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe CustomFields::Hierarchy::Items::UpdateContract,
               :check_errors_i18n,
               with_ee: %i[custom_field_hierarchies weighted_item_lists] do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:admin) }
  let(:custom_field) { create(:hierarchy_wp_custom_field) }
  let(:root) { custom_field.hierarchy_root }
  let(:project) { create(:project) }
  let!(:luke) { create(:hierarchy_item, parent: root, label: "Luke", short: "LS") }
  let!(:mara) { create(:hierarchy_item, parent: luke, label: "Mara", short: "MJ") }
  let!(:leia) { create(:hierarchy_item, parent: root, label: "Leia", short: "LO") }

  let(:item) { luke }
  let(:attributes) { { label: "Luke Skywalker", short: "SKY" } }

  subject(:contract) { described_class.new(item, current_user) }

  before { item.assign_attributes(attributes) }

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  context "without a label" do
    let(:attributes) { { label: "" } }

    it_behaves_like "contract is invalid", label: :blank
  end

  context "with a label used by a sibling in a different case" do
    let(:attributes) { { label: "LEIA" } }

    it_behaves_like "contract is invalid", label: :not_unique
  end

  context "with its own label in a different case" do
    let(:attributes) { { label: "LUKE" } }

    it_behaves_like "contract is valid"
  end

  context "with a short used by a sibling in a different case" do
    let(:attributes) { { short: "lo" } }

    it_behaves_like "contract is invalid", short: :not_unique
  end

  context "for the root" do
    let(:item) { root }
    let(:attributes) { { label: "Root" } }

    it_behaves_like "contract is invalid", parent: :blank
  end

  context "when changing the project" do
    let(:attributes) { { project: } }

    it_behaves_like "contract is invalid", project_id: :error_readonly
  end

  context "when changing the parent" do
    let(:attributes) { { parent: leia } }

    it_behaves_like "contract is valid"

    context "to the root" do
      let(:item) { mara }
      let(:attributes) { { parent: root } }

      it_behaves_like "contract is valid"
    end

    context "to the item itself" do
      let(:attributes) { { parent: luke } }

      it_behaves_like "contract is invalid", parent: :own_descendant
    end

    context "to a descendant of the item" do
      let(:attributes) { { parent: mara } }

      it_behaves_like "contract is invalid", parent: :own_descendant
    end

    context "to an item of another custom field" do
      let(:other_custom_field) { create(:hierarchy_wp_custom_field) }
      let(:attributes) { { parent: create(:hierarchy_item, parent: other_custom_field.hierarchy_root, label: "Vader") } }

      it_behaves_like "contract is invalid", parent: :other_hierarchy
    end

    context "to a parent with a child using the label in a different case" do
      let(:item) { mara }

      before { create(:hierarchy_item, parent: leia, label: "MARA") }

      it_behaves_like "contract is invalid", label: :not_unique
    end

    context "to a project item" do
      let(:attributes) { { parent: create(:hierarchy_item, parent: root, label: "Chewie", project:) } }

      it_behaves_like "contract is invalid", parent: :other_project
    end
  end

  context "for a project item" do
    let(:item) { create(:hierarchy_item, parent: root, label: "Chewie", project:) }
    let(:attributes) { { parent: leia } }

    it_behaves_like "contract is valid"

    context "when moving next to another project's item with the same label" do
      before { create(:hierarchy_item, parent: leia, label: "CHEWIE", project: create(:project)) }

      it_behaves_like "contract is valid"
    end

    context "when moving next to a global item with the same label" do
      before { create(:hierarchy_item, parent: leia, label: "CHEWIE") }

      it_behaves_like "contract is invalid", label: :not_unique
    end

    context "when moving below an item of another project" do
      let(:attributes) { { parent: create(:hierarchy_item, parent: root, label: "Jabba", project: create(:project)) } }

      it_behaves_like "contract is invalid", parent: :other_project
    end
  end

  context "for a weighted item list" do
    let(:custom_field) { create(:weighted_item_list_wp_custom_field) }
    let(:attributes) { { weight: "42" } }

    it_behaves_like "contract is valid"

    context "without a weight" do
      let(:attributes) { { weight: "" } }

      it_behaves_like "contract is invalid", weight: :blank
    end
  end
end
