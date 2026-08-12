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

RSpec.describe ProjectCustomFieldProjectMappings::BulkUpdateService do
  shared_let(:project) { create(:project) }
  shared_let(:project_custom_field_section) { create(:project_custom_field_section) }

  let(:instance) { described_class.new(user:, project:, project_custom_field_section:) }

  describe "permissions" do
    shared_let(:visible_project_custom_field) do
      create(:project_custom_field,
             name: "Visible field",
             admin_only: false,
             project_custom_field_section:)
    end

    shared_let(:visible_required_project_custom_field) do
      create(:project_custom_field,
             name: "Visible required field",
             admin_only: false,
             is_required: true,
             project_custom_field_section:)
    end

    shared_let(:visible_activated_project_custom_field) do
      create(:project_custom_field,
             name: "Visible activated field",
             admin_only: false,
             is_for_all: true,
             project_custom_field_section:)
    end

    shared_let(:invisible_project_custom_field) do
      create(:project_custom_field,
             name: "Admin only field",
             admin_only: true,
             project_custom_field_section:)
    end

    context "with admin permissions" do
      let(:user) { create(:admin) }

      it "bulk enables/disables all (non-for_all) fields of the section, including invisible ones" do
        expect(project.project_custom_fields).to contain_exactly(visible_activated_project_custom_field)

        expect(instance.call(action: :enable)).to be_success

        expected = [
          visible_activated_project_custom_field,
          visible_required_project_custom_field,
          visible_project_custom_field,
          invisible_project_custom_field
        ]
        expect(project.reload.project_custom_fields).to match_array(expected)

        expect(instance.call(action: :disable)).to be_success

        # for_all fields cannot be disabled, even not by admins
        expect(project.reload.project_custom_fields).to contain_exactly(visible_activated_project_custom_field)
      end
    end

    context "with non-admin but sufficient permissions" do
      let(:user) do
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

      it "bulk enables/disables all fields of the section, excluding invisible ones" do
        expect(project.project_custom_fields).to contain_exactly(visible_activated_project_custom_field)

        expect(instance.call(action: :enable)).to be_success

        expected = [
          visible_activated_project_custom_field,
          visible_required_project_custom_field,
          visible_project_custom_field
        ]
        expect(project.reload.project_custom_fields).to match_array(expected)

        project.project_custom_fields << invisible_project_custom_field

        expect(instance.call(action: :disable)).to be_success

        # force-activated fields cannot be disabled, invisible fields are not affected by non-admins
        expected = [
          visible_activated_project_custom_field,
          invisible_project_custom_field
        ]
        expect(project.reload.project_custom_fields).to match_array(expected)
      end
    end

    context "with insufficient permissions" do
      let(:user) do
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

      it "cannot bulk enable/disable project custom fields" do
        expect(project.project_custom_fields).to contain_exactly(visible_activated_project_custom_field)

        expect(instance.call(action: :enable)).to be_failure

        expect(project.reload.project_custom_fields).to contain_exactly(visible_activated_project_custom_field)

        expect(instance.call(action: :disable)).to be_failure
      end
    end
  end

  describe "project creation wizard fields" do
    shared_let(:visible_user_project_custom_field) do
      create(:user_project_custom_field,
             name: "User field",
             admin_only: false,
             project_custom_field_section:)
    end

    before do
      project.project_creation_wizard_enabled = true
      project.save!
    end

    shared_let(:user) { create(:admin) }

    it "disables fields not configured for project creation wizard" do
      project.project_custom_fields << visible_user_project_custom_field
      expect(project.project_custom_fields).to contain_exactly(visible_user_project_custom_field)

      expect(instance.call(action: :disable)).to be_success

      expect(project.reload.project_custom_fields).to be_empty
    end

    it "does not disable fields configured for project creation wizard" do
      project.project_custom_fields << visible_user_project_custom_field
      expect(project.project_custom_fields).to contain_exactly(visible_user_project_custom_field)

      project.project_creation_wizard_assignee_custom_field_id = visible_user_project_custom_field.id

      expect(instance.call(action: :disable)).to be_success

      expect(project.reload.project_custom_fields).to contain_exactly(visible_user_project_custom_field)
    end
  end

  describe "calculated values", with_ee: %i[calculated_values] do
    using CustomFieldFormulaReferencing

    shared_let(:user) { create(:admin) }

    shared_let(:other_section) { create(:project_custom_field_section) }

    shared_let(:static) { create(:integer_project_custom_field, project_custom_field_section:) }
    shared_let(:other_static) { create(:integer_project_custom_field, project_custom_field_section: other_section) }

    shared_let(:calculated1) do
      create(:calculated_value_project_custom_field, :skip_validations, formula: "#{static} * 7",
                                                                        project_custom_field_section:)
    end
    shared_let(:calculated2) do
      create(:calculated_value_project_custom_field, :skip_validations, formula: "#{other_static} * 11",
                                                                        project_custom_field_section:)
    end
    shared_let(:other_calculated) do
      create(:calculated_value_project_custom_field, :skip_validations, formula: "#{static} * 13",
                                                                        project_custom_field_section: other_section)
    end
    shared_let(:other_enabled) do
      create(:calculated_value_project_custom_field, :skip_validations, formula: "11",
                                                                        project_custom_field_section: other_section)
    end
    shared_let(:other_disabled) do
      create(:calculated_value_project_custom_field, :skip_validations, formula: "13",
                                                                        project_custom_field_section: other_section)
    end

    before do
      # this will auto enable custom fields for the project
      {
        static => 2,
        other_static => 3,
        other_enabled => 11
      }.each { |custom_field, value| create(:custom_value, custom_field:, value:, customized: project) }

      project.project_custom_fields = [other_static, other_calculated]
    end

    it "recalculates values" do
      expect(instance.call(action: :enable)).to be_success

      project.reload
      expect(project.project_custom_fields).to contain_exactly(static, other_static, calculated1, calculated2, other_calculated)
      expect(project.custom_value_attributes(all: true)).to eq({
                                                                 static.id => "2",
                                                                 other_static.id => "3",
                                                                 calculated1.id => "14",
                                                                 calculated2.id => "33",
                                                                 other_calculated.id => "26",
                                                                 other_enabled.id => "11",
                                                                 other_disabled.id => nil
                                                               })

      expect(instance.call(action: :disable)).to be_success

      project.reload
      expect(project.project_custom_fields).to contain_exactly(other_static, other_calculated)
      expect(project.custom_value_attributes(all: true)).to eq({
                                                                 static.id => "2",
                                                                 other_static.id => "3",
                                                                 calculated1.id => nil,
                                                                 calculated2.id => nil,
                                                                 other_calculated.id => nil,
                                                                 other_enabled.id => "11",
                                                                 other_disabled.id => nil
                                                               })
    end
  end
end
