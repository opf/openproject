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

RSpec.describe ProjectCustomFieldProjectMappings::ToggleService do
  shared_let(:project) { create(:project) }
  shared_let(:project_custom_field_section) { create(:project_custom_field_section) }

  let(:instance) { described_class.new(user:) }

  describe "permissions" do
    shared_let(:visible_custom_field) do
      create(:project_custom_field,
             name: "Visible field",
             admin_only: false,
             project_custom_field_section:)
    end

    shared_let(:required_custom_field) do
      create(:project_custom_field,
             name: "Required field",
             admin_only: false,
             is_required: true,
             project_custom_field_section:)
    end

    shared_let(:forced_active_custom_field) do
      create(:project_custom_field,
             name: "Visible forced-active field",
             admin_only: false,
             is_for_all: true,
             project_custom_field_section:)
    end

    shared_let(:invisible_custom_field) do
      create(:project_custom_field,
             name: "Admin only field",
             admin_only: true,
             project_custom_field_section:)
    end

    let(:visible_custom_field_params) { { project_id: project.id, custom_field_id: visible_custom_field.id } }
    let(:required_custom_field_params) { { project_id: project.id, custom_field_id: required_custom_field.id } }
    let(:forced_active_custom_field_params) { { project_id: project.id, custom_field_id: forced_active_custom_field.id } }
    let(:invisible_custom_field_params) { { project_id: project.id, custom_field_id: invisible_custom_field.id } }

    context "with admin permissions" do
      shared_let(:user) { create(:admin) }

      it "toggles visible, non-is_for_all fields" do
        expect(project.project_custom_fields).to contain_exactly(forced_active_custom_field)

        2.times do
          expect(instance.call(**visible_custom_field_params, value: "1")).to be_success

          expected = [forced_active_custom_field, visible_custom_field]
          expect(project.reload.project_custom_fields).to match_array(expected)
        end

        2.times do
          expect(instance.call(**visible_custom_field_params, value: "0")).to be_success

          expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)
        end
      end

      it "toggles invisible, non-is_for_all fields" do
        expect(project.project_custom_fields).to contain_exactly(forced_active_custom_field)

        2.times do
          expect(instance.call(**invisible_custom_field_params, value: "1")).to be_success

          expected = [forced_active_custom_field, invisible_custom_field]
          expect(project.reload.project_custom_fields).to match_array(expected)
        end

        2.times do
          expect(instance.call(**invisible_custom_field_params, value: "0")).to be_success

          expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)
        end
      end

      it "does not toggle is_for_all fields" do
        expect(project.project_custom_fields).to contain_exactly(forced_active_custom_field)

        expect(instance.call(**forced_active_custom_field_params, value: "1")).to be_failure

        expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)

        expect(instance.call(**forced_active_custom_field_params, value: "0")).to be_failure

        expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)
      end

      it "does toggle required fields" do
        expect(project.project_custom_fields).to contain_exactly(forced_active_custom_field)

        2.times do
          expect(instance.call(**required_custom_field_params, value: "1")).to be_success

          expected = [forced_active_custom_field, required_custom_field]
          expect(project.reload.project_custom_fields).to match_array(expected)
        end

        2.times do
          expect(instance.call(**required_custom_field_params, value: "0")).to be_success

          expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)
        end
      end
    end

    context "with non-admin but sufficient permissions" do
      shared_let(:user) do
        create(:user,
               firstname: "Project",
               lastname: "Admin",
               member_with_permissions: {
                 project => %w[
                   view_work_packages
                   edit_project
                   select_project_custom_fields
                 ]
               })
      end

      it "toggles visible, non-is_for_all fields" do
        expect(project.project_custom_fields).to contain_exactly(forced_active_custom_field)

        2.times do
          expect(instance.call(**visible_custom_field_params, value: "1")).to be_success

          expected = [forced_active_custom_field, visible_custom_field]
          expect(project.reload.project_custom_fields).to match_array(expected)
        end

        2.times do
          expect(instance.call(**visible_custom_field_params, value: "0")).to be_success

          expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)
        end
      end

      it "does not toggle invisible, non-required fields" do
        expect(project.project_custom_fields).to contain_exactly(forced_active_custom_field)

        expect(instance.call(**invisible_custom_field_params, value: "1")).to be_failure

        expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)

        expect(instance.call(**invisible_custom_field_params, value: "0")).to be_failure

        expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)
      end

      it "does not toggle is_for_all fields" do
        expect(project.project_custom_fields).to contain_exactly(forced_active_custom_field)

        expect(instance.call(**forced_active_custom_field_params, value: "1")).to be_failure

        expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)

        expect(instance.call(**forced_active_custom_field_params, value: "0")).to be_failure

        expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)
      end
    end

    context "with insufficient permissions" do
      shared_let(:user) do
        create(:user,
               firstname: "Project",
               lastname: "Editor",
               member_with_permissions: {
                 project => %w[
                   view_work_packages
                   edit_project
                 ]
               })
      end

      it "does not toggle visible, non-is_for_all fields" do
        expect(project.project_custom_fields).to contain_exactly(forced_active_custom_field)

        expect(instance.call(**visible_custom_field_params, value: "1")).to be_failure

        expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)

        expect(instance.call(**visible_custom_field_params, value: "0")).to be_failure

        expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)
      end

      it "does not toggle invisible, non-is_for_all fields" do
        expect(project.project_custom_fields).to contain_exactly(forced_active_custom_field)

        expect(instance.call(**invisible_custom_field_params, value: "1")).to be_failure

        expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)

        expect(instance.call(**invisible_custom_field_params, value: "0")).to be_failure

        expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)
      end

      it "does not toggle is_for_all fields" do
        expect(project.project_custom_fields).to contain_exactly(forced_active_custom_field)

        expect(instance.call(**forced_active_custom_field_params, value: "1")).to be_failure

        expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)

        expect(instance.call(**forced_active_custom_field_params, value: "0")).to be_failure

        expect(project.reload.project_custom_fields).to contain_exactly(forced_active_custom_field)
      end
    end
  end

  describe "calculated values", with_ee: %i[calculated_values] do
    using CustomFieldFormulaReferencing

    shared_let(:user) { create(:admin) }

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

    let(:with_calculated) { { static.id => "2", calculated.id => "14", enabled.id => "11", disabled.id => nil } }
    let(:without_calculated) { { static.id => "2", calculated.id => nil, enabled.id => "11", disabled.id => nil } }

    before do
      # this will auto enable custom fields for the project
      {
        static => 2,
        enabled => 11
      }.each { |custom_field, value| create(:custom_value, custom_field:, value:, customized: project) }
    end

    context "when toggling referenced static field" do
      let(:custom_field_id) { static.id }

      context "when referencing calculated field is enabled" do
        before do
          project.project_custom_fields = [calculated, enabled]
        end

        it "recalculates the value" do
          expect(instance.call(project_id: project.id, custom_field_id:, value: "1")).to be_success

          project.reload
          expect(project.project_custom_fields).to contain_exactly(calculated, enabled, static)
          expect(project.custom_value_attributes(all: true)).to eq(with_calculated)

          expect(instance.call(project_id: project.id, custom_field_id:, value: "0")).to be_success

          project.reload
          expect(project.project_custom_fields).to contain_exactly(calculated, enabled)
          expect(project.custom_value_attributes(all: true)).to eq(without_calculated)
        end
      end

      context "when referencing calculated field is disabled" do
        before do
          project.project_custom_fields = [enabled]
        end

        it "doesn't recalculate the value" do
          expect(instance.call(project_id: project.id, custom_field_id:, value: "1")).to be_success

          project.reload
          expect(project.project_custom_fields).to contain_exactly(enabled, static)
          expect(project.custom_value_attributes(all: true)).to eq(without_calculated)

          expect(instance.call(project_id: project.id, custom_field_id:, value: "0")).to be_success

          project.reload
          expect(project.project_custom_fields).to contain_exactly(enabled)
          expect(project.custom_value_attributes(all: true)).to eq(without_calculated)
        end
      end
    end

    context "when toggling calculated field" do
      let(:custom_field_id) { calculated.id }

      context "when referenced static field is enabled" do
        before do
          project.project_custom_fields = [static, enabled]
        end

        it "recalculates the value" do
          expect(instance.call(project_id: project.id, custom_field_id:, value: "1")).to be_success

          project.reload
          expect(project.project_custom_fields).to contain_exactly(static, enabled, calculated)
          expect(project.custom_value_attributes(all: true)).to eq(with_calculated)

          expect(instance.call(project_id: project.id, custom_field_id:, value: "0")).to be_success

          project.reload
          expect(project.project_custom_fields).to contain_exactly(static, enabled)
          expect(project.custom_value_attributes(all: true)).to eq(without_calculated)
        end
      end

      context "when referenced static field is disabled" do
        before do
          project.project_custom_fields = [enabled]
        end

        it "doesn't recalculate the value" do
          expect(instance.call(project_id: project.id, custom_field_id:, value: "1")).to be_success

          project.reload
          expect(project.project_custom_fields).to contain_exactly(enabled, calculated)
          expect(project.custom_value_attributes(all: true)).to eq(without_calculated)

          expect(instance.call(project_id: project.id, custom_field_id:, value: "0")).to be_success

          project.reload
          expect(project.project_custom_fields).to contain_exactly(enabled)
          expect(project.custom_value_attributes(all: true)).to eq(without_calculated)
        end
      end
    end
  end
end
