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

RSpec.describe CustomField::ProjectSpecificValues, "ancestors of project-specific values",
               with_ee: %i[custom_field_hierarchies project_specific_list_values] do
  include ProjectSpecificValuesHelpers

  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  let(:custom_field) { create(:hierarchy_wp_custom_field, *traits, allow_additional_project_values: true) }
  let!(:europe) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Europe") }
  let!(:germany) { create(:hierarchy_item, parent: europe, label: "Germany") }
  let!(:berlin) { create(:hierarchy_item, parent: germany, label: "Berlin") }
  let!(:munich) { create(:hierarchy_item, parent: germany, label: "Munich") }
  let!(:france) { create(:hierarchy_item, parent: europe, label: "France") }
  let!(:asia) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Asia") }

  let(:item_service) { CustomFields::Hierarchy::HierarchicalItemService.new }
  let(:usable_values) { custom_field.reload.usable_values_in(project) }

  before { User.current = admin }

  context "with an allowlist" do
    let(:traits) { [:project_specific_allowlist] }

    context "and no values enabled in the project" do
      it "enables the whole ancestor chain when the project adds a value" do
        own_item = insert_project_item(parent: berlin, label: "Adlershof Lab", project:)

        expect(usable_values).to contain_exactly(europe, germany, berlin, own_item)
      end
    end

    context "and a value of the project below an enabled parent" do
      let!(:own_item) { create(:hierarchy_item, parent: asia, label: "Shibuya Office", project:) }

      before { restrict_items_in(project, asia) }

      it "enables the whole ancestor chain when the value is moved below a disabled parent" do
        item_service.move_item(item: own_item, new_parent: berlin).value!

        expect(usable_values).to include(europe, germany, berlin, own_item)
      end
    end

    context "and a global value with values of several projects below it" do
      let!(:own_item) { create(:hierarchy_item, parent: berlin, label: "Adlershof Lab", project:) }
      let!(:other_item) { create(:hierarchy_item, parent: berlin, label: "Kreuzberg Lab", project: other_project) }

      before do
        restrict_items_in(project, europe, germany, berlin)
        restrict_items_in(other_project, europe, germany, berlin)
      end

      it "enables the new ancestor chain in each of those projects when the global value is moved" do
        item_service.move_item(item: germany, new_parent: asia).value!

        expect(usable_values).to include(asia, germany, berlin, own_item)
        expect(custom_field.reload.usable_values_in(other_project)).to include(asia, germany, berlin, other_item)
      end
    end

    context "and a value of the project deep in the hierarchy" do
      let!(:own_item) { create(:hierarchy_item, parent: berlin, label: "Adlershof Lab", project:) }

      before { restrict_items_in(project, europe, germany, berlin) }

      it "rejects disabling an ancestor of the value on its own" do
        expect(toggle_project_value(custom_field, project:, value: germany, enabled: false, user: admin)).to be_failure
        expect(usable_values).to include(europe, germany, berlin, own_item)
      end

      it "keeps the parents enabled when the value is deleted" do
        item_service.delete_branch(item: own_item).value!

        expect(usable_values).to contain_exactly(europe, germany, berlin)
      end
    end

    context "and a value of another project" do
      before do
        create(:hierarchy_item, parent: france, label: "La Défense Office", project: other_project)
        restrict_items_in(project, europe, france)
      end

      it "allows to disable the parents of that value" do
        expect(toggle_project_value(custom_field, project:, value: france, enabled: false, user: admin)).to be_success
        expect(usable_values).not_to include(france)
      end

      it "disables the parents of that value when disabling all values" do
        expect(disable_all_project_values(custom_field, project:, user: admin)).to be_success
        expect(usable_values).to be_empty
      end
    end
  end

  context "with a blocklist" do
    let(:traits) { [:project_specific_blocklist] }

    context "and a value of the project deep in the hierarchy" do
      let!(:own_item) { create(:hierarchy_item, parent: berlin, label: "Adlershof Lab", project:) }

      it "rejects disabling an ancestor of the value on its own" do
        expect(toggle_project_value(custom_field, project:, value: germany, enabled: false, user: admin)).to be_failure
        expect(usable_values).to include(europe, germany, berlin, own_item)
      end

      it "keeps the ancestor chain enabled when disabling all values" do
        expect(disable_all_project_values(custom_field, project:, user: admin)).to be_success
        expect(usable_values).to contain_exactly(europe, germany, berlin, own_item)
      end

      it "keeps the ancestor chain enabled when switching to an allowlist" do
        expect(switch_project_value_restriction(custom_field, "allow", user: admin)).to be_success
        expect(usable_values).to contain_exactly(europe, germany, berlin, own_item)
      end
    end

    context "and a blocked parent" do
      before { restrict_items_in(project, germany) }

      it "enables the ancestor chain, but not its other values, when the project adds a value" do
        own_item = insert_project_item(parent: berlin, label: "Adlershof Lab", project:)

        expect(usable_values).to include(europe, germany, berlin, own_item)
        expect(usable_values).not_to include(munich)
      end
    end
  end

  context "without restrictions and a value of the project deep in the hierarchy" do
    let(:traits) { [] }
    let!(:own_item) { create(:hierarchy_item, parent: berlin, label: "Adlershof Lab", project:) }

    it "keeps the ancestor chain enabled when switching to an allowlist" do
      expect(switch_project_value_restriction(custom_field, "allow", user: admin)).to be_success
      expect(usable_values).to contain_exactly(europe, germany, berlin, own_item)
    end
  end
end
