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

  shared_examples "showing hierarchical items" do |factory|
    let(:custom_field) { create(factory, *traits, types: [type]) }
    let!(:acme) { create(:hierarchy_item, parent: custom_field.hierarchy_root) }
    let!(:traffic_lights) { create(:hierarchy_item, parent: acme) }
    let!(:green) { create(:hierarchy_item, parent: traffic_lights) }
    let!(:oscorp) { create(:hierarchy_item, parent: custom_field.hierarchy_root) }

    context "without project-specific restrictions enabled" do
      let(:traits) { [] }

      it "returns all items below the root" do
        expect(visible_values).to contain_exactly(acme, traffic_lights, green, oscorp)
      end
    end

    context "with an allowlist" do
      let(:traits) { [:project_specific_allowlist] }

      before do
        create(:project_specific_value_restriction, project: member_project, hierarchy_item: acme)
        create(:project_specific_value_restriction, project: other_member_project, hierarchy_item: traffic_lights)
        create(:project_specific_value_restriction, project: other_member_project, hierarchy_item: green)
        create(:project_specific_value_restriction, project: foreign_project, hierarchy_item: oscorp)
      end

      it "returns the items usable in one of the user's projects without combining their restrictions" do
        expect(visible_values).to contain_exactly(acme)
      end
    end

    context "with a blocklist" do
      let(:traits) { [:project_specific_blocklist] }

      before do
        create(:project_specific_value_restriction, project: member_project, hierarchy_item: acme)
        create(:project_specific_value_restriction, project: other_member_project, hierarchy_item: acme)
        create(:project_specific_value_restriction, project: other_member_project, hierarchy_item: oscorp)
      end

      it "returns the items not blocked in one of the user's projects" do
        expect(visible_values).to contain_exactly(oscorp)
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

  describe "#usable_value_counts_in" do
    shared_let(:unconfigured_project) { create(:project) }

    subject(:counts) { custom_field.usable_value_counts_in(Project.where(id: [project, other_project, unconfigured_project])) }

    context "for a list custom field with an allowlist" do
      let(:custom_field) { create(:list_wp_custom_field, :project_specific_allowlist, possible_values: %w[A B C]) }

      before do
        create(:project_specific_value_restriction, project:, custom_option: custom_field.custom_options.first)
        create(:project_specific_value_restriction, project:, custom_option: custom_field.custom_options.second)
        create(:project_specific_value_restriction, project: other_project, custom_option: custom_field.custom_options.third)
      end

      it "counts the options usable in each project" do
        expect(counts).to eq(project.id => 2, other_project.id => 1, unconfigured_project.id => 0)
      end
    end

    context "for a hierarchy custom field with an allowlist", with_ee: [:custom_field_hierarchies] do
      let(:custom_field) { create(:hierarchy_wp_custom_field, :project_specific_allowlist) }
      let!(:acme) { create(:hierarchy_item, parent: custom_field.hierarchy_root) }
      let!(:anvils) { create(:hierarchy_item, parent: acme) }

      before do
        create(:project_specific_value_restriction, project:, hierarchy_item: acme)
        create(:project_specific_value_restriction, project:, hierarchy_item: anvils)
        create(:project_specific_value_restriction, project: other_project, hierarchy_item: anvils)
      end

      it "only counts the items whose ancestors are usable as well" do
        expect(counts).to eq(project.id => 2, other_project.id => 0, unconfigured_project.id => 0)
      end
    end
  end

  describe "#visible_values_for" do
    shared_let(:type) { create(:type) }
    shared_let(:user) { create(:user) }
    shared_let(:member_project) do
      create(:project, types: [type], member_with_permissions: { user => %i[view_work_packages] })
    end
    shared_let(:other_member_project) do
      create(:project, types: [type], member_with_permissions: { user => %i[view_work_packages] })
    end
    shared_let(:foreign_project) { create(:project, types: [type]) }
    shared_let(:observed_project) do
      create(:project, types: [type], member_with_permissions: { user => %i[view_project] })
    end
    shared_let(:unconfigured_project) do
      create(:project, no_types: true, member_with_permissions: { user => %i[view_work_packages] })
    end

    subject(:visible_values) { custom_field.visible_values_for(user) }

    context "for a list custom field" do
      let(:custom_field) { create(:list_wp_custom_field, *traits, types: [type], possible_values: %w[A B C D E]) }
      let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
      let(:option_b) { custom_field.custom_options.find_by!(value: "B") }
      let(:option_c) { custom_field.custom_options.find_by!(value: "C") }
      let(:option_d) { custom_field.custom_options.find_by!(value: "D") }
      let(:option_e) { custom_field.custom_options.find_by!(value: "E") }

      context "without project-specific restrictions enabled" do
        let(:traits) { [] }

        it "returns all options" do
          expect(visible_values).to contain_exactly(option_a, option_b, option_c, option_d, option_e)
        end
      end

      context "with an allowlist" do
        let(:traits) { [:project_specific_allowlist] }

        before do
          create(:project_specific_value_restriction, project: member_project, custom_option: option_a)
          create(:project_specific_value_restriction, project: other_member_project, custom_option: option_b)
          create(:project_specific_value_restriction, project: foreign_project, custom_option: option_c)
          create(:project_specific_value_restriction, project: observed_project, custom_option: option_d)
          create(:project_specific_value_restriction, project: unconfigured_project, custom_option: option_e)
        end

        it "returns the options allowed in the projects in which the user sees the field on work packages" do
          expect(visible_values).to contain_exactly(option_a, option_b)
        end

        context "with a work package of a project the user is not a member of shared with the user" do
          before do
            create(:work_package_member,
                   entity: create(:work_package, project: foreign_project, type:),
                   user:,
                   roles: [create(:view_work_package_role)])
          end

          it "also returns the options allowed in the project of the shared work package" do
            expect(visible_values).to contain_exactly(option_a, option_b, option_c)
          end
        end

        context "for an admin" do
          let(:user) { create(:admin) }

          it "returns all options" do
            expect(visible_values).to contain_exactly(option_a, option_b, option_c, option_d, option_e)
          end
        end
      end
    end

    context "for a hierarchy custom field", with_ee: [:custom_field_hierarchies] do
      it_behaves_like "showing hierarchical items", :hierarchy_wp_custom_field
    end

    context "for a weighted item list custom field", with_ee: [:weighted_item_lists] do
      it_behaves_like "showing hierarchical items", :weighted_item_list_wp_custom_field
    end
  end
end
