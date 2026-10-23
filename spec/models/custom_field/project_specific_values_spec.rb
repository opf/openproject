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

RSpec.describe CustomField::ProjectSpecificValues do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  shared_examples "restricting hierarchical items" do |factory|
    let(:custom_field) { create(factory, *traits) }
    let!(:acme) { create(:hierarchy_item, parent: custom_field.hierarchy_root) }
    let!(:anvils) { create(:hierarchy_item, parent: acme) }
    let!(:traffic_lights) { create(:hierarchy_item, parent: acme) }
    let!(:green) { create(:hierarchy_item, parent: traffic_lights) }
    let!(:orange) { create(:hierarchy_item, parent: traffic_lights) }
    let!(:oscorp) { create(:hierarchy_item, parent: custom_field.hierarchy_root) }

    context "without project-specific restrictions enabled" do
      let(:traits) { [] }

      before do
        create(:project_specific_value_restriction, project:, hierarchy_item: acme, restriction: "allow")
      end

      it "returns all items below the root, ignoring leftover restrictions" do
        expect(usable_values).to contain_exactly(acme, anvils, traffic_lights, green, orange, oscorp)
      end
    end

    context "with an allowlist" do
      let(:traits) { [:project_specific_allowlist] }

      it "returns nothing while no item is allowed" do
        expect(usable_values).to be_empty
      end

      context "with allowed items" do
        before do
          create(:project_specific_value_restriction, project:, hierarchy_item: acme)
          create(:project_specific_value_restriction, project:, hierarchy_item: traffic_lights)
          create(:project_specific_value_restriction, project:, hierarchy_item: green)
          create(:project_specific_value_restriction, project: other_project, hierarchy_item: anvils)
          create(:project_specific_value_restriction, project:, hierarchy_item: oscorp, restriction: "block")
        end

        it "returns the allowed items whose ancestors are all allowed" do
          expect(usable_values).to contain_exactly(acme, traffic_lights, green)
        end
      end

      context "with an allowed item below a parent that is not allowed" do
        before do
          create(:project_specific_value_restriction, project:, hierarchy_item: acme)
          create(:project_specific_value_restriction, project:, hierarchy_item: green)
        end

        it "does not return the item" do
          expect(usable_values).to contain_exactly(acme)
        end
      end
    end

    context "with a blocklist" do
      let(:traits) { [:project_specific_blocklist] }

      it "returns all items while no item is blocked" do
        expect(usable_values).to contain_exactly(acme, anvils, traffic_lights, green, orange, oscorp)
      end

      context "with blocked items" do
        before do
          create(:project_specific_value_restriction, project:, hierarchy_item: traffic_lights)
          create(:project_specific_value_restriction, project: other_project, hierarchy_item: anvils)
          create(:project_specific_value_restriction, project:, hierarchy_item: oscorp, restriction: "allow")
        end

        it "returns all items except the blocked ones and their descendants" do
          expect(usable_values).to contain_exactly(acme, anvils, oscorp)
        end
      end
    end
  end

  describe "#usable_values_in" do
    subject(:usable_values) { custom_field.usable_values_in(project) }

    context "for a list custom field" do
      let(:custom_field) { create(:list_wp_custom_field, *traits, possible_values: %w[A B C]) }
      let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
      let(:option_b) { custom_field.custom_options.find_by!(value: "B") }
      let(:option_c) { custom_field.custom_options.find_by!(value: "C") }

      context "without project-specific restrictions enabled" do
        let(:traits) { [] }

        before do
          create(:project_specific_value_restriction, project:, custom_option: option_a, restriction: "allow")
        end

        it "returns all options, ignoring leftover restrictions" do
          expect(usable_values).to contain_exactly(option_a, option_b, option_c)
        end
      end

      context "with an allowlist" do
        let(:traits) { [:project_specific_allowlist] }

        it "returns nothing while no option is allowed" do
          expect(usable_values).to be_empty
        end

        context "with allowed options" do
          before do
            create(:project_specific_value_restriction, project:, custom_option: option_a)
            create(:project_specific_value_restriction, project: other_project, custom_option: option_b)
            create(:project_specific_value_restriction, project:, custom_option: option_c, restriction: "block")
          end

          it "returns only the options allowed in the project" do
            expect(usable_values).to contain_exactly(option_a)
          end
        end
      end

      context "with a blocklist" do
        let(:traits) { [:project_specific_blocklist] }

        it "returns all options while no option is blocked" do
          expect(usable_values).to contain_exactly(option_a, option_b, option_c)
        end

        context "with blocked options" do
          before do
            create(:project_specific_value_restriction, project:, custom_option: option_a)
            create(:project_specific_value_restriction, project: other_project, custom_option: option_b)
            create(:project_specific_value_restriction, project:, custom_option: option_c, restriction: "allow")
          end

          it "returns all options except those blocked in the project" do
            expect(usable_values).to contain_exactly(option_b, option_c)
          end
        end
      end
    end

    context "for a hierarchy custom field", with_ee: [:custom_field_hierarchies] do
      it_behaves_like "restricting hierarchical items", :hierarchy_wp_custom_field
    end

    context "for a weighted item list custom field", with_ee: [:weighted_item_lists] do
      it_behaves_like "restricting hierarchical items", :weighted_item_list_wp_custom_field
    end
  end
end
