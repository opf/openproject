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

RSpec.describe CustomFields::Hierarchy::Items::CreateContract,
               :check_errors_i18n,
               with_ee: %i[custom_field_hierarchies weighted_item_lists] do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:admin) }
  let(:custom_field) { create(:hierarchy_wp_custom_field, allow_additional_project_values: true) }
  let(:root) { custom_field.hierarchy_root }
  let(:project) { create(:project) }
  let!(:luke) { create(:hierarchy_item, parent: root, label: "Luke", short: "LS") }

  let(:parent) { root }
  let(:label) { "Leia" }
  let(:short) { "LO" }
  let(:item_project) { nil }
  let(:item) { CustomField::Hierarchy::Item.new(parent:, label:, short:, project: item_project) }

  subject(:contract) { described_class.new(item, current_user) }

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  context "without a parent" do
    let(:parent) { nil }

    it_behaves_like "contract is invalid", parent: :blank
  end

  context "without a label" do
    let(:label) { "" }

    it_behaves_like "contract is invalid", label: :blank
  end

  context "without a short" do
    let(:short) { nil }

    it_behaves_like "contract is valid"
  end

  context "with a label used by a sibling in a different case" do
    let(:label) { "lUKE" }

    it_behaves_like "contract is invalid", label: :not_unique
  end

  context "with a short used by a sibling in a different case" do
    let(:short) { "ls" }

    it_behaves_like "contract is invalid", short: :not_unique
  end

  context "with a label used in another branch" do
    let(:parent) { create(:hierarchy_item, parent: root, label: "Han") }
    let(:label) { "Luke" }
    let(:short) { "LS" }

    it_behaves_like "contract is valid"
  end

  context "with the label of a project sibling" do
    let(:label) { "chewie" }

    before { create(:hierarchy_item, parent: root, label: "Chewie", project:) }

    it_behaves_like "contract is invalid", label: :not_unique
  end

  context "with a project item as parent" do
    let(:parent) { create(:hierarchy_item, parent: root, label: "Chewie", project:) }

    it_behaves_like "contract is invalid", parent: :other_project
  end

  context "for a project" do
    let(:item_project) { project }

    it_behaves_like "contract is valid"

    context "when the custom field does not allow additional project values" do
      let(:custom_field) { create(:hierarchy_wp_custom_field, allow_additional_project_values: false) }

      it_behaves_like "contract is invalid", project_id: :additional_values_not_allowed
    end

    context "with the label of a global sibling" do
      let(:label) { "luke" }

      it_behaves_like "contract is invalid", label: :not_unique
    end

    context "with the label of another project's sibling" do
      let(:label) { "chewie" }

      before { create(:hierarchy_item, parent: root, label: "Chewie", project: create(:project)) }

      it_behaves_like "contract is valid"
    end

    context "with an item of the same project as parent" do
      let(:parent) { create(:hierarchy_item, parent: root, label: "Chewie", project:) }

      it_behaves_like "contract is valid"
    end

    context "with an item of another project as parent" do
      let(:parent) { create(:hierarchy_item, parent: root, label: "Jabba", project: create(:project)) }

      it_behaves_like "contract is invalid", parent: :other_project
    end
  end

  context "for a weighted item list" do
    let(:custom_field) { create(:weighted_item_list_wp_custom_field) }
    let(:weight) { "2.5" }
    let(:item) { CustomField::Hierarchy::Item.new(parent:, label:, weight:) }

    it_behaves_like "contract is valid"

    context "without a weight" do
      let(:weight) { nil }

      it_behaves_like "contract is invalid", weight: :blank
    end

    context "with a non-numeric weight" do
      let(:weight) { "heavy" }

      it_behaves_like "contract is invalid", weight: :not_a_number
    end
  end
end
