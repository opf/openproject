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

RSpec.describe ActsAsCustomizable::CalculatedValue, with_ee: %i[calculated_values] do
  using CustomFieldFormulaReferencing
  include CalculatedValues::ErrorsHelper

  describe "#calculate_custom_fields" do
    let(:model_class) do
      Class.new do
        include ActsAsCustomizable::CalculatedValue

        def enabled_custom_field_ids = nil

        def custom_field_values(*) = nil
        attr_writer :custom_field_values
      end
    end

    let(:instance) { model_class.new }

    before do
      allow(instance).to receive(:enabled_custom_field_ids).and_return(enabled_custom_field_ids)
      allow(instance).to receive(:custom_field_values).with(all: true).and_return(custom_field_values)
      allow(instance).to receive(:custom_field_values=)
    end

    context "when calling with empty array" do
      let(:enabled_custom_field_ids) { [42] }
      let(:custom_field_values) { [:foo] }

      it "doesn't calculate anything" do
        instance.calculate_custom_fields([])

        expect(instance).not_to have_received(:custom_field_values=)
      end
    end

    context "when calling with non calculated value custom fields" do
      let(:static_custom_field) { build_stubbed(:integer_project_custom_field) }
      let(:enabled_custom_field_ids) { [static_custom_field.id] }
      let(:custom_field_values) { [:foo] }

      it "raises an exception when" do
        expect do
          instance.calculate_custom_fields([static_custom_field])
        end.to raise_error(ArgumentError, "Expected array of calculated value custom fields")
      end

      it "doesn't calculate anything" do
        begin
          instance.calculate_custom_fields([static_custom_field])
        rescue ArgumentError
          # ignore
        end

        expect(instance).not_to have_received(:custom_field_values=)
      end
    end

    describe "operations" do
      let(:by_op) do
        {
          add: build_stubbed(:calculated_value_project_custom_field, formula: "1 + 2"),
          sub: build_stubbed(:calculated_value_project_custom_field, formula: "2 - 3"),
          mul: build_stubbed(:calculated_value_project_custom_field, formula: "3 * 4"),
          div: build_stubbed(:calculated_value_project_custom_field, formula: "5 / 4"),
          mod: build_stubbed(:calculated_value_project_custom_field, formula: "6 % 5"),
          percent: build_stubbed(:calculated_value_project_custom_field, formula: "6 + 7%"),
          group: build_stubbed(:calculated_value_project_custom_field, formula: "2 * (1 + 2)")
        }
      end
      let(:custom_fields) { by_op.values }
      let(:ids) { by_op.transform_values(&:id) }

      let(:enabled_custom_field_ids) { custom_fields.map(&:id) }
      let(:custom_field_values) { [] }

      it "handles all available operations" do
        instance.calculate_custom_fields(custom_fields)

        expect(instance).to have_received(:custom_field_values=)
          .with(
            ids[:add] => 3,
            ids[:sub] => -1,
            ids[:mul] => 12,
            ids[:div] => 5/4r,
            ids[:mod] => 1,
            ids[:percent] => 607/100r,
            ids[:group] => 6
          )
      end
    end

    describe "division by zero" do
      let(:cf_div) { build_stubbed(:calculated_value_project_custom_field, formula: "5 / 0") }
      let(:cf_mod) { build_stubbed(:calculated_value_project_custom_field, formula: "5 % 0") }
      let(:cf_add) { build_stubbed(:calculated_value_project_custom_field, formula: "1 + 2") }

      let(:enabled_custom_field_ids) { [cf_div, cf_mod, cf_add].map(&:id) }
      let(:custom_field_values) { [] }

      it "blanks field with division by zero, but calculates other field" do
        instance.calculate_custom_fields([cf_div, cf_add])

        expect(instance).to have_received(:custom_field_values=)
          .with(
            cf_div.id => nil,
            cf_add.id => 3
          )
      end

      it "blanks field with modulo zero, but calculates other field" do
        instance.calculate_custom_fields([cf_mod, cf_add])

        expect(instance).to have_received(:custom_field_values=)
          .with(
            cf_mod.id => nil,
            cf_add.id => 3
          )
      end
    end

    context "when calling with custom fields referencing constant fields" do
      let(:cf_a) { build_stubbed(:integer_project_custom_field) }
      let(:cf_b) { build_stubbed(:integer_project_custom_field) }

      let(:cf1) { build_stubbed(:calculated_value_project_custom_field, formula: "#{cf_a} + #{cf_b}") }
      let(:cf2) { build_stubbed(:calculated_value_project_custom_field, formula: "#{cf_a} * #{cf_b}") }

      let(:enabled_custom_field_ids) { [cf_a, cf_b, cf1, cf2].map(&:id) }
      let(:custom_field_values) do
        {
          cf_a => 2,
          cf_b => 3
        }.map { |custom_field, value| build_stubbed(:custom_value, custom_field:, value:) }
      end

      it "calculates values for requested fields" do
        instance.calculate_custom_fields([cf1])
        expect(instance).to have_received(:custom_field_values=).with(cf1.id => 2 + 3).once

        instance.calculate_custom_fields([cf2])
        expect(instance).to have_received(:custom_field_values=).with(cf2.id => 2 * 3).once

        instance.calculate_custom_fields([cf1, cf2])
        expect(instance).to have_received(:custom_field_values=).with(cf1.id => 2 + 3, cf2.id => 2 * 3).once
      end
    end

    context "when calling with custom fields referencing other calculated fields" do
      let(:cf1) { build_stubbed(:calculated_value_project_custom_field, formula: "1 + 1") }
      let(:cf2) { build_stubbed(:calculated_value_project_custom_field, formula: "1 + 2") }
      let(:cf3) { build_stubbed(:calculated_value_project_custom_field, formula: "#{cf1} * #{cf2}") }

      let(:enabled_custom_field_ids) { [cf1, cf2, cf3].map(&:id) }
      let(:custom_field_values) do
        {
          cf1 => 5,
          cf2 => 7,
          cf3 => 9
        }.map { |custom_field, value| build_stubbed(:custom_value, custom_field:, value:) }
      end

      it "calculates only requested fields in proper order using old values for unrequested fields" do
        instance.calculate_custom_fields([cf1])
        expect(instance).to have_received(:custom_field_values=).with(cf1.id => 2).once

        instance.calculate_custom_fields([cf2])
        expect(instance).to have_received(:custom_field_values=).with(cf2.id => 3).once

        instance.calculate_custom_fields([cf3])
        expect(instance).to have_received(:custom_field_values=).with(cf3.id => 5 * 7).once

        instance.calculate_custom_fields([cf1, cf2])
        expect(instance).to have_received(:custom_field_values=).with(cf1.id => 2, cf2.id => 3).once

        instance.calculate_custom_fields([cf1, cf3])
        expect(instance).to have_received(:custom_field_values=).with(cf1.id => 2, cf3.id => 2 * 7).once

        instance.calculate_custom_fields([cf2, cf3])
        expect(instance).to have_received(:custom_field_values=).with(cf2.id => 3, cf3.id => 5 * 3).once

        instance.calculate_custom_fields([cf1, cf2, cf3])
        expect(instance).to have_received(:custom_field_values=).with(cf1.id => 2, cf2.id => 3, cf3.id => 2 * 3).once
      end
    end

    context "when calling with custom fields referencing missing or unavailable values" do
      let(:cf_missing) { build_stubbed(:integer_project_custom_field) }
      let(:cf_unavailable) { build_stubbed(:integer_project_custom_field) }

      let(:cf_using_missing) { build_stubbed(:calculated_value_project_custom_field, formula: "1 + #{cf_missing}") }
      let(:cf_using_unavailable) { build_stubbed(:calculated_value_project_custom_field, formula: "2 + #{cf_unavailable}") }
      let(:cf_other) { build_stubbed(:calculated_value_project_custom_field, formula: "1 + 2") }

      let(:enabled_custom_field_ids) { [cf_missing, cf_unavailable, cf_using_missing, cf_using_unavailable, cf_other].map(&:id) }
      let(:custom_field_values) do
        {
          cf_missing => nil
        }.map { |custom_field, value| build_stubbed(:custom_value, custom_field:, value:) }
      end

      it "blanks erroneous fields and calculates valid ones" do
        instance.calculate_custom_fields([cf_using_missing, cf_using_unavailable, cf_other])
        expect(instance).to have_received(:custom_field_values=).with(
          cf_using_missing.id => nil,
          cf_using_unavailable.id => nil,
          cf_other.id => 3
        )
      end
    end

    context "with disabled fields" do
      let(:cf_a) { build_stubbed(:integer_project_custom_field) }
      let(:cf_b) { build_stubbed(:integer_project_custom_field) }

      let(:cf1) { build_stubbed(:calculated_value_project_custom_field, formula: "#{cf_a} * 5") }
      let(:cf2) { build_stubbed(:calculated_value_project_custom_field, formula: "#{cf_b} * 7") }

      let(:custom_field_values) do
        {
          cf_a => 2,
          cf_b => 3
        }.map { |custom_field, value| build_stubbed(:custom_value, custom_field:, value:) }
      end

      context "when a referenced field is disabled" do
        let(:enabled_custom_field_ids) { [cf_b, cf1, cf2].map(&:id) }

        it "considers its value to be blank" do
          instance.calculate_custom_fields([cf1, cf2])
          expect(instance).to have_received(:custom_field_values=).with(cf1.id => nil, cf2.id => 3 * 7).once
        end
      end

      context "when a calculated field is disabled" do
        let(:enabled_custom_field_ids) { [cf_a, cf_b, cf1].map(&:id) }

        it "blanks its value" do
          instance.calculate_custom_fields([cf1, cf2])
          expect(instance).to have_received(:custom_field_values=).with(cf1.id => 2 * 5, cf2.id => nil).once
        end
      end
    end

    context "when calling with custom fields having circular reference" do
      let(:cf_a) { build_stubbed(:integer_project_custom_field) }
      let(:cf_b) { build_stubbed(:integer_project_custom_field) }
      let(:cf_c) { build_stubbed(:integer_project_custom_field) }
      let(:cf_d) { build_stubbed(:integer_project_custom_field) }

      let(:cf1) { build_stubbed(:calculated_value_project_custom_field) }
      let(:cf2) { build_stubbed(:calculated_value_project_custom_field) }
      let(:cf3) { build_stubbed(:calculated_value_project_custom_field) }
      let(:cf4) { build_stubbed(:calculated_value_project_custom_field) }

      let(:enabled_custom_field_ids) { [cf_a, cf_b, cf_c, cf_d, cf1, cf2, cf3, cf4].map(&:id) }
      let(:custom_field_values) do
        {
          cf_a => 2,
          cf_b => 3,
          cf_c => 5,
          cf_d => 7,
          cf1 => 11,
          cf2 => 13,
          cf3 => 17,
          cf4 => 19
        }.map { |custom_field, value| build_stubbed(:custom_value, custom_field:, value:) }
      end

      before do
        {
          cf1 => "#{cf_a} * #{cf2}",
          cf2 => "#{cf_b} * #{cf3}",
          cf3 => "#{cf1} * #{cf4}",
          cf4 => "#{cf_c} * #{cf_d}"
        }.each do |cf, formula|
          cf.formula = formula
        end
      end

      it "blanks them when requested to calculate fields that lead to recursion" do
        instance.calculate_custom_fields([cf1, cf2, cf3])

        expect(instance).to have_received(:custom_field_values=)
          .with(cf1.id => nil, cf2.id => nil, cf3.id => nil)
      end

      it "blanks also unrelated fields when requested to calculate fields that lead to recursion" do
        instance.calculate_custom_fields([cf1, cf2, cf3, cf4])

        expect(instance).to have_received(:custom_field_values=)
          .with(cf1.id => nil, cf2.id => nil, cf3.id => nil, cf4.id => nil)
      end

      it "calculates values when there is no recursion in fields requested to calculate (one field)" do
        instance.calculate_custom_fields([cf1])
        expect(instance).to have_received(:custom_field_values=)
          .with(cf1.id => 2 * 13).once

        instance.calculate_custom_fields([cf2])
        expect(instance).to have_received(:custom_field_values=)
          .with(cf2.id => 3 * 17).once

        instance.calculate_custom_fields([cf3])
        expect(instance).to have_received(:custom_field_values=)
          .with(cf3.id => 11 * 19).once

        instance.calculate_custom_fields([cf4])
        expect(instance).to have_received(:custom_field_values=)
          .with(cf4.id => 5 * 7).once
      end

      it "calculates values when there is no recursion in fields requested to calculate (two fields)" do
        instance.calculate_custom_fields([cf1, cf2])
        expect(instance).to have_received(:custom_field_values=)
          .with(cf1.id => 2 * 3 * 17, cf2.id => 3 * 17).once

        instance.calculate_custom_fields([cf1, cf3])
        expect(instance).to have_received(:custom_field_values=)
          .with(cf1.id => 2 * 13, cf3.id => 2 * 13 * 19).once

        instance.calculate_custom_fields([cf1, cf4])
        expect(instance).to have_received(:custom_field_values=)
          .with(cf1.id => 2 * 13, cf4.id => 5 * 7).once

        instance.calculate_custom_fields([cf2, cf3])
        expect(instance).to have_received(:custom_field_values=)
          .with(cf2.id => 3 * 11 * 19, cf3.id => 11 * 19).once

        instance.calculate_custom_fields([cf2, cf4])
        expect(instance).to have_received(:custom_field_values=)
          .with(cf2.id => 3 * 17, cf4.id => 5 * 7).once

        instance.calculate_custom_fields([cf3, cf4])
        expect(instance).to have_received(:custom_field_values=)
          .with(cf3.id => 5 * 7 * 11, cf4.id => 5 * 7).once
      end

      it "calculates values when there is no recursion in fields requested to calculate (three fields)" do
        instance.calculate_custom_fields([cf1, cf2, cf4])
        expect(instance).to have_received(:custom_field_values=)
          .with(cf1.id => 2 * 3 * 17, cf2.id => 3 * 17, cf4.id => 5 * 7).once

        instance.calculate_custom_fields([cf1, cf3, cf4])
        expect(instance).to have_received(:custom_field_values=)
          .with(cf1.id => 2 * 13, cf3.id => 2 * 5 * 7 * 13, cf4.id => 5 * 7).once

        instance.calculate_custom_fields([cf2, cf3, cf4])
        expect(instance).to have_received(:custom_field_values=)
          .with(cf2.id => 3 * 5 * 7 * 11, cf3.id => 5 * 7 * 11, cf4.id => 5 * 7).once
      end
    end

    context "when using weighted item lists" do
      let(:cf_list) { build_stubbed(:weighted_item_list_project_custom_field) }
      let(:cf1) { build_stubbed(:calculated_value_project_custom_field) }
      let(:hierarchy_item) { create(:hierarchy_item, weight: 7) }

      let(:enabled_custom_field_ids) { [cf_list, cf1].map(&:id) }
      let(:custom_field_values) do
        {
          cf_list => hierarchy_item.id
        }.map { |custom_field, value| build_stubbed(:custom_value, custom_field:, value:) }
      end

      before do
        {
          cf1 => "#{cf_list} * 2"
        }.each do |cf, formula|
          cf.formula = formula
        end
      end

      it "calculates values using the weight of the selected entry" do
        instance.calculate_custom_fields([cf1])
        expect(instance).to have_received(:custom_field_values=)
                              .with(cf1.id => 2 * 7).once
      end
    end
  end

  describe "#calculate_custom_fields error handling" do
    def expect_calculated_value_error(calc_val_cf, project, error_code, message_part = nil)
      error = calc_val_cf.first_calculation_error(project)
      expect(error&.error_code).to eq(error_code)

      if message_part
        expect(calculated_value_error_msg(error)).to include(message_part)
      end
    end

    def expect_no_calculated_value_errors(calc_val_cf, project)
      expect(calc_val_cf.first_calculation_error(project)).to be_blank
    end

    let(:project) { create(:project) }
    let(:custom_field_values) { {} }

    before do
      custom_field_values.each do |custom_field, value|
        create(:custom_value, customized: project, custom_field:, value:)
      end
    end

    describe "division by zero" do
      let(:cf_div) { create(:calculated_value_project_custom_field, projects: [project], formula: "5 / 0") }
      let(:cf_add) { create(:calculated_value_project_custom_field, projects: [project], formula: "5 + 0") }

      let(:custom_field_values) do
        { cf_div => nil, cf_add => nil }
      end

      it "creates a mathematical error for division by zero" do
        project.calculate_custom_fields([cf_div, cf_add])

        expect_no_calculated_value_errors(cf_add, project)
        expect_calculated_value_error(cf_div, project, "ERROR_MATHEMATICAL")
      end
    end

    describe "missing value" do
      let(:cf_int) { create(:integer_project_custom_field, projects: [project]) }
      let(:cv1) do
        create(:calculated_value_project_custom_field, :skip_validations, projects: [project], formula: "5 + #{cf_int}")
      end
      let(:cv2) { create(:calculated_value_project_custom_field, :skip_validations, projects: [project], formula: "5 + #{cv1}") }
      let(:cv3) { create(:calculated_value_project_custom_field, :skip_validations, projects: [project], formula: "5 + 5") }

      let(:custom_field_values) do
        { cv1 => nil, cv2 => nil, cf_int => nil, cv3 => nil }
      end

      it "creates a missing value error" do
        project.calculate_custom_fields([cv1, cv2, cv3])

        expect_no_calculated_value_errors(cv3, project)

        # Directly missing cf_int
        expect_calculated_value_error(cv1, project, "ERROR_MISSING_VALUE", cf_int.name)

        # Missing a value for cv1, which itself is missing cf_int and thus has no value
        expect_calculated_value_error(cv2, project, "ERROR_MISSING_VALUE", cv1.name)
      end
    end

    describe "disabled value" do
      let(:cf_int) { create(:integer_project_custom_field, projects: []) }
      let(:cv1) do
        create(:calculated_value_project_custom_field, :skip_validations, projects: [project], formula: "5 + #{cf_int}")
      end
      let(:cv2) { create(:calculated_value_project_custom_field, :skip_validations, projects: [project], formula: "5 + #{cv1}") }
      let(:cv3) { create(:calculated_value_project_custom_field, :skip_validations, projects: [project], formula: "5 + 5") }

      let(:custom_field_values) do
        { cv1 => nil, cv2 => nil, cv3 => nil }
      end

      it "creates a disabled value error" do
        project.calculate_custom_fields([cv1, cv2, cv3])

        expect_no_calculated_value_errors(cv3, project)

        # The referenced int field is disabled, we thus expect a `disabled` error.
        expect_calculated_value_error(cv1, project, "ERROR_DISABLED_VALUE", cf_int.name)

        # Since cv1 cannot be calculated, it leads to a missing value error in cv2.
        expect_calculated_value_error(cv2, project, "ERROR_MISSING_VALUE", cv1.name)
      end
    end

    context "with disabled calculated values" do
      let(:cf_int) { create(:integer_project_custom_field) }
      let(:formula) { "2 / #{cf_int}" }
      let(:disabled_cv) do
        create(:calculated_value_project_custom_field, :skip_validations, projects: [], formula:)
      end
      let(:enabled_cv) { create(:calculated_value_project_custom_field, :skip_validations, projects: [project], formula:) }

      let(:custom_field_values) do
        { enabled_cv => nil, cf_int => 0 }
      end

      it "only creates errors for enabled calculated values" do
        project.calculate_custom_fields([disabled_cv, enabled_cv])

        expect_calculated_value_error(enabled_cv, project, "ERROR_MATHEMATICAL")
        expect_no_calculated_value_errors(disabled_cv, project)
      end
    end

    describe "nesting multiple custom fields into one formula" do
      let(:a) { create(:integer_project_custom_field) }
      let(:b) { create(:integer_project_custom_field) }

      let(:a_plus_b_enabled) { true }
      let(:a_plus_b) do
        create(:calculated_value_project_custom_field,
               :skip_validations,
               projects: a_plus_b_enabled ? [project] : [],
               formula: "#{a} + #{b}")
      end

      let(:a_minus_b_enabled) { true }
      let(:a_minus_b) do
        create(:calculated_value_project_custom_field,
               :skip_validations,
               projects: a_minus_b_enabled ? [project] : [],
               formula: "#{a} - #{b}")
      end

      let(:nested_calculation) do
        create(:calculated_value_project_custom_field,
               :skip_validations,
               projects: [project],
               formula: "#{a_plus_b} / #{a_minus_b}")
      end

      let(:custom_field_values) do
        { a => 1, b => 2, a_plus_b => nil, a_minus_b => nil, nested_calculation => nil }
      end

      it "calculates the result correctly and does not produce an error" do
        project.calculate_custom_fields([a_plus_b, a_minus_b, nested_calculation])

        custom_values = project.custom_field_values.to_h { |cv| [cv.custom_field_id, cv.value] }
        expect(custom_values).to eq({
                                      a_plus_b.id => "3",
                                      a_minus_b.id => "-1",
                                      nested_calculation.id => "-3.0"
                                    })

        expect_no_calculated_value_errors(a_plus_b, project)
        expect_no_calculated_value_errors(a_minus_b, project)
        expect_no_calculated_value_errors(nested_calculation, project)
      end

      describe "with a_minus_b being disabled" do
        let(:a_minus_b_enabled) { false }

        let(:custom_field_values) do
          { a => 1, b => 2, a_plus_b => nil, nested_calculation => nil }
        end

        it "produces an error for the disabled field" do
          project.calculate_custom_fields([a_plus_b, a_minus_b, nested_calculation])

          expect_no_calculated_value_errors(a_plus_b, project)
          expect_calculated_value_error(nested_calculation, project, "ERROR_DISABLED_VALUE", a_minus_b.name)
        end
      end

      describe "with a_plus_b being disabled" do
        let(:a_plus_b_enabled) { false }

        let(:custom_field_values) do
          { a => 1, b => 2, a_minus_b => nil, nested_calculation => nil }
        end

        it "produces an error for the disabled field" do
          project.calculate_custom_fields([a_plus_b, a_minus_b, nested_calculation])

          expect_no_calculated_value_errors(a_minus_b, project)
          expect_calculated_value_error(nested_calculation, project, "ERROR_DISABLED_VALUE", a_plus_b.name)
        end
      end

      describe "resulting in a division by zero error" do
        let(:custom_field_values) do
          { a => 1, b => 1, a_plus_b => nil, a_minus_b => nil, nested_calculation => nil }
        end

        it "produces a mathematical error" do
          project.calculate_custom_fields([a_plus_b, a_minus_b, nested_calculation])

          expect_no_calculated_value_errors(a_plus_b, project)
          expect_no_calculated_value_errors(a_minus_b, project)
          expect_calculated_value_error(nested_calculation, project, "ERROR_MATHEMATICAL")
        end
      end
    end
  end
end
