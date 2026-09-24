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

RSpec.describe CustomField do
  before do
    described_class.destroy_all
  end

  let(:field)  { build(:custom_field) }
  let(:field2) { build(:custom_field) }

  it { is_expected.to have_readonly_attribute(:field_format) }

  describe "#name" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(256) }

    it_behaves_like "strips invisible characters", :name

    describe "uniqueness" do
      describe "WHEN value, locale and type are identical" do
        before do
          field.name = field2.name = "taken name"
          field2.save!
        end

        it { expect(field).not_to be_valid }
      end

      describe "WHEN value and locale are identical and type is different" do
        before do
          field.name = field2.name = "taken name"
          field2.save!
          field.type = "TestCustomField"
        end

        it { expect(field).to be_valid }
      end

      describe "WHEN type and locale are identical and value is different" do
        before do
          field.name = "new name"
          field2.name = "taken name"
          field2.save!
        end

        it { expect(field).to be_valid }
      end
    end
  end

  describe "#valid?" do
    describe "WITH a text field WITH minimum length blank" do
      before do
        field.field_format = "text"
        field.min_length = nil
      end

      it { expect(field).not_to be_valid }
    end

    describe "WITH a text field WITH maximum length blank" do
      before do
        field.field_format = "text"
        field.max_length = nil
      end

      it { expect(field).not_to be_valid }
    end

    describe "WITH a text field WITH minimum length not an integer" do
      before do
        field.field_format = "text"
        field.min_length = "a"
      end

      it { expect(field).not_to be_valid }
    end

    describe "WITH a text field WITH maximum length not an integer" do
      before do
        field.field_format = "text"
        field.max_length = "a"
      end

      it { expect(field).not_to be_valid }
    end

    describe "WITH a text field WITH minimum length greater than maximum length" do
      before do
        field.field_format = "text"
        field.min_length = 2
        field.max_length = 1
      end

      it { expect(field).not_to be_valid }
    end

    describe "WITH a text field WITH negative minimum length" do
      before do
        field.field_format = "text"
        field.min_length = -2
      end

      it { expect(field).not_to be_valid }
    end

    describe "WITH a text field WITH negative maximum length" do
      before do
        field.field_format = "text"
        field.max_length = -2
      end

      it { expect(field).not_to be_valid }
    end

    describe "WITH a text field WITH a minimum length but no maximum length" do
      before do
        field.field_format = "text"
        field.min_length = 2
        field.max_length = 0
      end

      it { expect(field).to be_valid }
    end

    describe "value bounds" do
      shared_examples "a numeric format" do |field_format|
        describe "WITH a #{field_format} field WITHOUT bounds" do
          before { field.field_format = field_format }

          it { expect(field).to be_valid }
        end

        describe "WITH a #{field_format} field WITH a zero minimum value" do
          before do
            field.field_format = field_format
            field.min_value = 0
          end

          it { expect(field).to be_valid }
        end

        describe "WITH a #{field_format} field WITH negative bounds" do
          before do
            field.field_format = field_format
            field.min_value = -10
            field.max_value = -5
          end

          it { expect(field).to be_valid }
        end

        describe "WITH a #{field_format} field WITH only a minimum value" do
          before do
            field.field_format = field_format
            field.min_value = 5
          end

          it { expect(field).to be_valid }
        end

        describe "WITH a #{field_format} field WITH only a maximum value" do
          before do
            field.field_format = field_format
            field.max_value = 5
          end

          it { expect(field).to be_valid }
        end

        describe "WITH a #{field_format} field WITH equal bounds" do
          before do
            field.field_format = field_format
            field.min_value = 5
            field.max_value = 5
          end

          it { expect(field).to be_valid }
        end

        describe "WITH a #{field_format} field WITH a minimum value above the maximum value" do
          before do
            field.field_format = field_format
            field.min_value = 10
            field.max_value = 5
          end

          it "is invalid" do
            expect(field).not_to be_valid
            expect(field.errors.symbols_for(:min_value)).to include(:smaller_than_or_equal_to_max_value)
          end
        end

        describe "WITH a #{field_format} field WITH a non numeric bound" do
          before do
            field.field_format = field_format
            field.min_value = "abc"
          end

          it "is invalid" do
            expect(field).not_to be_valid
            expect(field.errors.symbols_for(:min_value)).to include(:not_a_number)
          end
        end

        describe "WITH a #{field_format} field WITH a blank bound" do
          before do
            field.field_format = field_format
            field.min_value = ""
          end

          it "reads as unrestricted" do
            expect(field).to be_valid
            expect(field.min_value).to be_nil
            expect(field.min_bound).to be_nil
          end
        end
      end

      it_behaves_like "a numeric format", "int"
      it_behaves_like "a numeric format", "float"

      describe "WITH an int field WITH a decimal bound" do
        before do
          field.field_format = "int"
          field.min_value = 0.5
        end

        it "is invalid" do
          expect(field).not_to be_valid
          expect(field.errors.symbols_for(:min_value)).to include(:not_an_integer)
        end
      end

      describe "WITH an int field WITH an integral bound" do
        before do
          field.field_format = "int"
          field.min_value = 5
        end

        it "reads back as an integer" do
          expect(field).to be_valid
          expect(field.min_bound).to eq(5)
          expect(field.min_bound).to be_a(Integer)
        end
      end

      describe "WITH a float field WITH a decimal bound" do
        before do
          field.field_format = "float"
          field.min_value = "0.1234"
        end

        it "keeps the decimal" do
          expect(field).to be_valid
          expect(field.min_bound).to eq(0.1234)
        end
      end

      describe "WITH a text field WITH a value bound" do
        before do
          field.field_format = "text"
          field.min_value = 5
        end

        it { expect(field).not_to be_valid }
      end
    end

    describe "WITH a text field WITH an invalid regexp" do
      before do
        field.field_format = "text"
        field.regexp = "[0-9}"
      end

      it "is not valid" do
        expect(field).not_to be_valid
        expect(field.errors[:regexp].size).to eq(1)
      end
    end

    describe "WITH a list field WITH items" do
      let(:field) { create(:custom_field, :list, possible_values: %w[some\ value]) }

      it "is valid" do
        expect(field)
          .to be_valid
      end
    end
  end

  describe "#all_attribute_names" do
    subject { field.all_attribute_names }

    context "when field has comments" do
      let(:field) { build_stubbed(:custom_field, :has_comment) }

      it { is_expected.to eq(["custom_field_#{field.id}", "custom_comment_#{field.id}"]) }
    end

    context "when field has no comments" do
      let(:field) { build_stubbed(:custom_field) }

      it { is_expected.to eq(["custom_field_#{field.id}"]) }
    end
  end

  describe "#attribute_name" do
    let(:field) { build_stubbed(:custom_field) }

    subject { field.attribute_name }

    it { is_expected.to eq("custom_field_#{field.id}") }

    context "when a format is provided" do
      subject { field.attribute_name(:camel_case) }

      it { is_expected.to eq("customField#{field.id}") }
    end
  end

  describe "#comment_attribute_name" do
    let(:field) { build_stubbed(:custom_field) }

    subject { field.comment_attribute_name }

    it { is_expected.to eq("custom_comment_#{field.id}") }

    context "when a format is provided" do
      subject { field.comment_attribute_name(:camel_case) }

      it { is_expected.to eq("customComment#{field.id}") }
    end
  end

  describe "#attribute_getter" do
    let(:field) { build_stubbed(:custom_field) }

    subject { field.attribute_getter }

    it { is_expected.to eq(:"custom_field_#{field.id}") }
  end

  describe "#comment_attribute_getter" do
    let(:field) { build_stubbed(:custom_field) }

    subject { field.comment_attribute_getter }

    it { is_expected.to eq(:"custom_comment_#{field.id}") }
  end

  describe "#attribute_setter" do
    let(:field) { build_stubbed(:custom_field) }

    subject { field.attribute_setter }

    it { is_expected.to eq(:"custom_field_#{field.id}=") }
  end

  describe "#comment_attribute_setter" do
    let(:field) { build_stubbed(:custom_field) }

    subject { field.comment_attribute_setter }

    it { is_expected.to eq(:"custom_comment_#{field.id}=") }
  end

  describe "#column_name" do
    let(:field) { build_stubbed(:custom_field) }

    subject { field.column_name }

    it { is_expected.to eq("cf_#{field.id}") }
  end

  describe "#possible_values_options" do
    let(:project) { build_stubbed(:project) }
    let(:user1) { build_stubbed(:user) }
    let(:user2) { build_stubbed(:user) }
    let(:in_visible_scope) { instance_double(ActiveRecord::Relation) }
    let(:principals_scope) { instance_double(ActiveRecord::Relation) }
    let(:all_visible_scope) { instance_double(ActiveRecord::Relation) }

    context "for a user custom field" do
      before do
        field.field_format = "user"
        allow(project)
          .to receive(:principals)
                .and_return(principals_scope)

        allow(principals_scope)
          .to receive(:select)
                .and_return([user1, user2])

        allow(Principal).to receive_messages(
          in_visible_project_or_me: in_visible_scope,
          visible: all_visible_scope
        )

        allow(in_visible_scope).to receive(:select).and_return([user2])
        allow(all_visible_scope).to receive(:select).and_return([user1])
      end

      context "for a project" do
        it "is a list of name, id pairs" do
          expect(field.possible_values_options(project))
            .to contain_exactly([user1.name, user1.id.to_s], [user2.name, user2.id.to_s])
        end
      end

      context "for something that responds to project" do
        it "is a list of name, id pairs" do
          object = OpenStruct.new(project:) # rubocop:disable Style/OpenStructUse

          expect(field.possible_values_options(object))
            .to contain_exactly([user1.name, user1.id.to_s], [user2.name, user2.id.to_s])
        end
      end

      context "for nil" do
        it "returns all principles visible to me" do
          expect(field.possible_values_options)
            .to contain_exactly([user2.name, user2.id.to_s])
        end
      end

      context "with user format setting excluding lastname", with_settings: { user_format: :username } do
        it "always includes lastname for Group#name{:lastname} aliasing" do
          expect(field.possible_values_options)
            .to contain_exactly([user2.name, user2.id.to_s])

          expect(in_visible_scope).to have_received(:select)
           .with("login", "lastname", "id", "type")
        end
      end

      context "for a custom field bound to role assigment" do
        let(:project_role) { build_stubbed(:project_role) }
        let(:field) { build(:project_custom_field, :user, role_id: project_role.id) }

        it "allows all visible users" do
          expect(field.possible_values_options).to contain_exactly([user1.name, user1.id.to_s])
        end
      end
    end

    context "for a list custom field" do
      let(:field) { create(:custom_field, :list, possible_values: ["First", "Second"]) }

      it "is a list of label, id pairs" do
        expect(field.possible_values_options)
          .to eq(field.possible_values.map { |item| [item.label, item.id.to_s] })
      end
    end

    context "for a version custom field" do
      let(:versions) { [build_stubbed(:version, project:), build_stubbed(:version, project:)] }
      let(:shared_versions_scope) { instance_double(ActiveRecord::Relation) }

      before do
        field.field_format = "version"
        allow(shared_versions_scope)
          .to receive(:references)
          .with(:project)
          .and_return(versions)
      end

      context "with a project provided" do
        it "returns the project's shared_versions" do
          allow(project)
            .to receive(:shared_versions)
            .and_return(shared_versions_scope)

          expect(field.possible_values_options(project))
            .to eql(versions.sort.map { |u| [u.name, u.id.to_s, project.name] })
        end
      end

      context "with a time entry provided" do
        let(:time_entry) { build_stubbed(:time_entry, project:) }

        it "returns the project's shared_versions" do
          allow(project)
            .to receive(:shared_versions)
            .and_return(shared_versions_scope)

          expect(field.possible_values_options(project))
            .to eql(versions.sort.map { |u| [u.name, u.id.to_s, project.name] })
        end
      end

      context "with nothing provided" do
        context "and no scope provided" do
          it "returns the systemwide versions" do
            allow(Version)
              .to receive(:systemwide)
              .and_return(shared_versions_scope)

            expect(field.possible_values_options)
              .to eql(versions.sort.map { |u| [u.name, u.id.to_s, project.name] })
          end
        end

        context "and scope: :visible is provided" do
          it "returns the visible and systemwide versions" do
            allow(Version).to receive(:visible).and_return(shared_versions_scope)
            allow(shared_versions_scope).to receive(:or)
                                        .with(Version.systemwide)
                                        .and_return(shared_versions_scope)

            expect(field.possible_values_options(options: { scope: :visible }))
              .to eql(versions.sort.map { |u| [u.name, u.id.to_s, project.name] })
          end
        end
      end
    end
  end

  describe "#possible_values" do
    context "on a list custom field" do
      let(:field) { create(:custom_field, :list, possible_values:) }

      context "on providing an array" do
        let(:possible_values) { ["One value", "Two values", ""] }

        it "accepts the values" do
          expect(field.possible_values.pluck(:label))
            .to contain_exactly("One value", "Two values")
        end
      end

      context "on providing a string" do
        let(:possible_values) { "One value" }

        it "accepts the values" do
          expect(field.possible_values.pluck(:label))
            .to contain_exactly("One value")
        end
      end

      context "on providing a multiline string" do
        let(:possible_values) { "One value\nTwo values  \r\n \n" }

        it "accepts the values" do
          expect(field.possible_values.pluck(:label))
            .to contain_exactly("One value", "Two values")
        end
      end
    end
  end

  describe "#possible_values=" do
    context "on a persisted custom field" do
      let(:field) { create(:custom_field, :list, possible_values: ["Existing"]) }

      it "raises instead of silently discarding the new values" do
        expect { field.possible_values = ["New"] }
          .to raise_error(/possible_values=/)

        expect(field.possible_values.pluck(:label)).to contain_exactly("Existing")
      end
    end
  end

  describe "#flush_buffered_possible_values" do
    it "raises when the hierarchy service rejects one of the buffered values" do
      real_service = CustomFields::Hierarchy::HierarchicalItemService.new
      service = instance_double(CustomFields::Hierarchy::HierarchicalItemService)
      allow(CustomFields::Hierarchy::HierarchicalItemService).to receive(:new).and_return(service)
      allow(service).to receive(:generate_root) { |cf| real_service.generate_root(cf) }
      allow(service).to receive(:insert_item).and_return(Dry::Monads::Failure.new(:boom))

      expect { create(:custom_field, field_format: "list", possible_values: ["Only"]) }
        .to raise_error(/Could not insert possible value/)
    end
  end

  describe "#multi_value_possible?" do
    context "with a wp list cf" do
      let(:field) { build_stubbed(:list_wp_custom_field) }

      it "is true" do
        expect(field)
          .to be_multi_value_possible
      end
    end

    context "with a wp user cf" do
      let(:field) { build_stubbed(:user_wp_custom_field) }

      it "is true" do
        expect(field)
          .to be_multi_value_possible
      end
    end

    context "with a wp int cf" do
      let(:field) { build_stubbed(:integer_wp_custom_field) }

      it "is false" do
        expect(field)
          .not_to be_multi_value_possible
      end
    end

    context "with a project list cf" do
      let(:field) { build_stubbed(:list_project_custom_field) }

      it "is true" do
        expect(field)
          .to be_multi_value_possible
      end
    end

    context "with a project user cf" do
      let(:field) { build_stubbed(:user_project_custom_field) }

      it "is true" do
        expect(field)
          .to be_multi_value_possible
      end
    end

    context "with a project int cf" do
      let(:field) { build_stubbed(:integer_project_custom_field) }

      it "is false" do
        expect(field)
          .not_to be_multi_value_possible
      end
    end

    context "with a project calculated value cf" do
      let(:field) { build_stubbed(:calculated_value_project_custom_field) }

      it "is false" do
        expect(field)
          .not_to be_multi_value_possible
      end
    end

    context "with a time_entry user cf" do
      let(:field) { build_stubbed(:time_entry_custom_field, :user) }

      it "is true" do
        expect(field)
          .to be_multi_value_possible
      end
    end

    context "with a time_entry list cf" do
      let(:field) { build_stubbed(:time_entry_custom_field, :list) }

      it "is true" do
        expect(field)
          .to be_multi_value_possible
      end
    end
  end

  describe "#allow_non_open_versions?" do
    context "with a wp list cf" do
      let(:field) { build_stubbed(:list_wp_custom_field) }

      it "is false" do
        expect(field)
          .not_to be_allow_non_open_versions_possible
      end
    end

    context "with a wp user cf" do
      let(:field) { build_stubbed(:user_wp_custom_field) }

      it "is false" do
        expect(field)
          .not_to be_allow_non_open_versions_possible
      end
    end

    context "with a wp int cf" do
      let(:field) { build_stubbed(:integer_wp_custom_field) }

      it "is false" do
        expect(field)
          .not_to be_allow_non_open_versions_possible
      end
    end

    context "with a work package user cf" do
      let(:field) { build_stubbed(:wp_custom_field, :user) }

      it "is false" do
        expect(field)
          .not_to be_allow_non_open_versions_possible
      end
    end

    context "with a work package version cf" do
      let(:field) { build_stubbed(:wp_custom_field, :version) }

      it "is true" do
        expect(field)
          .to be_allow_non_open_versions_possible
      end
    end

    context "with a version cf for version" do
      let(:field) { build_stubbed(:version_custom_field, :version) }

      it "is true" do
        expect(field)
          .to be_allow_non_open_versions_possible
      end
    end

    context "with a project version cf" do
      let(:field) { build_stubbed(:project_custom_field, :version) }

      it "is true" do
        expect(field)
          .to be_allow_non_open_versions_possible
      end
    end

    context "with a time entry version cf" do
      let(:field) { build_stubbed(:time_entry_custom_field, :version) }

      it "is true" do
        expect(field)
          .to be_allow_non_open_versions_possible
      end
    end
  end

  describe "#destroy" do
    it "removes the cf" do
      field.save!

      field.destroy
      expect(described_class.where(id: field.id)).not_to exist
    end
  end

  describe "can_have_comment? instance and class methods" do
    context "for project custom field" do
      let(:instance) { build_stubbed(:project_custom_field) }

      context "for instance" do
        it { expect(instance).to be_can_have_comment }
      end

      context "for class" do
        it { expect(instance.class).to be_can_have_comment }
      end
    end

    {
      wp_custom_field: "work package",
      user_custom_field: "user",
      version_custom_field: "version",
      custom_field: "base"
    }.each do |factory, name|
      context "for #{name} custom field" do
        let(:instance) { build_stubbed(factory) }

        context "for instance" do
          it { expect(instance).not_to be_can_have_comment }
        end

        context "for class" do
          it { expect(instance.class).not_to be_can_have_comment }
        end
      end
    end
  end

  describe "#comment_for" do
    let(:field) { build_stubbed(:project_custom_field) }
    let(:customized) { build_stubbed(:project) }

    before { allow(field).to receive(:comments).and_return(comments) }

    context "when there are no comments" do
      let(:comments) { [] }

      it "returns nil" do
        expect(field.comment_for(customized)).to be_nil
      end
    end

    context "when comments exist only for other customized" do
      let(:comments) { [build_stubbed(:custom_comment, customized: build_stubbed(:project), custom_field: field)] }

      it "returns nil" do
        expect(field.comment_for(customized)).to be_nil
      end
    end

    context "when comment exists for the customized" do
      let(:comment) { build_stubbed(:custom_comment, customized:, custom_field: field) }
      let(:other_comment) { build_stubbed(:custom_comment, customized: build_stubbed(:project), custom_field: field) }
      let(:comments) { [other_comment, comment] }

      it "returns the matching comment" do
        expect(field.comment_for(customized)).to eq(comment)
      end
    end
  end

  describe "#cast_value" do
    describe "handling all registered formats" do
      before do
        allow(Principal).to receive(:find_by).with(id: 1).and_return(build(:user))
        allow(Version).to receive(:find_by).with(id: 1).and_return(build(:version))
        allow(CustomField::Hierarchy::Item).to receive(:find_by).with(id: 1).and_return(build(:hierarchy_item))
      end

      OpenProject::CustomFieldFormat.registered.map(&:name).each do |field_format|
        it "handles custom field with format #{field_format}" do
          field = build(:custom_field, field_format:)

          input = field_format == "date" ? "2025.10.27" : "1"

          if field_format == "empty"
            expect(field.cast_value(input)).to be_nil
          else
            expect(field.cast_value(input)).not_to be_nil
          end
        end
      end
    end
  end

  describe "#default_value for hierarchical formats", with_ee: [:custom_field_hierarchies] do
    let(:custom_field) { create(:hierarchy_wp_custom_field) }
    let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }
    let!(:first) do
      service.insert_item(contract_class: CustomFields::Hierarchy::InsertHierarchyItemContract,
                          parent: custom_field.hierarchy_root, label: "First").value!
    end
    let!(:second) do
      service.insert_item(contract_class: CustomFields::Hierarchy::InsertHierarchyItemContract,
                          parent: custom_field.hierarchy_root, label: "Second").value!
    end

    it "is nil when no item is marked as default" do
      expect(custom_field.default_value).to be_nil
    end

    it "returns the marked item's id as a string" do
      second.update!(default_value: true)

      expect(custom_field.default_value).to eq(second.id.to_s)
    end

    context "when the field is multi value" do
      let(:custom_field) { create(:hierarchy_wp_custom_field, multi_value: true) }

      it "returns every marked item's id" do
        first.update!(default_value: true)
        second.update!(default_value: true)

        expect(custom_field.default_value).to contain_exactly(first.id.to_s, second.id.to_s)
      end

      it "orders the marked ids by position, not by the order they were marked" do
        third = service.insert_item(contract_class: CustomFields::Hierarchy::InsertHierarchyItemContract,
                                    parent: custom_field.hierarchy_root, label: "Third").value!
        third.update!(default_value: true)
        first.update!(default_value: true)

        expect(custom_field.default_value).to eq([first.id.to_s, third.id.to_s])
      end
    end
  end

  describe "#generate_hierarchy_root" do
    it "raises and rolls back the field when the root cannot be created" do
      service = instance_double(CustomFields::Hierarchy::HierarchicalItemService,
                                generate_root: Dry::Monads::Failure.new(:boom))
      allow(CustomFields::Hierarchy::HierarchicalItemService).to receive(:new).and_return(service)

      expect { create(:custom_field, field_format: "list") }
        .to raise_error(/Could not generate a hierarchy root/)
        .and not_change(described_class, :count)
    end
  end
end
