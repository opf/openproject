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
require_relative "../shared_expectations"

RSpec.describe Automations::Actions::CustomField do
  let(:scope) { instance_double(ActiveRecord::Relation) }
  let(:list_custom_field) do
    build_stubbed(:list_wp_custom_field,
                  custom_options: [build_stubbed(:custom_option, value: "A"),
                                   build_stubbed(:custom_option, value: "B")])
  end
  let(:list_multi_custom_field) do
    build_stubbed(:list_wp_custom_field,
                  custom_options: [build_stubbed(:custom_option, value: "A"),
                                   build_stubbed(:custom_option, value: "B")],
                  multi_value: true)
  end
  let(:version_custom_field) do
    build_stubbed(:version_wp_custom_field)
  end
  let(:bool_custom_field) do
    build_stubbed(:boolean_wp_custom_field)
  end
  let(:user_custom_field) do
    build_stubbed(:user_wp_custom_field)
  end
  let(:int_custom_field) do
    build_stubbed(:integer_wp_custom_field)
  end
  let(:float_custom_field) do
    build_stubbed(:float_wp_custom_field)
  end
  let(:text_custom_field) do
    build_stubbed(:text_wp_custom_field)
  end
  let(:string_custom_field) do
    build_stubbed(:string_wp_custom_field)
  end
  let(:link_custom_field) do
    build_stubbed(:link_wp_custom_field)
  end
  let(:date_custom_field) do
    build_stubbed(:date_wp_custom_field)
  end

  let(:custom_field) do
    list_custom_field
  end
  let(:custom_fields) do
    [list_custom_field,
     version_custom_field,
     bool_custom_field,
     user_custom_field,
     int_custom_field,
     float_custom_field,
     text_custom_field,
     string_custom_field,
     link_custom_field,
     date_custom_field]
  end
  let(:klass) do
    allow(WorkPackageCustomField)
      .to receive(:find_by)
      .with(id: custom_field.id)
      .and_return(custom_field)

    described_class.subclass_for(custom_field)
  end
  let(:instance) do
    klass.new(custom_field_id: custom_field.id)
  end

  describe ".templates" do
    before do
      allow(WorkPackageCustomField)
        .to receive(:usable_as_automation)
        .and_return(custom_fields)
    end

    it "is an array of template instances for every custom_field" do
      expect(described_class.templates.length)
        .to eql custom_fields.length

      expect(described_class.templates.map(&:custom_field))
        .to match_array(custom_fields)

      described_class.templates.each do |template|
        expect(template).to be_a(described_class)
      end
    end
  end

  describe "#key" do
    it "is the custom field accessor" do
      expect(instance.key)
        .to eql(custom_field.attribute_getter)
    end
  end

  describe "#value" do
    it "can be provided on initialization" do
      i = klass.new(custom_field_id: custom_field.id, values: [1])

      expect(i.values)
        .to eql [1]
    end

    it "can be set and read" do
      instance.values = [1]

      expect(instance.values)
        .to eql [1]
    end

    context "for an list custom field" do
      let(:custom_field) { list_custom_field }

      it_behaves_like "associated values transformation"
    end

    context "for an int custom field" do
      let(:custom_field) { int_custom_field }

      it_behaves_like "int values transformation"
    end

    context "for a float custom field" do
      let(:custom_field) { float_custom_field }

      it_behaves_like "float values transformation"
    end

    context "for a string custom field" do
      let(:custom_field) { string_custom_field }

      it_behaves_like "string values transformation"
    end

    context "for a link custom field" do
      let(:custom_field) { link_custom_field }

      it_behaves_like "string values transformation"
    end

    context "for a text custom field" do
      let(:custom_field) { text_custom_field }

      it_behaves_like "text values transformation"
    end

    context "for a date custom field" do
      let(:custom_field) { date_custom_field }

      it_behaves_like "date values transformation"
    end
  end

  describe "#human_name" do
    it "is the name of the custom field" do
      expect(instance.human_name)
        .to eql(custom_field.name)
    end
  end

  describe "#type" do
    context "for a list custom field" do
      it "is :associated_property" do
        expect(instance.type)
          .to be(:associated_property)
      end
    end

    context "for a list custom field allowing multiple values" do
      let(:custom_field) { list_multi_custom_field }

      it "is :associated_property" do
        expect(instance.type)
          .to be(:associated_property)
      end
    end

    context "for a text custom field" do
      let(:custom_field) { text_custom_field }

      it "is :text_property" do
        expect(instance.type)
          .to be(:text_property)
      end
    end

    context "for a string custom field" do
      let(:custom_field) { string_custom_field }

      it "is :string_property" do
        expect(instance.type)
          .to be(:string_property)
      end
    end

    context "for a link custom field" do
      let(:custom_field) { link_custom_field }

      it "is :link_property" do
        expect(instance.type)
          .to be(:link_property)
      end
    end

    context "for a version custom field" do
      let(:custom_field) { version_custom_field }

      it "is :associated_property" do
        expect(instance.type)
          .to be(:associated_property)
      end
    end

    context "for a bool custom field" do
      let(:custom_field) { bool_custom_field }

      it "is :boolean" do
        expect(instance.type)
          .to be(:boolean)
      end
    end

    context "for a user custom field" do
      let(:custom_field) { user_custom_field }

      it "is :associated_property" do
        expect(instance.type)
          .to be(:user)
      end

      describe "current_user special value" do
        let(:work_package) { build_stubbed(:work_package) }
        let(:user) { build_stubbed(:user) }

        before do
          allow(work_package).to receive(:available_custom_fields).and_return([custom_field])
          instance.values = ["current_user"]
        end

        it "can set the value" do
          expect(instance).to have_me_value
        end

        it "includes the value in available_values" do
          expect(instance.associated)
            .to include([instance.current_user_value_key, I18n.t("automations.actions.assigned_to.executing_user_value")])
        end

        context "when logged in" do
          before do
            login_as user
          end

          it "sets the current user" do
            instance.apply work_package
            expect(work_package.custom_value_for(custom_field).value).to eq(user.id.to_s)
          end

          it "validates the me value when executing" do
            errors = ActiveModel::Errors.new(Automation.new)
            instance.validate errors
            expect(errors.symbols_for(:actions)).to be_empty
          end
        end

        context "when not logged in" do
          before do
            login_as User.anonymous
          end

          it "returns nil for the current user id" do
            instance.apply work_package
            expect(work_package.custom_value_for(custom_field).value).to be_nil
          end

          it "validates the me value when executing" do
            errors = ActiveModel::Errors.new(Automation.new)
            instance.validate errors
            expect(errors.symbols_for(:actions)).to include :not_logged_in
          end
        end
      end
    end

    context "for an int custom field" do
      let(:custom_field) { int_custom_field }

      it "is :integer_property" do
        expect(instance.type)
          .to be(:integer_property)
      end
    end

    context "for a float custom field" do
      let(:custom_field) { float_custom_field }

      it "is :float_property" do
        expect(instance.type)
          .to be(:float_property)
      end
    end

    context "for a date custom field" do
      let(:custom_field) { date_custom_field }

      it "is :date_property" do
        expect(instance.type)
          .to be(:date_property)
      end
    end
  end

  describe "#multi_value?" do
    context "for a non multi value field" do
      it "is false" do
        expect(instance)
          .not_to be_multi_value
      end
    end

    context "for a multi value field" do
      let(:custom_field) { list_multi_custom_field }

      it "is true" do
        expect(instance)
          .to be_multi_value
      end
    end
  end

  describe "#allowed_values" do
    context "for a list custom field" do
      let(:expected) do
        custom_field
          .custom_options
          .map { |o| { value: o.id, label: o.value } }
      end

      context "for a non required field" do
        it "is the list of options and an empty placeholder" do
          expect(instance.allowed_values)
            .to eql(expected.unshift(value: nil, label: "-"))
        end
      end

      context "for a required field" do
        before do
          custom_field.is_required = true
        end

        it "is the list of options" do
          expect(instance.allowed_values)
            .to eql(expected)
        end
      end
    end

    context "for a version custom field" do
      let(:custom_field) { version_custom_field }
      let(:expected) do
        # the versions will be sorted which by their name (and the project but that is the same for all of them)
        versions
          .sort
          .map { |o| { value: o.id, label: o.name } }
      end
      let(:project) { build_stubbed(:project) }
      let(:a_version) { build_stubbed(:version, name: "aaaaa", project:) }
      let(:m_version) { build_stubbed(:version, name: "mmmmm", project:) }
      let(:z_version) { build_stubbed(:version, name: "zzzzz", project:) }
      let(:versions) { [z_version, a_version, m_version] }

      before do
        allow(scope)
          .to receive(:references)
                .with(:project)
                .and_return(versions)

        allow(Version)
          .to receive(:systemwide)
          .and_return(scope)
      end

      context "for a non required field" do
        it "is the list of options and an empty placeholder" do
          expect(instance.allowed_values)
            .to eql(expected.unshift(value: nil, label: "-"))
        end
      end

      context "for a required field" do
        before do
          custom_field.is_required = true
        end

        it "is the list of options" do
          expect(instance.allowed_values)
            .to eql(expected)
        end
      end
    end

    context "for a user custom field" do
      let(:custom_field) { user_custom_field }
      let(:expected) do
        values = [{ label: "(Assign to executing user)", value: "current_user" }]
        values + users.map { |u| { value: u.id, label: u.name } }
      end
      let(:users) do
        [build_stubbed(:user),
         build_stubbed(:user),
         build_stubbed(:user)]
      end

      before do
        allow(Principal)
          .to receive(:in_visible_project_or_me)
                .with(User.current)
                .and_return(scope)

        allow(scope)
          .to receive(:select)
                .and_return(users)
      end

      context "for a non required field" do
        it "is the list of options and an empty placeholder" do
          expect(instance.allowed_values)
            .to eql(expected.unshift(value: nil, label: "-"))
        end
      end

      context "for a required field" do
        before do
          custom_field.is_required = true
        end

        it "is the list of options" do
          expect(instance.allowed_values)
            .to eql(expected)
        end
      end
    end

    context "for a bool custom field" do
      let(:custom_field) { bool_custom_field }

      let(:expected) do
        [
          { label: I18n.t(:general_text_yes), value: OpenProject::Database::DB_VALUE_TRUE },
          { label: I18n.t(:general_text_no), value: OpenProject::Database::DB_VALUE_FALSE }
        ]
      end

      it "is the list of options" do
        expect(instance.allowed_values)
          .to eql(expected)
      end
    end
  end

  describe "#validate" do
    context "for a list custom field" do
      it_behaves_like "associated custom action validations" do
        let(:allowed_values) do
          custom_field
            .custom_options
            .map { |o| { value: o.id, label: o.value } }
        end
      end
    end

    context "for a multi list custom field" do
      let(:custom_field) { list_multi_custom_field }

      it_behaves_like "associated custom action validations" do
        let(:allowed_values) do
          custom_field
            .custom_options
            .map { |o| { value: o.id, label: o.value } }
        end
      end
    end

    context "for a user custom field" do
      let(:custom_field) { user_custom_field }
      let(:users) do
        [build_stubbed(:user),
         build_stubbed(:user),
         build_stubbed(:user)]
      end

      before do
        allow(Principal)
          .to receive(:in_visible_project_or_me)
                .with(User.current)
                .and_return(scope)

        allow(scope)
          .to receive(:select)
                .and_return(users)
      end

      it_behaves_like "associated custom action validations" do
        let(:allowed_values) do
          users
            .map { |u| { value: u.id, label: u.name } }
        end
      end
    end

    context "for a version custom field" do
      let(:custom_field) { version_custom_field }
      let(:project) { build_stubbed(:project) }
      let(:versions) do
        [build_stubbed(:version, project:),
         build_stubbed(:version, project:),
         build_stubbed(:version, project:)]
      end

      before do
        allow(scope)
          .to receive(:references)
                .with(:project)
                .and_return(versions)

        allow(Version)
          .to receive(:systemwide)
          .and_return(scope)
      end

      it_behaves_like "associated custom action validations" do
        let(:allowed_values) do
          versions
            .map { |o| { value: o.id, label: o.name } }
        end
      end
    end

    context "for a bool custom field" do
      let(:custom_field) { bool_custom_field }

      it_behaves_like "bool custom action validations" do
        let(:allowed_values) do
          [
            { true => OpenProject::Database::DB_VALUE_TRUE },
            { false => OpenProject::Database::DB_VALUE_FALSE }
          ]
        end
      end
    end

    context "for an int custom field" do
      let(:custom_field) { int_custom_field }

      it_behaves_like "int custom action validations"
    end

    context "for a float custom field" do
      let(:custom_field) { float_custom_field }

      it_behaves_like "float custom action validations"
    end

    context "for a string custom field" do
      let(:custom_field) { string_custom_field }

      it_behaves_like "string custom action validations"
    end

    context "for a link custom field" do
      let(:custom_field) { link_custom_field }

      it_behaves_like "link custom action validations"
    end

    context "for a date custom field" do
      let(:custom_field) { date_custom_field }

      it_behaves_like "date custom action validations"
    end
  end

  describe "#apply" do
    let(:work_package) { build(:work_package) }

    %i[list
       version
       bool
       user
       int
       float
       text
       string
       date
       list_multi].each do |type|
      let(:custom_field) { send(:"#{type}_custom_field") }

      it "sets the value for #{type} custom fields" do
        without_partial_double_verification do
          allow(work_package)
            .to receive(custom_field.attribute_setter)
        end

        instance.values = 42
        instance.apply(work_package)

        without_partial_double_verification do
          expect(work_package)
            .to have_received(custom_field.attribute_setter)
            .with([42])
        end
      end
    end

    context "for a date custom field" do
      let(:custom_field) { date_custom_field }

      it "sets the value to today for a dynamic value" do
        without_partial_double_verification do
          allow(work_package)
            .to receive(custom_field.attribute_setter)

          instance.values = "%CURRENT_DATE%"
          instance.apply(work_package)

          expect(work_package)
            .to have_received(custom_field.attribute_setter)
                  .with(Date.current)
        end
      end
    end

    describe "custom field validation" do
      let(:custom_field) { create(:string_wp_custom_field) }
      let(:work_package) { create(:work_package) }
      let(:custom_value) { work_package.custom_value_for(custom_field) }

      before do
        # Ensure the work package has the custom field
        work_package.project.work_package_custom_fields << custom_field
        work_package.type.custom_fields << custom_field
        work_package.reload # Reload to pick up the new custom field associations
      end

      it "adds the custom value to custom_values_to_validate when applying the action" do
        # Create the action instance for our created custom field
        action_instance = described_class.subclass_for(custom_field).new(custom_field_id: custom_field.id)
        action_instance.values = ["test value"]

        # Initially, custom_values_to_validate should be empty for persisted work packages
        expect(work_package.custom_values_to_validate).to eq([])

        action_instance.apply(work_package)

        # After applying, the custom value should be added to validation
        expect(work_package.custom_values_to_validate).to include(custom_value)
        expect(work_package.custom_values_to_validate.size).to eq(1)
      end

      it "does not add to custom_values_to_validate if work package doesn't respond to the setter" do
        # Create a work package that doesn't have this custom field
        other_work_package = create(:work_package)
        action_instance = described_class.subclass_for(custom_field).new(custom_field_id: custom_field.id)
        action_instance.values = ["test value"]

        expect(other_work_package.custom_values_to_validate).to be_empty

        action_instance.apply(other_work_package)

        # Should remain empty since the setter doesn't exist
        expect(other_work_package.custom_values_to_validate).to be_empty
      end

      context "with multiple custom actions" do
        let(:another_custom_field) { create(:string_wp_custom_field) }
        let(:another_instance) { described_class.subclass_for(another_custom_field).new(custom_field_id: another_custom_field.id) }

        before do
          work_package.project.work_package_custom_fields << another_custom_field
          work_package.type.custom_fields << another_custom_field
        end

        it "accumulates custom values in custom_values_to_validate" do
          action_instance = described_class.subclass_for(custom_field).new(custom_field_id: custom_field.id)
          action_instance.values = ["first value"]
          another_instance.values = ["second value"]

          expect(work_package.custom_values_to_validate).to be_empty

          action_instance.apply(work_package)
          expect(work_package.custom_values_to_validate.size).to eq(1)

          another_instance.apply(work_package)
          expect(work_package.custom_values_to_validate.size).to eq(2)

          # Should contain custom values for both fields
          custom_field_ids = work_package.custom_values_to_validate.map(&:custom_field_id)
          expect(custom_field_ids).to contain_exactly(custom_field.id, another_custom_field.id)
        end
      end
    end
  end
end
