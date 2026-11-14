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

RSpec.describe CustomFields::ProjectSpecificValues::MakeGlobalService,
               with_ee: %i[project_specific_list_values custom_field_hierarchies] do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  let(:traits) { [] }

  subject(:service_call) { described_class.new(user: admin, model: custom_field).call(project:, value:) }

  context "for a list custom field" do
    let(:custom_field) do
      create(:list_wp_custom_field, *traits, possible_values: %w[A], allow_additional_project_values: true)
    end
    let(:value) { custom_field.custom_options.create!(value: "Own", project:) }

    it "makes the value available to all projects" do
      expect(service_call).to be_success

      expect(value.reload.project_id).to be_nil
      expect(custom_field.usable_values_in(other_project)).to include(value)
    end

    context "when another project added a value with the same name" do
      before do
        custom_field.custom_options.create!(value: "own", project: other_project)
      end

      it "keeps the value in the project" do
        expect(service_call).to be_failure
        expect(service_call.errors.symbols_for(:value)).to include(:taken)

        expect(value.reload.project).to eq(project)
      end
    end

    context "when the value belongs to another project" do
      let(:value) { custom_field.custom_options.create!(value: "Foreign", project: other_project) }

      it "fails" do
        expect(service_call).to be_failure
        expect(value.reload.project).to eq(other_project)
      end
    end

    context "with values allowed per project" do
      let(:traits) { [:project_specific_allowlist] }

      it "keeps the value enabled in the project only" do
        expect(service_call).to be_success

        expect(custom_field.usable_values_in(project)).to include(value)
        expect(custom_field.usable_values_in(other_project)).not_to include(value)
      end
    end

    context "with values blocked per project" do
      let(:traits) { [:project_specific_blocklist] }

      it "makes the value available everywhere without restrictions" do
        expect(service_call).to be_success

        expect(custom_field.project_specific_value_restrictions).to be_empty
        expect(custom_field.usable_values_in(other_project)).to include(value)
      end
    end
  end

  context "for a hierarchy custom field" do
    let(:custom_field) { create(:hierarchy_wp_custom_field, *traits, allow_additional_project_values: true) }
    let!(:global_item) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Global") }
    let!(:own_item) { create(:hierarchy_item, parent: global_item, label: "Own", short: "OW", project:) }
    let!(:own_sub_item) { create(:hierarchy_item, parent: own_item, label: "Own sub", project:) }
    let(:value) { own_item }

    it "makes the value available to all projects and keeps its sub-values in the project" do
      expect(service_call).to be_success

      expect(own_item.reload.project_id).to be_nil
      expect(own_sub_item.reload.project).to eq(project)
    end

    context "when the parent is only available in the project" do
      let(:value) { own_sub_item }

      it "fails" do
        expect(service_call).to be_failure
        expect(service_call.errors.symbols_for(:value)).to include(:parent_only_in_project)

        expect(own_sub_item.reload.project).to eq(project)
      end
    end

    context "when another project added a sibling with the same name" do
      before do
        create(:hierarchy_item, parent: global_item, label: "own", project: other_project)
      end

      it "fails" do
        expect(service_call).to be_failure
        expect(service_call.errors.symbols_for(:value)).to include(:taken)
      end
    end

    context "when another project added a sibling with the same short name" do
      before do
        create(:hierarchy_item, parent: global_item, label: "Other", short: "ow", project: other_project)
      end

      it "fails" do
        expect(service_call).to be_failure
        expect(service_call.errors.symbols_for(:value)).to include(:taken)
      end
    end

    context "with values allowed per project" do
      let(:traits) { [:project_specific_allowlist] }

      it "keeps the value and its ancestors enabled in the project only" do
        expect(service_call).to be_success

        expect(custom_field.usable_values_in(project)).to include(global_item, own_item, own_sub_item)
        expect(custom_field.usable_values_in(other_project)).not_to include(own_item)
      end
    end
  end
end
