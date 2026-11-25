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

RSpec.describe CustomFields::ProjectSpecificValues::EnableAllService, with_ee: %i[project_specific_list_values] do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  let(:restrictions) { custom_field.project_specific_value_restrictions.where(project:) }

  subject(:service_call) { described_class.new(user: admin, model: custom_field).call(project:) }

  context "for a list custom field" do
    let(:custom_field) { create(:list_wp_custom_field, *traits, possible_values: %w[A B C]) }
    let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
    let(:option_b) { custom_field.custom_options.find_by!(value: "B") }
    let(:option_c) { custom_field.custom_options.find_by!(value: "C") }

    context "with an allowlist" do
      let(:traits) { [:project_specific_allowlist] }

      before do
        create(:project_specific_value_restriction, project:, custom_option: option_a)
        create(:project_specific_value_restriction, project: other_project, custom_option: option_b)
      end

      it "allows every option" do
        expect(service_call).to be_success

        expect(custom_field.usable_values_in(project)).to contain_exactly(option_a, option_b, option_c)
        expect(restrictions.pluck(:custom_option_id)).to contain_exactly(option_a.id, option_b.id, option_c.id)
      end

      it "leaves other projects alone" do
        service_call

        expect(custom_field.usable_values_in(other_project)).to contain_exactly(option_b)
      end
    end

    context "with a blocklist" do
      let(:traits) { [:project_specific_blocklist] }

      before do
        create(:project_specific_value_restriction, project:, custom_option: option_a)
      end

      it "removes every block" do
        expect(service_call).to be_success

        expect(custom_field.usable_values_in(project)).to contain_exactly(option_a, option_b, option_c)
        expect(restrictions).to be_empty
      end
    end

    context "without project-specific restrictions enabled" do
      let(:traits) { [] }

      it "fails" do
        expect(service_call).to be_failure
        expect(service_call.errors.symbols_for(:project_specific_value_restriction)).to eq([:blank])
      end
    end
  end

  shared_examples "enabling all hierarchical items" do |factory|
    let(:custom_field) { create(factory, *traits) }
    let!(:acme) { create(:hierarchy_item, parent: custom_field.hierarchy_root) }
    let!(:traffic_lights) { create(:hierarchy_item, parent: acme) }
    let!(:green) { create(:hierarchy_item, parent: traffic_lights) }
    let!(:oscorp) { create(:hierarchy_item, parent: custom_field.hierarchy_root) }

    context "with an allowlist" do
      let(:traits) { [:project_specific_allowlist] }

      before do
        create(:project_specific_value_restriction, project:, hierarchy_item: acme)
      end

      it "allows every item" do
        expect(service_call).to be_success

        expect(custom_field.usable_values_in(project)).to contain_exactly(acme, traffic_lights, green, oscorp)
        expect(restrictions.pluck(:hierarchy_item_id)).to contain_exactly(acme.id, traffic_lights.id, green.id, oscorp.id)
      end
    end

    context "with a blocklist" do
      let(:traits) { [:project_specific_blocklist] }

      before do
        create(:project_specific_value_restriction, project:, hierarchy_item: traffic_lights)
      end

      it "removes every block" do
        expect(service_call).to be_success

        expect(custom_field.usable_values_in(project)).to contain_exactly(acme, traffic_lights, green, oscorp)
        expect(restrictions).to be_empty
      end
    end
  end

  context "for a hierarchy custom field", with_ee: %i[custom_field_hierarchies project_specific_list_values] do
    it_behaves_like "enabling all hierarchical items", :hierarchy_wp_custom_field
  end

  context "for a weighted item list custom field", with_ee: %i[weighted_item_lists project_specific_list_values] do
    it_behaves_like "enabling all hierarchical items", :weighted_item_list_wp_custom_field
  end
end
