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

RSpec.describe CustomField::CalculatedValue, with_ee: %i[calculated_values weighted_item_lists] do
  using CustomFieldFormulaReferencing

  subject(:custom_field) { create(:calculated_value_project_custom_field, formula: "1 + 1") }

  describe ".with_formula_referencing", :aggregate_failures do
    shared_let(:cf_a) { create(:integer_project_custom_field, default_value: 1) }
    shared_let(:cf_b) { create(:integer_project_custom_field, default_value: 2) }
    shared_let(:cf_c) { create(:integer_project_custom_field, default_value: 3) }

    shared_let(:cf1) { create(:calculated_value_project_custom_field, :skip_validations, formula: "#{cf_a} + #{cf_b}") }
    shared_let(:cf2) { create(:calculated_value_project_custom_field, :skip_validations, formula: "#{cf_b} + #{cf1}") }

    let(:scope) { CustomField }

    it "finds all fields referencing given id" do
      expect(scope.with_formula_referencing(cf_a.id)).to contain_exactly(cf1)
      expect(scope.with_formula_referencing(cf_b.id)).to contain_exactly(cf1, cf2)
      expect(scope.with_formula_referencing(cf_c.id)).to be_empty
      expect(scope.with_formula_referencing(cf1.id)).to contain_exactly(cf2)
      expect(scope.with_formula_referencing(cf2.id)).to be_empty
    end

    it "finds all fields referencing given custom field" do
      expect(scope.with_formula_referencing(cf_a)).to contain_exactly(cf1)
      expect(scope.with_formula_referencing(cf_b)).to contain_exactly(cf1, cf2)
      expect(scope.with_formula_referencing(cf_c)).to be_empty
      expect(scope.with_formula_referencing(cf1)).to contain_exactly(cf2)
      expect(scope.with_formula_referencing(cf2)).to be_empty
    end
  end

  describe ".affected_calculated_fields", :aggregate_failures do
    let(:scope) { CustomField }

    context "given simple formulas" do
      shared_let(:cf_a) { create(:integer_project_custom_field, default_value: 1) }
      shared_let(:cf_b) { create(:integer_project_custom_field, default_value: 2) }
      shared_let(:cf_c) { create(:integer_project_custom_field, default_value: 3) }
      shared_let(:cf_d) { create(:integer_project_custom_field, default_value: 4) }
      shared_let(:cf1) { create(:calculated_value_project_custom_field, :skip_validations, formula: "#{cf_a} * 2") }
      shared_let(:cf2) { create(:calculated_value_project_custom_field, :skip_validations, formula: "#{cf_a} + #{cf_b}") }
      shared_let(:cf3) { create(:calculated_value_project_custom_field, :skip_validations, formula: "#{cf_b} * 2") }
      shared_let(:cf4) { create(:calculated_value_project_custom_field, :skip_validations, formula: "#{cf_c} * 2") }

      it "returns an empty array if argument is empty" do
        expect(scope.affected_calculated_fields([])).to eq([])
      end

      it "returns an empty array when passing non referenced constant field ids" do
        expect(scope.affected_calculated_fields([cf_d.id])).to eq([])
      end

      it "returns an empty array when passing non existing field id" do
        expect(scope.affected_calculated_fields([-1, -2])).to eq([])
      end

      it "returns referencing fields when passing referenced constant field ids" do
        expect(scope.affected_calculated_fields([cf_a.id])).to contain_exactly(cf1, cf2)
        expect(scope.affected_calculated_fields([cf_b.id])).to contain_exactly(cf2, cf3)
        expect(scope.affected_calculated_fields([cf_c.id])).to contain_exactly(cf4)
        expect(scope.affected_calculated_fields([cf_a.id, cf_b.id])).to contain_exactly(cf1, cf2, cf3)
        expect(scope.affected_calculated_fields([cf_a.id, cf_c.id])).to contain_exactly(cf1, cf2, cf4)
        expect(scope.affected_calculated_fields([cf_b.id, cf_c.id])).to contain_exactly(cf2, cf3, cf4)
        expect(scope.affected_calculated_fields([cf_a.id, cf_b.id, cf_c.id])).to contain_exactly(cf1, cf2, cf3, cf4)
      end

      it "returns referencing fields once when passing referenced constant field ids multiple times" do
        expect(scope.affected_calculated_fields([cf_a.id] * 5)).to contain_exactly(cf1, cf2)
        expect(scope.affected_calculated_fields([cf_a.id, cf_b.id] * 5)).to contain_exactly(cf1, cf2, cf3)
      end

      it "returns fields themselves when passing calculated field ids" do
        expect(scope.affected_calculated_fields([cf1.id])).to contain_exactly(cf1)
        expect(scope.affected_calculated_fields([cf2.id])).to contain_exactly(cf2)
        expect(scope.affected_calculated_fields([cf3.id])).to contain_exactly(cf3)
        expect(scope.affected_calculated_fields([cf4.id])).to contain_exactly(cf4)
      end

      it "returns fields once when passing mixture of calculated and constant field ids" do
        expect(scope.affected_calculated_fields([cf_a.id, cf1.id])).to contain_exactly(cf1, cf2)
      end

      context "when scope doesn't include some values" do
        let(:scope) { CustomField.where.not(id: [cf_c, cf1]) }

        it "returns referencing fields when passing referenced constant field ids if both are in scope" do
          expect(scope.affected_calculated_fields([cf_a.id])).to contain_exactly(cf2)
          expect(scope.affected_calculated_fields([cf_b.id])).to contain_exactly(cf2, cf3)
          expect(scope.affected_calculated_fields([cf_c.id])).to be_empty
          expect(scope.affected_calculated_fields([cf_a.id, cf_b.id])).to contain_exactly(cf2, cf3)
          expect(scope.affected_calculated_fields([cf_a.id, cf_c.id])).to contain_exactly(cf2)
          expect(scope.affected_calculated_fields([cf_b.id, cf_c.id])).to contain_exactly(cf2, cf3)
          expect(scope.affected_calculated_fields([cf_a.id, cf_b.id, cf_c.id])).to contain_exactly(cf2, cf3)
        end

        it "returns fields themselves if they are in scope when passing calculated field ids" do
          expect(scope.affected_calculated_fields([cf1.id])).to be_empty
          expect(scope.affected_calculated_fields([cf2.id])).to contain_exactly(cf2)
          expect(scope.affected_calculated_fields([cf3.id])).to contain_exactly(cf3)
          expect(scope.affected_calculated_fields([cf4.id])).to contain_exactly(cf4)
        end
      end
    end

    context "given formulas referencing other calculated fields" do
      shared_let(:cf_a) { create(:integer_project_custom_field, default_value: 1) }
      shared_let(:cf_b) { create(:integer_project_custom_field, default_value: 2) }
      shared_let(:cf_c) { create(:integer_project_custom_field, default_value: 3) }
      shared_let(:cf_d) { create(:integer_project_custom_field, default_value: 4) }

      shared_let(:cf1) { create(:calculated_value_project_custom_field, :skip_validations, formula: "#{cf_a} + #{cf_b}") }
      shared_let(:cf2) { create(:calculated_value_project_custom_field, :skip_validations, formula: "#{cf1} * #{cf_c}") }
      shared_let(:cf3) { create(:calculated_value_project_custom_field, :skip_validations, formula: "#{cf2} * #{cf_d}") }

      it "returns referencing fields when passing referenced constant field ids" do
        expect(scope.affected_calculated_fields([cf_a.id])).to contain_exactly(cf1, cf2, cf3)
        expect(scope.affected_calculated_fields([cf_b.id])).to contain_exactly(cf1, cf2, cf3)
        expect(scope.affected_calculated_fields([cf_c.id])).to contain_exactly(cf2, cf3)
        expect(scope.affected_calculated_fields([cf_d.id])).to contain_exactly(cf3)
      end

      it "returns fields themselves and referencing fields when passing calculated field ids" do
        expect(scope.affected_calculated_fields([cf1.id])).to contain_exactly(cf1, cf2, cf3)
        expect(scope.affected_calculated_fields([cf2.id])).to contain_exactly(cf2, cf3)
        expect(scope.affected_calculated_fields([cf3.id])).to contain_exactly(cf3)
      end

      context "when scope doesn't include some values" do
        let(:scope) { CustomField.where.not(id: cf2) }

        it "returns referencing fields when passing referenced constant field ids if whole paths are in scope" do
          expect(scope.affected_calculated_fields([cf_a.id])).to contain_exactly(cf1)
          expect(scope.affected_calculated_fields([cf_b.id])).to contain_exactly(cf1)
          expect(scope.affected_calculated_fields([cf_c.id])).to be_empty
          expect(scope.affected_calculated_fields([cf_d.id])).to contain_exactly(cf3)
          expect(scope.affected_calculated_fields([cf_a.id, cf_b.id])).to contain_exactly(cf1)
          expect(scope.affected_calculated_fields([cf_a.id, cf_c.id])).to contain_exactly(cf1)
          expect(scope.affected_calculated_fields([cf_a.id, cf_d.id])).to contain_exactly(cf1, cf3)
          expect(scope.affected_calculated_fields([cf_b.id, cf_c.id])).to contain_exactly(cf1)
          expect(scope.affected_calculated_fields([cf_b.id, cf_d.id])).to contain_exactly(cf1, cf3)
          expect(scope.affected_calculated_fields([cf_c.id, cf_d.id])).to contain_exactly(cf3)
        end

        it "returns fields themselves if they are in scope when passing calculated field ids" do
          expect(scope.affected_calculated_fields([cf1.id])).to contain_exactly(cf1)
          expect(scope.affected_calculated_fields([cf2.id])).to be_empty
          expect(scope.affected_calculated_fields([cf3.id])).to contain_exactly(cf3)
        end
      end
    end

    context "given formulas with circular references" do
      let!(:cf_a) { create(:integer_project_custom_field, default_value: 1) }
      let!(:cf_b) { create(:integer_project_custom_field, default_value: 2) }
      let!(:cf_c) { create(:integer_project_custom_field, default_value: 3) }

      let!(:cf1) { create(:calculated_value_project_custom_field) }
      let!(:cf2) { create(:calculated_value_project_custom_field) }
      let!(:cf3) { create(:calculated_value_project_custom_field) }

      before do
        {
          cf1 => "#{cf_a} + #{cf2}",
          cf2 => "#{cf_b} + #{cf3}",
          cf3 => "#{cf_c} + #{cf1}"
        }.each do |cf, formula|
          cf.formula = formula
          cf.save!(validate: false)
        end
      end

      it "does not enter infinite loop and returns all affected fields" do
        expect(scope.affected_calculated_fields([cf_a.id])).to contain_exactly(cf1, cf2, cf3)
        expect(scope.affected_calculated_fields([cf_b.id])).to contain_exactly(cf1, cf2, cf3)
        expect(scope.affected_calculated_fields([cf_c.id])).to contain_exactly(cf1, cf2, cf3)
        expect(scope.affected_calculated_fields([cf1.id])).to contain_exactly(cf1, cf2, cf3)
        expect(scope.affected_calculated_fields([cf2.id])).to contain_exactly(cf1, cf2, cf3)
        expect(scope.affected_calculated_fields([cf3.id])).to contain_exactly(cf1, cf2, cf3)
      end
    end
  end

  describe "#usable_custom_field_references_for_formula" do
    let!(:int) { create(:project_custom_field, :integer, default_value: 4, is_for_all: true) }
    let!(:float) { create(:project_custom_field, :float, default_value: 5.5, is_for_all: true) }
    let!(:weighted_item_list) { create(:project_custom_field, :weighted_item_list, is_for_all: true) }
    let!(:other_calculated_value) { create(:calculated_value_project_custom_field, formula: "2 + 2", is_for_all: true) }

    current_user { create(:admin) }

    context "with permission to see all custom fields" do
      it "returns custom fields with formats that can be used in formulas" do
        expected = [int, float, other_calculated_value, weighted_item_list]
        expect(subject.usable_custom_field_references_for_formula).to match_array(expected)
      end

      it "excludes custom field formats that are not usable in formulas" do
        text = create(:project_custom_field, :text, default_value: "txt", is_for_all: true)
        expect(subject.usable_custom_field_references_for_formula).not_to include(text)
      end

      it "excludes the current custom field from the results" do
        expect(subject.usable_custom_field_references_for_formula).not_to include(subject)
      end
    end

    context "with insufficient permission to see some custom fields" do
      let(:project_with_permission) { create(:project) }
      let(:project_without_permission) { create(:project) }
      let(:user) { create(:user, member_with_permissions: { project_with_permission => [:view_project_attributes] }) }

      let!(:int) { create(:project_custom_field, :integer, default_value: 4, projects: [project_with_permission]) }
      let!(:float) { create(:project_custom_field, :float, default_value: 5.5, projects: [project_with_permission]) }
      let!(:other_calculated_value) do
        create(:calculated_value_project_custom_field, formula: "2 + 2", projects: [project_without_permission])
      end
      let!(:weighted_item_list) do
        create(:project_custom_field, :weighted_item_list, projects: [project_without_permission])
      end

      current_user { user }

      it "returns only custom fields that the user has permission to see" do
        expect(subject.usable_custom_field_references_for_formula).to contain_exactly(int, float)
      end
    end

    context "when there are circular references" do
      let!(:field_a) { create(:calculated_value_project_custom_field, formula: "1 + 1", is_for_all: true) }
      let!(:field_b) { create(:calculated_value_project_custom_field, formula: "2 + 2", is_for_all: true) }
      let!(:field_c) { create(:calculated_value_project_custom_field, formula: "3 + 3", is_for_all: true) }

      before do
        # Set up circular reference: field_a -> field_b -> field_c -> field_a
        field_a.formula = "{{cf_#{field_b.id}}} + 1"
        field_b.formula = "{{cf_#{field_c.id}}} + 2"
        field_c.formula = "{{cf_#{field_a.id}}} + 3"

        field_a.save(validate: false)
        field_b.save(validate: false)
        field_c.save(validate: false)
      end

      it "excludes fields that would create circular references" do
        # field_a should not be able to reference field_b, field_b should not be able to reference field_c, etc.
        expect(field_a.usable_custom_field_references_for_formula).not_to include(field_b, field_c)
        expect(field_b.usable_custom_field_references_for_formula).not_to include(field_c, field_a)
        expect(field_c.usable_custom_field_references_for_formula).not_to include(field_a, field_b)
      end

      it "still includes fields that don't create circular references" do
        expect(field_a.usable_custom_field_references_for_formula).to include(int, float)
        expect(field_b.usable_custom_field_references_for_formula).to include(int, float)
        expect(field_c.usable_custom_field_references_for_formula).to include(int, float)
      end
    end

    context "when two calculated values reference the same custom field" do
      let!(:constant_cf1) { create(:project_custom_field, :integer, default_value: 1, is_for_all: true) }
      let!(:calculated_cf2) do
        create(:calculated_value_project_custom_field, formula: "{{cf_#{constant_cf1.id}}}", is_for_all: true)
      end
      let!(:calculated_cf3) do
        create(:calculated_value_project_custom_field,
               formula: "{{cf_#{constant_cf1.id}}} + {{cf_#{calculated_cf2.id}}}",
               is_for_all: true)
      end

      it "does not lead to a false positive" do
        subject.formula = "{{cf_#{calculated_cf3.id}}}"
        subject.save(validate: false)

        expect(subject.usable_custom_field_references_for_formula).to include(constant_cf1, calculated_cf2, calculated_cf3)
      end
    end

    context "when there are self-referencing fields" do
      let!(:self_referencing_field) { create(:calculated_value_project_custom_field, formula: "1 + 1", is_for_all: true) }

      before do
        self_referencing_field.formula = "{{cf_#{self_referencing_field.id}}} + 1"
        self_referencing_field.save(validate: false)
      end

      it "excludes self-referencing fields from other fields' usable references" do
        expect(subject.usable_custom_field_references_for_formula).not_to include(self_referencing_field)
      end

      it "still includes non-self-referencing fields" do
        expect(subject.usable_custom_field_references_for_formula).to include(int, float)
      end
    end
  end

  describe "#formula=" do
    let!(:int) { create(:project_custom_field, :integer, default_value: 2, is_for_all: true) }
    let!(:float) { create(:project_custom_field, :float, default_value: 3.5, is_for_all: true) }

    current_user { create(:admin) }

    it "splits formula and referenced custom fields on persist if given a string" do
      formula = "1 * {{cf_#{int.id}}} + {{cf_#{float.id}}}"
      subject.formula = formula

      expect(subject.formula).to eq({ "formula" => formula, "referenced_custom_fields" => [int.id, float.id] })
    end

    it "omits referenced custom fields if none are given" do
      formula = "2 + 3 * (8 / 7)"
      subject.formula = formula

      expect(subject.formula).to eq({ "formula" => formula, "referenced_custom_fields" => [] })
    end
  end

  describe "#formula_string" do
    it "returns an empty string if no formula is set" do
      subject.formula = nil
      expect(subject.formula_string).to eq("")
    end

    it "returns the formula as a string" do
      formula = "1 * {{cf_7}} + {{cf_42}}"
      subject.formula = formula

      expect(subject.formula_string).to eq(formula)
    end
  end

  describe "#formula_str_without_patterns" do
    it "returns an empty string if no formula is set" do
      subject.formula = nil

      expect(subject.formula_str_without_patterns).to eq("")
    end

    it "returns the formula as is if formula doesn't reference custom fields" do
      subject.formula = "2 + 2"

      expect(subject.formula_str_without_patterns).to eq("2 + 2")
    end

    it "returns ids if formula references custom fields" do
      subject.formula = "1 * {{cf_7}} + {{cf_42}}"

      expect(subject.formula_str_without_patterns).to eq("1 * cf_7 + cf_42")
    end
  end

  describe "#formula_referenced_custom_field_ids" do
    it "returns an empty array if no formula is set" do
      subject.formula = nil

      expect(subject.formula_referenced_custom_field_ids).to eq([])
    end

    it "returns an empty array if formula doesn't reference custom fields" do
      subject.formula = "2 + 2"

      expect(subject.formula_referenced_custom_field_ids).to eq([])
    end

    it "returns ids if formula references custom fields" do
      subject.formula = "1 * {{cf_7}} + {{cf_42}}"

      expect(subject.formula_referenced_custom_field_ids).to eq([7, 42])
    end
  end

  describe "#formula_references_id?" do
    let!(:int_field) { create(:project_custom_field, :integer, default_value: 10, is_for_all: true) }
    let!(:float_field) { create(:project_custom_field, :float, default_value: 5.5, is_for_all: true) }
    let!(:text_field) { create(:project_custom_field, :text, default_value: "text", is_for_all: true) }

    current_user { create(:admin) }

    context "when checking a non-calculated value custom field" do
      it "returns false for integer custom field" do
        expect(int_field.formula_references_id?(subject.id)).to be false
      end

      it "returns false for float custom field" do
        expect(float_field.formula_references_id?(subject.id)).to be false
      end

      it "returns false for text custom field" do
        expect(text_field.formula_references_id?(subject.id)).to be false
      end
    end

    context "when checking a calculated value custom field with formula but no references" do
      let!(:simple_calculated_field) do
        create(:calculated_value_project_custom_field, formula: "1 + 2", is_for_all: true)
      end

      it "returns false" do
        expect(simple_calculated_field.formula_references_id?(subject.id)).to be false
      end
    end

    context "when checking for direct circular reference" do
      let!(:self_referencing_field) do
        create(:calculated_value_project_custom_field,
               formula: "{{cf_#{int_field.id}}} + 1",
               is_for_all: true)
      end

      before do
        # Manually set the formula to reference itself
        self_referencing_field.formula = "{{cf_#{self_referencing_field.id}}} + 1"
        self_referencing_field.save(validate: false)
      end

      it "returns true when field references itself" do
        circular = self_referencing_field.formula_references_id?(self_referencing_field.id)
        expect(circular).to be true
      end
    end

    context "when checking for indirect circular reference" do
      let!(:field_a) do
        create(:calculated_value_project_custom_field,
               formula: "1 + 1",
               is_for_all: true)
      end

      let!(:field_b) do
        create(:calculated_value_project_custom_field,
               formula: "1 + 1",
               is_for_all: true)
      end

      let!(:field_c) do
        create(:calculated_value_project_custom_field,
               formula: "1 + 1",
               is_for_all: true)
      end

      before do
        # Set up the circular reference: field_a -> field_b -> field_c -> field_a
        field_a.formula = "{{cf_#{field_b.id}}} + 1"
        field_b.formula = "{{cf_#{field_c.id}}} + 2"
        field_c.formula = "{{cf_#{field_a.id}}} + 3"

        field_a.save(validate: false)
        field_b.save(validate: false)
        field_c.save(validate: false)
      end

      it "returns true when there is an indirect circular reference" do
        expect(field_a.formula_references_id?(field_a.id)).to be true
      end

      it "returns true when checking from any field in the circular chain" do
        expect(field_b.formula_references_id?(field_b.id)).to be true
        expect(field_c.formula_references_id?(field_c.id)).to be true
      end
    end

    context "when checking for no circular reference" do
      # Set up a linear chain: field_x -> field_y -> field_z (no circular reference)
      let!(:field_x) do
        create(:calculated_value_project_custom_field,
               formula: "{{cf_#{int_field.id}}} + 1",
               is_for_all: true)
      end

      let!(:field_y) do
        create(:calculated_value_project_custom_field,
               formula: "{{cf_#{field_x.id}}} + 2",
               is_for_all: true)
      end

      let!(:field_z) do
        create(:calculated_value_project_custom_field,
               formula: "{{cf_#{field_y.id}}} + 3",
               is_for_all: true)
      end

      it "returns false when there is no circular reference" do
        expect(field_x.formula_references_id?(field_x.id)).to be false
        expect(field_x.formula_references_id?(field_y.id)).to be false
        expect(field_x.formula_references_id?(field_z.id)).to be false
        expect(field_y.formula_references_id?(field_y.id)).to be false
        expect(field_z.formula_references_id?(field_z.id)).to be false
      end
    end

    context "when checking with visited nodes tracking" do
      let!(:field1) do
        create(:calculated_value_project_custom_field,
               formula: "{{cf_#{int_field.id}}} + 1",
               is_for_all: true)
      end

      let!(:field2) do
        create(:calculated_value_project_custom_field,
               formula: "{{cf_#{field1.id}}} + 2",
               is_for_all: true)
      end

      it "returns true when a node has already been visited" do
        visited = { field1.id => true }
        expect(field1.formula_references_id?(field2.id, visited)).to be true
      end

      it "returns false when checking a new node with empty visited set" do
        visited = {}
        expect(field1.formula_references_id?(field2.id, visited)).to be false
      end
    end

    context "when checking with non-existent referenced custom field" do
      let!(:field_with_invalid_ref) do
        create(:calculated_value_project_custom_field,
               formula: "1 + 1",
               is_for_all: true)
      end

      before do
        field_with_invalid_ref.formula = "{{cf_99999}} + 1"
        field_with_invalid_ref.save(validate: false)
      end

      it "returns false when referenced custom field does not exist" do
        circular = field_with_invalid_ref.formula_references_id?(field_with_invalid_ref.id)
        expect(circular).to be false
      end
    end
  end

  describe "#validate_formula" do
    shared_examples_for "valid formula" do
      it "is valid", :aggregate_failures do
        subject.formula = formula
        subject.validate_formula

        expect(subject).to be_valid
      end
    end

    shared_examples_for "invalid formula" do |error_message|
      it "is invalid", :aggregate_failures do
        subject.formula = formula
        subject.validate_formula

        expect(subject).not_to be_valid
        expect(subject.errors[:formula]).to include(error_message)
      end
    end

    let(:formula) { "" }

    context "with an empty formula" do
      it_behaves_like "invalid formula", "Formula can't be blank."
    end

    context "with a formula containing only allowed characters" do
      let(:formula) { "1 / 2 + (3 * 4.5) - 0.0" }

      it_behaves_like "valid formula"
    end

    context "with a formula using the modulo operator" do
      let(:formula) { "10 % 3" }

      it_behaves_like "valid formula"
    end

    context "with a formula calculating percentages" do
      let(:formula) { "10% * 3" }

      it_behaves_like "valid formula"
    end

    context "when omitting leading decimals before a decimal point" do
      let(:formula) { "1.5 + .0 - 3.25" }

      it_behaves_like "valid formula"
    end

    context "when omitting trailing decimals after a decimal point" do
      let(:formula) { "1.5 + 1. - 3.25" }

      it_behaves_like "invalid formula", "Formula is invalid."
    end

    context "with a formula containing forbidden characters" do
      let(:formula) { "abc + 2" }

      it_behaves_like "invalid formula",
                      "Only numeric values, mathematical operators and project attributes of type integer, float, " \
                      "calculated value and weighted list are allowed."
    end

    context "with a formula containing references to custom fields without pattern-mustaches" do
      let(:formula) { "100 * cf_3" }

      it_behaves_like "invalid formula",
                      "Only numeric values, mathematical operators and project attributes of type integer, float, " \
                      "calculated value and weighted list are allowed."
    end

    context "with a formula that is not a valid equation" do
      let(:formula) { "1 / + - 3" }

      it_behaves_like "invalid formula", "Formula is invalid."
    end

    context "with a formula that contains custom fields that are not visible to the user" do
      let(:project_with_permission) { create(:project) }
      let(:project_without_permission) { create(:project) }
      let(:user) { create(:user, member_with_permissions: { project_with_permission => [:view_project_attributes] }) }

      let!(:int) do
        create(:project_custom_field, :integer, name: "int", default_value: 4, projects: [project_without_permission])
      end
      let!(:float) do
        create(:project_custom_field, :float, name: "float", default_value: 5.5, projects: [project_without_permission])
      end
      let!(:other_calculated_value) do
        create(:calculated_value_project_custom_field, formula: "2 + 2", projects: [project_with_permission])
      end

      let(:formula) { "1 + {{cf_#{int.id}}} + {{cf_#{float.id}}} + {{cf_#{other_calculated_value.id}}}" }

      current_user { user }

      it_behaves_like "invalid formula",
                      /The attribute (int, float|float, int) cannot be used because it leads to a circular reference/
    end
  end
end
