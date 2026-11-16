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

RSpec.describe CustomFields::ProjectSpecificValues::SetService, with_ee: %i[project_specific_list_values] do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }

  let(:restrictions) { custom_field.project_specific_value_restrictions.where(project:) }

  subject(:service_call) { described_class.new(user: admin, model: custom_field).call(project:, value:, enabled:) }

  context "for a list custom field" do
    let(:custom_field) { create(:list_wp_custom_field, *traits, possible_values: %w[A B C]) }
    let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
    let(:option_b) { custom_field.custom_options.find_by!(value: "B") }
    let(:option_c) { custom_field.custom_options.find_by!(value: "C") }

    context "with an allowlist" do
      let(:traits) { [:project_specific_allowlist] }

      before do
        create(:project_specific_value_restriction, project:, custom_option: option_a)
      end

      context "when enabling an option" do
        let(:value) { option_b }
        let(:enabled) { true }

        it "allows the option" do
          expect(service_call).to be_success

          expect(custom_field.usable_values_in(project)).to contain_exactly(option_a, option_b)
          expect(restrictions.pluck(:custom_option_id)).to contain_exactly(option_a.id, option_b.id)
        end
      end

      context "when enabling an option that is already enabled" do
        let(:value) { option_a }
        let(:enabled) { true }

        it "keeps the restriction" do
          restriction = restrictions.first

          expect(service_call).to be_success

          expect(restrictions).to contain_exactly(restriction)
        end
      end

      context "when disabling an option" do
        let(:value) { option_a }
        let(:enabled) { false }

        it "removes the option" do
          expect(service_call).to be_success

          expect(custom_field.usable_values_in(project)).to be_empty
          expect(restrictions).to be_empty
        end
      end

      context "when enabling an option of another custom field" do
        let(:value) { create(:list_wp_custom_field).custom_options.first }
        let(:enabled) { true }

        it "fails without changing the restrictions" do
          expect(service_call).to be_failure
          expect(service_call.errors.symbols_for(:value)).to eq([:inclusion])

          expect(restrictions.pluck(:custom_option_id)).to contain_exactly(option_a.id)
        end
      end
    end

    context "with a blocklist" do
      let(:traits) { [:project_specific_blocklist] }

      before do
        create(:project_specific_value_restriction, project:, custom_option: option_a)
      end

      context "when disabling an option" do
        let(:value) { option_b }
        let(:enabled) { false }

        it "blocks the option" do
          expect(service_call).to be_success

          expect(custom_field.usable_values_in(project)).to contain_exactly(option_c)
          expect(restrictions.pluck(:custom_option_id)).to contain_exactly(option_a.id, option_b.id)
        end
      end

      context "when enabling an option" do
        let(:value) { option_a }
        let(:enabled) { true }

        it "unblocks the option" do
          expect(service_call).to be_success

          expect(custom_field.usable_values_in(project)).to contain_exactly(option_a, option_b, option_c)
          expect(restrictions).to be_empty
        end
      end
    end
  end

  shared_examples "setting hierarchical items" do |factory|
    let(:custom_field) { create(factory, *traits) }
    let!(:acme) { create(:hierarchy_item, parent: custom_field.hierarchy_root) }
    let!(:anvils) { create(:hierarchy_item, parent: acme) }
    let!(:traffic_lights) { create(:hierarchy_item, parent: acme) }
    let!(:green) { create(:hierarchy_item, parent: traffic_lights) }
    let!(:orange) { create(:hierarchy_item, parent: traffic_lights) }
    let!(:oscorp) { create(:hierarchy_item, parent: custom_field.hierarchy_root) }

    context "with an allowlist" do
      let(:traits) { [:project_specific_allowlist] }

      context "when enabling a nested item" do
        let(:value) { green }
        let(:enabled) { true }

        before do
          create(:project_specific_value_restriction, project:, hierarchy_item: oscorp, restriction: "block")
        end

        it "allows the item with all of its ancestors and removes leftover restrictions" do
          expect(service_call).to be_success

          expect(custom_field.usable_values_in(project)).to contain_exactly(acme, traffic_lights, green)
          expect(restrictions.pluck(:hierarchy_item_id)).to contain_exactly(acme.id, traffic_lights.id, green.id)
          expect(restrictions.pluck(:restriction)).to all(eq("allow"))
        end
      end

      context "when disabling an item with allowed descendants" do
        let(:value) { traffic_lights }
        let(:enabled) { false }

        before do
          create(:project_specific_value_restriction, project:, hierarchy_item: acme)
          create(:project_specific_value_restriction, project:, hierarchy_item: anvils)
          create(:project_specific_value_restriction, project:, hierarchy_item: traffic_lights)
          create(:project_specific_value_restriction, project:, hierarchy_item: green)
          create(:project_specific_value_restriction, project:, hierarchy_item: oscorp)
        end

        it "removes the item with all of its descendants" do
          expect(service_call).to be_success

          expect(custom_field.usable_values_in(project)).to contain_exactly(acme, anvils, oscorp)
          expect(restrictions.pluck(:hierarchy_item_id)).to contain_exactly(acme.id, anvils.id, oscorp.id)
        end
      end

      context "when enabling the hierarchy root" do
        let(:value) { custom_field.hierarchy_root }
        let(:enabled) { true }

        it "fails" do
          expect(service_call).to be_failure
          expect(restrictions).to be_empty
        end
      end
    end

    context "with a blocklist" do
      let(:traits) { [:project_specific_blocklist] }

      context "when disabling an item" do
        let(:value) { traffic_lights }
        let(:enabled) { false }

        it "blocks the item" do
          expect(service_call).to be_success

          expect(custom_field.usable_values_in(project)).to contain_exactly(acme, anvils, oscorp)
          expect(restrictions.pluck(:hierarchy_item_id)).to contain_exactly(traffic_lights.id)
        end
      end

      context "when disabling an item with blocked descendants" do
        let(:value) { acme }
        let(:enabled) { false }

        before do
          create(:project_specific_value_restriction, project:, hierarchy_item: traffic_lights)
        end

        it "only keeps the block of the item" do
          expect(service_call).to be_success

          expect(custom_field.usable_values_in(project)).to contain_exactly(oscorp)
          expect(restrictions.pluck(:hierarchy_item_id)).to contain_exactly(acme.id)
        end
      end

      context "when enabling an item below a blocked ancestor" do
        let(:value) { green }
        let(:enabled) { true }

        before do
          create(:project_specific_value_restriction, project:, hierarchy_item: acme)
        end

        it "unblocks the item with its ancestors and keeps their other children blocked" do
          expect(service_call).to be_success

          expect(custom_field.usable_values_in(project)).to contain_exactly(acme, traffic_lights, green, oscorp)
          expect(restrictions.pluck(:hierarchy_item_id)).to contain_exactly(anvils.id, orange.id)
        end
      end

      context "when enabling a blocked item" do
        let(:value) { acme }
        let(:enabled) { true }

        before do
          create(:project_specific_value_restriction, project:, hierarchy_item: acme)
        end

        it "unblocks the item but keeps its children blocked" do
          expect(service_call).to be_success

          expect(custom_field.usable_values_in(project)).to contain_exactly(acme, oscorp)
          expect(restrictions.pluck(:hierarchy_item_id)).to contain_exactly(anvils.id, traffic_lights.id)
        end
      end
    end
  end

  context "for a hierarchy custom field", with_ee: %i[custom_field_hierarchies project_specific_list_values] do
    it_behaves_like "setting hierarchical items", :hierarchy_wp_custom_field
  end

  context "for a weighted item list custom field", with_ee: %i[weighted_item_lists project_specific_list_values] do
    it_behaves_like "setting hierarchical items", :weighted_item_list_wp_custom_field
  end
end
