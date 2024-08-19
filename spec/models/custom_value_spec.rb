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

RSpec.describe CustomValue do
  shared_let(:version) { create(:version) }

  let(:format) { "bool" }
  let(:custom_field) { create(:version_custom_field, field_format: format) }
  let(:custom_value) { create(:custom_value, custom_field:, value:, customized: version) }

  describe "#typed_value" do
    subject { custom_value }

    before do
      # we are testing roundtrips through the database here
      # the databases might choose to store values in weird and unexpected formats (e.g. booleans)
      subject.reload
    end

    describe "boolean custom value" do
      let(:format) { "bool" }
      let(:value) { true }

      context "when it is true" do
        it { expect(subject.typed_value).to eql(value) }
      end

      context "when it is false" do
        let(:value) { false }

        it { expect(subject.typed_value).to eql(value) }
      end

      context "when it is nil" do
        let(:value) { nil }

        it { expect(subject.typed_value).to eql(value) }
      end
    end

    describe "string custom value" do
      let(:format) { "string" }
      let(:value) { "This is a string!" }

      it { expect(subject.typed_value).to eql(value) }
    end

    describe "integer custom value" do
      let(:format) { "int" }
      let(:value) { 123 }

      it { expect(subject.typed_value).to eql(value) }
    end

    describe "float custom value" do
      let(:format) { "float" }
      let(:value) { 3.147 }

      it { expect(subject.typed_value).to eql(value) }
    end

    describe "date custom value" do
      let(:format) { "date" }
      let(:value) { Date.new(2016, 12, 1) }

      it { expect(subject.typed_value).to eql(value) }

      context "for a date format", with_settings: { date_format: "%Y/%m/%d" } do
        it { expect(subject.formatted_value).to eq("2016/12/01") }
      end
    end
  end

  describe "#default?" do
    shared_let(:project) { create(:project) }

    before do
      allow(User).to receive(:current).and_return build_stubbed(:admin)
    end

    RSpec::Matchers.define_negated_matcher :not_be_default, :be_default

    shared_examples "returns true for generated custom value" do
      describe "for a generated custom value" do
        it "returns true" do
          custom_values = project.custom_field_values

          expect(custom_values.count).to eq(1)
          expect(custom_values).to all(be_default)
        end
      end
    end

    shared_examples "returns false for custom value with value" do |value:|
      describe "for a custom value with #{value.inspect} value" do
        it "returns false" do
          project.send(custom_field.attribute_setter, value)
          custom_value = project.custom_values.last

          expect(custom_value).to not_be_default
        end
      end
    end

    context "for a boolean custom field without default value" do
      shared_let(:custom_field) { create(:project_custom_field, :boolean, projects: [project]) }

      include_examples "returns true for generated custom value"
      include_examples "returns false for custom value with value", value: false
      include_examples "returns false for custom value with value", value: true
    end

    context "for a boolean custom field with default value" do
      describe "for a generated custom value" do
        it "returns true" do
          create(:project_custom_field, :boolean, default_value: true)
          create(:project_custom_field, :boolean, default_value: false)
          # the admin interface saves default value as "1" (checked) or "0" (unchecked)
          create(:project_custom_field, :boolean, default_value: "1")
          create(:project_custom_field, :boolean, default_value: "0")

          custom_values = project.custom_field_values

          expect(custom_values).to all(be_default)
        end
      end
    end

    context "for a string custom field without default value" do
      shared_let(:custom_field) { create(:project_custom_field, :string, projects: [project]) }

      include_examples "returns true for generated custom value"
      include_examples "returns false for custom value with value", value: "Hello world!"
    end

    context "for a string custom field with default value" do
      describe "for a generated custom value" do
        it "returns true" do
          create(:project_custom_field, :string, default_value: "Hello world!", projects: [project])
          create(:project_custom_field, :string, default_value: "", projects: [project])

          custom_values = project.custom_field_values

          expect(custom_values).to all(be_default)
        end
      end
    end

    context "for a text custom field without default value" do
      shared_let(:custom_field) { create(:project_custom_field, :text, projects: [project]) }

      include_examples "returns true for generated custom value"
      include_examples "returns false for custom value with value", value: "Hello world!"
      include_examples "returns false for custom value with value", value: "Hello world!\nHello world!\nHello world!"
    end

    context "for a text custom field with default value" do
      describe "for a generated custom value" do
        it "returns true" do
          create(:project_custom_field, :text, default_value: "Hello world!", projects: [project])
          create(:project_custom_field, :text, default_value: "", projects: [project])

          custom_values = project.custom_field_values

          expect(custom_values).to all(be_default)
        end
      end
    end

    context "for an integer custom field without default value" do
      shared_let(:custom_field) { create(:project_custom_field, :integer, projects: [project]) }

      include_examples "returns true for generated custom value"
      include_examples "returns false for custom value with value", value: 123
      include_examples "returns false for custom value with value", value: 0
      include_examples "returns false for custom value with value", value: -12
    end

    context "for an integer custom field with default value" do
      describe "for a generated custom value" do
        it "returns true" do
          create(:project_custom_field, :integer, default_value: 0, projects: [project])
          create(:project_custom_field, :integer, default_value: 123, projects: [project])
          create(:project_custom_field, :integer, default_value: "456", projects: [project])
          create(:project_custom_field, :integer, default_value: -987, projects: [project])
          create(:project_custom_field, :integer, default_value: "-678", projects: [project])

          custom_values = project.custom_field_values

          expect(custom_values).to all(be_default)
        end
      end
    end

    context "for a float custom field without default value" do
      shared_let(:custom_field) { create(:project_custom_field, :float, projects: [project]) }

      include_examples "returns true for generated custom value"
      include_examples "returns false for custom value with value", value: 3.14
      include_examples "returns false for custom value with value", value: 0
      include_examples "returns false for custom value with value", value: -12
    end

    context "for a float custom field with default value" do
      describe "for a generated custom value" do
        it "returns true" do
          create(:project_custom_field, :float, default_value: 0.0, projects: [project])
          create(:project_custom_field, :float, default_value: 12.3, projects: [project])
          create(:project_custom_field, :float, default_value: "45.6", projects: [project])
          create(:project_custom_field, :float, default_value: -98.7, projects: [project])
          create(:project_custom_field, :float, default_value: "-67", projects: [project])

          custom_values = project.custom_field_values

          expect(custom_values).to all(be_default)
        end
      end
    end

    context "for a date custom field" do
      shared_let(:custom_field) { create(:project_custom_field, :date, projects: [project]) }

      include_examples "returns true for generated custom value"
      include_examples "returns false for custom value with value", value: "2023-08-08"
      include_examples "returns false for custom value with value", value: Date.current
    end

    context "for a list custom field without default value" do
      shared_let(:custom_field) { create(:project_custom_field, :list, projects: [project]) }

      include_examples "returns true for generated custom value"

      describe "for a custom value with option 'B' selected" do
        it "returns false" do
          project.send(custom_field.attribute_setter, custom_field.value_of("B"))
          custom_value = project.custom_values.last

          expect(custom_value).to not_be_default
        end
      end
    end

    context "for a list custom field with default value" do
      describe "for a generated custom value" do
        it "returns true" do
          create(:project_custom_field, :list, default_option: "B", projects: [project])

          custom_values = project.custom_field_values

          expect(custom_values.count).to eq(ProjectCustomField.count)
          expect(custom_values).to all(be_default)
        end
      end
    end

    context "for a multi-value list custom field without default value" do
      shared_let(:custom_field) { create(:project_custom_field, :multi_list, projects: [project]) }

      include_examples "returns true for generated custom value"

      describe "for a custom value with option 'B' and 'D' selected" do
        it "returns false" do
          project.send(custom_field.attribute_setter, [custom_field.value_of("B"), custom_field.value_of("D")])
          project.save!

          expect(project.custom_values).to all(not_be_default)
        end
      end
    end

    context "for a multi-value list custom field with default value" do
      describe "for a generated custom value" do
        it "returns true" do
          create(:project_custom_field, :multi_list, default_options: ["B"], projects: [project])
          create(:project_custom_field, :multi_list, default_options: ["G", "B", "C"], projects: [project])

          custom_values = project.custom_field_values

          # 1 CustomValue for each of the default options
          expect(custom_values.count).to eq(4)
          expect(custom_values).to all(be_default)
        end
      end
    end

    context "for a version custom field" do
      shared_let(:custom_field) { create(:project_custom_field, :version, projects: [project]) }

      include_examples "returns true for generated custom value"

      describe "for a custom value with a version selected" do
        let!(:version_turfu) { create(:version, name: "turfu", project:) }

        it "returns false" do
          project.send(custom_field.attribute_setter, version_turfu.id)
          project.save!
          custom_value = project.custom_values.last

          expect(custom_value).to not_be_default
        end
      end
    end

    context "for a multi version custom field" do
      shared_let(:custom_field) { create(:project_custom_field, :multi_version, projects: [project]) }

      include_examples "returns true for generated custom value"

      describe "for a custom value with multiple versions selected" do
        let!(:version_ringbo) { create(:version, name: "ringbo", project:) }
        let!(:version_turfu) { create(:version, name: "turfu", project:) }

        it "returns false" do
          project.send(custom_field.attribute_setter, [version_ringbo.id, version_turfu.id])
          project.save!

          expect(project.custom_values).to all(not_be_default)
        end
      end
    end

    context "for a user custom field" do
      shared_let(:custom_field) { create(:project_custom_field, :user, projects: [project]) }

      include_examples "returns true for generated custom value"

      describe "for a custom value with a user selected" do
        let!(:alice) do
          create(:user, firstname: "Alice", member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
        end

        it "returns false" do
          project.send(custom_field.attribute_setter, alice.id)
          project.save!
          custom_value = project.custom_values.last

          expect(custom_value).to not_be_default
        end
      end
    end

    context "for a multi user custom field" do
      shared_let(:custom_field) { create(:project_custom_field, :multi_user, projects: [project]) }

      include_examples "returns true for generated custom value"

      describe "for a custom value with multiple users selected" do
        let!(:alice) do
          create(:user, firstname: "Alice", member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
        end
        let!(:bob) do
          create(:user, firstname: "Bob", member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
        end

        it "returns false" do
          project.send(custom_field.attribute_setter, [alice.id, bob.id])
          project.save!

          expect(project.custom_values).to all(not_be_default)
        end
      end
    end
  end

  describe "trying to use a custom field that does not exist" do
    subject { build(:custom_value, custom_field_id: 123412341, value: "my value") }

    it "returns an empty placeholder" do
      expect(subject.custom_field).to be_nil
      expect(subject.send(:strategy)).to be_a CustomValue::EmptyStrategy
      expect(subject.typed_value).to eq "my value not found"
      expect(subject.formatted_value).to eq "my value not found"
    end
  end

  describe "#valid?" do
    let(:custom_field) do
      build_stubbed(:custom_field, field_format:, is_required:, min_length:, max_length:, regexp:)
    end
    let(:custom_value) { described_class.new(custom_field:, value:) }
    let(:is_required) { false }
    let(:min_length) { 0 }
    let(:max_length) { 0 }
    let(:regexp) { nil }

    context "for a data custom field" do
      let(:field_format) { "date" }

      context "with a valid date" do
        let(:value) { "1975-07-14" }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with some non date string" do
        let(:value) { "abc" }

        it "is invalid" do
          expect(custom_value)
            .not_to be_valid
        end
      end
    end

    context "for a string custom field" do
      let(:field_format) { "string" }

      context "with some string" do
        let(:value) { "abc" }

        it "is invalid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with a nil value" do
        let(:value) { nil }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with an empty value" do
        let(:value) { "" }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with a nil value when required" do
        let(:value) { nil }
        let(:is_required) { true }

        it "is invalid" do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context "with an empty value when required" do
        let(:value) { "" }
        let(:is_required) { true }

        it "is invalid" do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context "with an empty value when having a min_length" do
        let(:value) { "" }
        let(:min_length) { 1 }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with too short a value when having a min_length" do
        let(:value) { "a" }
        let(:min_length) { 2 }

        it "is invalid" do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context "with too long a value when having a max_length" do
        let(:value) { "a" * 6 }
        let(:max_length) { 5 }

        it "is invalid" do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context "with a value of the correct length when having a max_length and a min_value" do
        let(:value) { "a" * 4 }
        let(:min_length) { 4 }
        let(:max_length) { 4 }

        it "is invalid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with an empty value when having a regexp" do
        let(:value) { "" }
        let(:regexp) { "^[A-Z0-9]*$" }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with a not matching value when having a regexp" do
        let(:value) { "a" }
        let(:regexp) { "^[A-Z0-9]*$" }

        it "is invalid" do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context "with a matching value when having a regexp" do
        let(:value) { "A" }
        let(:regexp) { "^[A-Z0-9]*$" }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end
    end

    context "for a list custom field" do
      let(:custom_option1) { build_stubbed(:custom_option, value: "value1") }
      let(:custom_option2) { build_stubbed(:custom_option, value: "value1") }
      let(:custom_field) do
        build_stubbed(:custom_field, field_format: "list", custom_options: [custom_option1, custom_option2])
      end

      context "with a value from the list" do
        let(:value) { custom_option1.id }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with some string" do
        let(:value) { "abc" }

        it "is invalid" do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context "with nil string" do
        let(:value) { nil }

        it "is invalid" do
          expect(custom_value)
            .to be_valid
        end
      end
    end

    context "for an int custom field" do
      let(:field_format) { "int" }

      context "with a valid int string" do
        let(:value) { "123" }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with a valid negative int string" do
        let(:value) { "-123" }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with a valid positive int string" do
        let(:value) { "+123" }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with some non int string" do
        let(:value) { "abc" }

        it "is invalid" do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context "with a float string" do
        let(:value) { "5.5" }

        it "is invalid" do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context "with an empty string" do
        let(:value) { "" }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end
    end

    context "for a float custom field" do
      let(:field_format) { "float" }

      context "with a valid float string" do
        let(:value) { "123.5" }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with a valid negative float string" do
        let(:value) { "-123.5" }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with a valid positive float string" do
        let(:value) { "+123.5" }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with some non float string" do
        let(:value) { "abc" }

        it "is invalid" do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context "with an int string" do
        let(:value) { "5" }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with an empty string" do
        let(:value) { "" }

        it "is valid" do
          expect(custom_value)
            .to be_valid
        end
      end

      context "with a mixed string" do
        let(:value) { "6.5a" }

        it "is invalid" do
          expect(custom_value)
            .not_to be_valid
        end
      end
    end
  end

  describe "value/value=" do
    let(:custom_value) { build_stubbed(:custom_value) }
    let(:strategy_double) { instance_double(CustomValue::FormatStrategy) }

    it "calls the strategy for parsing and uses that value" do
      original_value = "original value"
      parsed_value = "parsed value"

      allow(custom_value)
        .to receive(:strategy)
        .and_return(strategy_double)

      allow(strategy_double)
        .to receive(:parse_value)
        .with(original_value)
        .and_return(parsed_value)

      custom_value.value = original_value

      expect(custom_value.value).to eql parsed_value
    end
  end

  describe "#activate_custom_field_in_customized_project" do
    let(:project) { create(:project) }

    context "with a given default value" do
      let(:custom_field) { create(:string_project_custom_field, default_value: "foo") }

      context "when a value other than the default value is set" do
        let(:custom_value) { build(:custom_value, custom_field:, customized: project, value: "bar") }

        it "activates the custom field in the project after create if missing" do
          expect(project.project_custom_fields).not_to include(custom_field)
          custom_value.save!
          expect(project.reload.project_custom_fields).to include(custom_field)
        end
      end

      context "when a value equal to the default value is set" do
        let(:custom_value) { build(:custom_value, custom_field:, customized: project, value: "foo") }

        it "activates the custom field in the project after create if missing" do
          expect(project.project_custom_fields).not_to include(custom_field)
          custom_value.save!
          expect(project.reload.project_custom_fields).not_to include(custom_field)
        end
      end

      context "when a value is not set" do
        let(:custom_value) { build(:custom_value, custom_field:, customized: project) }

        it "does not activate the custom field in the project after create if missing" do
          expect(project.project_custom_fields).not_to include(custom_field)
          custom_value.save!
          expect(project.reload.project_custom_fields).not_to include(custom_field)
        end
      end
    end

    context "with no default value given" do
      let(:custom_field) { create(:string_project_custom_field) }

      context "when a value is set" do
        let(:custom_value) { build(:custom_value, custom_field:, customized: project, value: "bar") }

        it "activates the custom field in the project after create if missing" do
          expect(project.project_custom_fields).not_to include(custom_field)
          custom_value.save!
          expect(project.reload.project_custom_fields).to include(custom_field)
        end
      end

      context "when a value is not set" do
        let(:custom_value) { build(:custom_value, custom_field:, customized: project) }

        it "does not activate the custom field in the project after create if missing" do
          expect(project.project_custom_fields).not_to include(custom_field)
          custom_value.save!
          expect(project.reload.project_custom_fields).not_to include(custom_field)
        end
      end
    end
  end
end
