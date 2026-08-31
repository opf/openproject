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

    describe "WITH a list field WITH a custom option" do
      before do
        field.field_format = "list"
        field.custom_options.build(value: "some value")
      end

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
      let(:option1) { build_stubbed(:custom_option) }
      let(:option2) { build_stubbed(:custom_option) }

      before do
        field.field_format = "list"

        field.custom_options = [option1, option2]
      end

      it "is a list of name, id pairs" do
        expect(field.possible_values_options)
          .to contain_exactly([option1.value, option1.id.to_s], [option2.value, option2.id.to_s])
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
      let(:field) { described_class.new field_format: "list" }

      context "on providing an array" do
        before do
          field.possible_values = ["One value", "Two values", ""]
        end

        it "accepts the values" do
          expect(field.possible_values.map(&:value))
            .to contain_exactly("One value", "Two values")
        end
      end

      context "on providing a string" do
        before do
          field.possible_values = "One value"
        end

        it "accepts the values" do
          expect(field.possible_values.map(&:value))
            .to contain_exactly("One value")
        end
      end

      context "on providing a multiline string" do
        before do
          field.possible_values = "One value\nTwo values  \r\n \n"
        end

        it "accepts the values" do
          expect(field.possible_values.map(&:value))
            .to contain_exactly("One value", "Two values")
        end
      end
    end
  end

  describe "nested attributes for custom options" do
    let(:option) { build(:custom_option) }
    let(:options) { [option] }
    let(:field) { build(:custom_field, field_format: "list", custom_options: options) }

    before do
      field.save!
    end

    shared_examples_for "saving updates field's updated_at" do
      it "updates updated_at" do
        timestamp_before = field.updated_at
        sleep 0.001
        field.save
        expect(field.updated_at).not_to eql(timestamp_before)
      end
    end

    context "after adding a custom option" do
      before do
        field.attributes = { "custom_options_attributes" => { "0" => option.attributes,
                                                              "1" => { value: "blubs" } } }
      end

      it_behaves_like "saving updates field's updated_at"
    end

    context "after changing a custom option" do
      before do
        attributes = option.attributes.merge(value: "new_value")

        field.attributes = { "custom_options_attributes" => { "0" => attributes } }
      end

      it_behaves_like "saving updates field's updated_at"
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
end
