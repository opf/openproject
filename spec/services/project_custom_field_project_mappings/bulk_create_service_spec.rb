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
require_relative "../bulk_services/project_mappings/behaves_like_bulk_project_mapping_create_service"

RSpec.describe ProjectCustomFieldProjectMappings::BulkCreateService do
  it_behaves_like "BulkServices project mappings create service" do
    shared_let(:project_custom_field) { create(:project_custom_field) }

    let(:model) { project_custom_field }
    let(:model_mapping_class) { ProjectCustomFieldProjectMapping }
    let(:model_foreign_key_id) { :custom_field_id }
    let(:required_permission) { :select_project_custom_fields }
  end

  describe "calculated values", with_ee: %i[calculated_values] do
    using CustomFieldFormulaReferencing

    shared_let(:user) { create(:admin) }

    shared_let(:project_a) { create(:project) }
    shared_let(:project_b) { create(:project) }
    shared_let(:project_bb) { create(:project, parent: project_b) }
    shared_let(:project_c) { create(:project) }
    shared_let(:all_projects) { [project_a, project_b, project_bb, project_c] }

    shared_let(:project_custom_field_section) { create(:project_custom_field_section) }
    shared_let(:static) { create(:integer_project_custom_field, project_custom_field_section:) }
    shared_let(:calculated) do
      create(:calculated_value_project_custom_field, :skip_validations, formula: "#{static} * 7", project_custom_field_section:)
    end
    shared_let(:enabled) do
      create(:calculated_value_project_custom_field, :skip_validations, formula: "11", project_custom_field_section:)
    end
    shared_let(:disabled) do
      create(:calculated_value_project_custom_field, :skip_validations, formula: "13", project_custom_field_section:)
    end

    let(:projects) { [project_a, project_b] }
    let(:instance) { described_class.new(user:, model: custom_field, projects:, include_sub_projects:) }

    before do
      User.current = user

      all_projects.each do |project|
        create(:custom_value, custom_field: enabled, value: "11", customized: project)
      end
    end

    context "when enabling referenced static field" do
      let(:custom_field) { static }

      before do
        all_projects.each.with_index(1) do |project, i|
          # create first with blank value to skip auto enabling it
          create(:custom_value, custom_field: static, value: nil, customized: project).update_columns(value: i)

          create(:project_custom_field_project_mapping, project:, project_custom_field: calculated)
        end
      end

      context "when enabling including sub projects" do
        let(:include_sub_projects) { true }

        it "recalculates the value for enabled projects including sub projects" do
          expect(instance.call).to be_success

          expect(project_a.custom_value_attributes).to eq(static.id => "1", calculated.id => "7", enabled.id => "11")
          expect(project_b.custom_value_attributes).to eq(static.id => "2", calculated.id => "14", enabled.id => "11")
          expect(project_bb.custom_value_attributes).to eq(static.id => "3", calculated.id => "21", enabled.id => "11")
          expect(project_c.custom_value_attributes).to eq(calculated.id => nil, enabled.id => "11")
        end
      end

      context "when enabling not including sub projects" do
        let(:include_sub_projects) { false }

        it "recalculates the value for enabled projects including sub projects" do
          expect(instance.call).to be_success

          expect(project_a.custom_value_attributes).to eq(static.id => "1", calculated.id => "7", enabled.id => "11")
          expect(project_b.custom_value_attributes).to eq(static.id => "2", calculated.id => "14", enabled.id => "11")
          expect(project_bb.custom_value_attributes).to eq(calculated.id => nil, enabled.id => "11")
          expect(project_c.custom_value_attributes).to eq(calculated.id => nil, enabled.id => "11")
        end
      end
    end

    context "when enabling calculated field" do
      let(:custom_field) { calculated }

      before do
        all_projects.each.with_index(1) do |project, i|
          create(:custom_value, custom_field: static, value: i, customized: project)
        end
      end

      context "when enabling including sub projects" do
        let(:include_sub_projects) { true }

        it "recalculates the value for enabled projects including sub projects" do
          expect(instance.call).to be_success

          expect(project_a.custom_value_attributes).to eq(static.id => "1", calculated.id => "7", enabled.id => "11")
          expect(project_b.custom_value_attributes).to eq(static.id => "2", calculated.id => "14", enabled.id => "11")
          expect(project_bb.custom_value_attributes).to eq(static.id => "3", calculated.id => "21", enabled.id => "11")
          expect(project_c.custom_value_attributes).to eq(static.id => "4", enabled.id => "11")
        end
      end

      context "when enabling not including sub projects" do
        let(:include_sub_projects) { false }

        it "recalculates the value for enabled projects including sub projects" do
          expect(instance.call).to be_success

          expect(project_a.custom_value_attributes).to eq(static.id => "1", calculated.id => "7", enabled.id => "11")
          expect(project_b.custom_value_attributes).to eq(static.id => "2", calculated.id => "14", enabled.id => "11")
          expect(project_bb.custom_value_attributes).to eq(static.id => "3", enabled.id => "11")
          expect(project_c.custom_value_attributes).to eq(static.id => "4", enabled.id => "11")
        end
      end
    end
  end
end
