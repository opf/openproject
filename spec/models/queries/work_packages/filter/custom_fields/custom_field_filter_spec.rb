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

RSpec.describe Queries::WorkPackages::Filter::CustomFieldFilter do
  let(:project) { build_stubbed(:project) }
  let(:bool_wp_custom_field) { build_stubbed(:boolean_wp_custom_field) }
  let(:int_wp_custom_field) { build_stubbed(:integer_wp_custom_field) }
  let(:float_wp_custom_field) { build_stubbed(:float_wp_custom_field) }
  let(:text_wp_custom_field) { build_stubbed(:text_wp_custom_field) }
  let(:user_wp_custom_field) { build_stubbed(:user_wp_custom_field) }
  let(:version_wp_custom_field) { build_stubbed(:version_wp_custom_field) }
  let(:date_wp_custom_field) { build_stubbed(:date_wp_custom_field) }
  let(:string_wp_custom_field) { build_stubbed(:string_wp_custom_field) }
  let(:link_wp_custom_field) { build_stubbed(:link_wp_custom_field) }
  let(:custom_field) { list_wp_custom_field }
  let(:all_custom_fields) do
    [list_wp_custom_field,
     bool_wp_custom_field,
     int_wp_custom_field,
     float_wp_custom_field,
     text_wp_custom_field,
     user_wp_custom_field,
     version_wp_custom_field,
     date_wp_custom_field,
     string_wp_custom_field,
     link_wp_custom_field]
  end
  let(:query) { build_stubbed(:query, project:) }
  let(:cf_accessor) { custom_field.column_name }
  let(:instance) do
    described_class.create!(name: cf_accessor, operator: "=", context: query)
  end
  let(:instance_key) { nil }

  shared_let(:list_wp_custom_field) { create(:list_wp_custom_field) }

  before do
    allow(WorkPackageCustomField)
      .to receive(:all)
      .and_return(all_custom_fields)
  end

  describe "invalid custom field" do
    let(:cf_accessor) { "cf_100" }
    let(:all_custom_fields) { [] }

    it "raises exception" do
      expect { instance }.to raise_error(Queries::Filters::InvalidError)
    end
  end

  describe ".valid?" do
    let(:custom_field) { string_wp_custom_field }

    before do
      instance.values = ["bogus"]
    end

    shared_examples_for "custom field type dependent validity" do
      context "with a string custom field" do
        it "is valid" do
          expect(instance).to be_valid
        end
      end

      context "with a list custom field" do
        let(:custom_field) { list_wp_custom_field }

        before do
          instance.values = [list_wp_custom_field.possible_values.first.id]
        end

        it "is valid" do
          expect(instance).to be_valid
        end

        it "is invalid if the value is not one of the custom field's possible values" do
          instance.values = ["bogus"]

          expect(instance).not_to be_valid
        end
      end
    end

    context "within a project" do
      it_behaves_like "custom field type dependent validity"
    end

    context "without a project" do
      let(:project) { nil }

      it_behaves_like "custom field type dependent validity"
    end
  end

  describe ".key" do
    it "is a regular expression" do
      expect(described_class.key).to eql(/cf_(\d+)/)
    end
  end

  describe "instance attributes" do
    it "are valid" do
      all_custom_fields.each do |cf|
        filter = described_class.create!(name: cf.column_name)
        expect(filter.name).to eql(cf.column_name.to_sym)
      end
    end
  end

  describe "#type" do
    describe "integer" do
      let(:cf_accessor) { int_wp_custom_field.column_name }

      it "is integer for an integer" do
        expect(instance.type)
          .to be(:integer)
      end
    end

    describe "float" do
      let(:cf_accessor) { float_wp_custom_field.column_name }

      it "is integer for a float" do
        expect(instance.type)
          .to be(:float)
      end
    end

    describe "text" do
      let(:cf_accessor) { text_wp_custom_field.column_name }

      it "is text for a text" do
        expect(instance.type)
          .to be(:text)
      end
    end

    describe "list optional" do
      let(:cf_accessor) { list_wp_custom_field.column_name }

      it "is list_optional for a list" do
        expect(instance.type)
          .to be(:list_optional)
      end
    end

    describe "user" do
      let(:cf_accessor) { user_wp_custom_field.column_name }

      it "is list_optional for a user" do
        expect(instance.type)
          .to be(:list_optional)
      end
    end

    describe "version" do
      let(:cf_accessor) { version_wp_custom_field.column_name }

      it "is list_optional for a version" do
        expect(instance.type)
          .to be(:list_optional)
      end
    end

    describe "date" do
      let(:cf_accessor) { date_wp_custom_field.column_name }

      it "is date for a date" do
        expect(instance.type)
          .to be(:date)
      end
    end

    describe "bool" do
      let(:cf_accessor) { bool_wp_custom_field.column_name }

      it "is list for a bool" do
        expect(instance.type)
          .to be(:list)
      end
    end

    describe "string" do
      let(:cf_accessor) { string_wp_custom_field.column_name }

      it "is string for a string" do
        expect(instance.type)
          .to be(:string)
      end
    end

    describe "link" do
      let(:cf_accessor) { link_wp_custom_field.column_name }

      it "is string for a link" do
        expect(instance.type)
          .to be(:string)
      end
    end
  end

  describe "#human_name" do
    it "is the field name" do
      expect(instance.human_name)
        .to eql(list_wp_custom_field.name)
    end
  end

  describe "#allowed_values" do
    context "integer" do
      let(:cf_accessor) { int_wp_custom_field.column_name }

      it "is nil for an integer" do
        expect(instance.allowed_values)
          .to be_nil
      end
    end

    context "float" do
      let(:cf_accessor) { float_wp_custom_field.column_name }

      it "is integer for a float" do
        expect(instance.allowed_values)
          .to be_nil
      end
    end

    context "text" do
      let(:cf_accessor) { text_wp_custom_field.column_name }

      it "is text for a text" do
        expect(instance.allowed_values)
          .to be_nil
      end
    end

    context "list" do
      let(:cf_accessor) { list_wp_custom_field.column_name }

      it "is list_optional for a list" do
        expect(instance.allowed_values)
          .to match_array(list_wp_custom_field.custom_options.map { |co| [co.value, co.id.to_s] })
      end
    end

    context "user" do
      let(:cf_accessor) { user_wp_custom_field.column_name }

      it "is list_optional for a user" do
        bogus_return_value = ["user1", "user2"]
        allow(user_wp_custom_field)
          .to receive(:possible_values_options)
          .with(project)
          .and_return(bogus_return_value)

        instance.context = project
        expect(instance.allowed_values)
          .to match_array bogus_return_value
      end
    end

    context "version" do
      let(:cf_accessor) { version_wp_custom_field.column_name }

      it "is list_optional for a version" do
        bogus_return_value = ["version1", "version2"]
        allow(version_wp_custom_field)
          .to receive(:possible_values_options)
          .with(project)
          .and_return(bogus_return_value)

        instance.context = project
        expect(instance.allowed_values)
          .to match_array bogus_return_value
      end
    end

    context "date" do
      let(:cf_accessor) { date_wp_custom_field.column_name }

      it "is nil for a date" do
        expect(instance.allowed_values)
          .to be_nil
      end
    end

    context "bool" do
      let(:cf_accessor) { bool_wp_custom_field.column_name }

      it "is list for a bool" do
        expect(instance.allowed_values)
          .to contain_exactly([I18n.t(:general_text_yes), OpenProject::Database::DB_VALUE_TRUE],
                              [I18n.t(:general_text_no), OpenProject::Database::DB_VALUE_FALSE])
      end
    end

    context "string" do
      let(:cf_accessor) { string_wp_custom_field.column_name }

      it "is nil for a string" do
        expect(instance.allowed_values)
          .to be_nil
      end
    end
  end

  describe ".all_for" do
    context "with a project" do
      before do
        filter_scope = instance_double(ActiveRecord::Relation)

        allow(WorkPackageCustomField)
          .to receive(:filter)
                .and_return(filter_scope)

        project_cf_scope = instance_double(ActiveRecord::Relation)

        allow(project)
          .to receive(:all_work_package_custom_fields)
                .and_return(project_cf_scope)

        allow(project_cf_scope)
          .to receive(:merge)
                .with(filter_scope)
                .and_return(all_custom_fields)
      end

      it "returns a list with a filter for every custom field" do
        filters = described_class.all_for(query)

        all_custom_fields.each do |cf|
          expect(filters.detect { |filter| filter.name == cf.column_name.to_sym }).not_to be_nil
        end
      end

      it "sets the project as context for every created cf filter" do
        filters = described_class.all_for(query)

        all_custom_fields.each do |cf|
          expect(filters.detect { |filter| filter.name == cf.column_name.to_sym }.context.project)
            .to eq project
        end
      end
    end

    context "without a project" do
      before do
        query.project = nil

        allow(WorkPackageCustomField)
          .to receive_message_chain(:filter, :for_all, :where, :not)
          .and_return([list_wp_custom_field,
                       bool_wp_custom_field,
                       int_wp_custom_field,
                       float_wp_custom_field,
                       text_wp_custom_field,
                       date_wp_custom_field,
                       string_wp_custom_field])
      end

      it "returns a list with a filter for every custom field" do
        filters = described_class.all_for(query)

        [list_wp_custom_field,
         bool_wp_custom_field,
         int_wp_custom_field,
         float_wp_custom_field,
         text_wp_custom_field,
         date_wp_custom_field,
         string_wp_custom_field].each do |cf|
          expect(filters.detect { |filter| filter.name == cf.column_name.to_sym }).not_to be_nil
        end

        expect(filters.detect { |filter| filter.name == version_wp_custom_field.column_name.to_sym })
          .to be_nil
        expect(filters.detect { |filter| filter.name == user_wp_custom_field.column_name.to_sym })
          .to be_nil
      end
    end
  end

  context "list cf" do
    describe "#ar_object_filter? / #value_objects" do
      let(:custom_field) { list_wp_custom_field }

      describe "#ar_object_filter?" do
        it "is true" do
          expect(instance)
            .to be_ar_object_filter
        end
      end

      describe "#value_objects" do
        before do
          instance.values = [custom_field.custom_options.last.id,
                             custom_field.custom_options.first.id]
        end

        it "returns an array with custom classes" do
          expect(instance.value_objects)
            .to contain_exactly(custom_field.custom_options.last, custom_field.custom_options.first)
        end

        it "ignores invalid values" do
          instance.values = ["invalid",
                             custom_field.custom_options.last.id]

          expect(instance.value_objects)
            .to contain_exactly(custom_field.custom_options.last)
        end
      end
    end

    context "bool cf" do
      let(:custom_field) { bool_wp_custom_field }

      it_behaves_like "non ar filter"
    end

    context "int cf" do
      let(:custom_field) { int_wp_custom_field }

      it_behaves_like "non ar filter"
    end

    context "float cf" do
      let(:custom_field) { float_wp_custom_field }

      it_behaves_like "non ar filter"
    end

    context "text cf" do
      let(:custom_field) { text_wp_custom_field }

      it_behaves_like "non ar filter"
    end

    context "user cf" do
      let(:custom_field) { user_wp_custom_field }

      describe "#ar_object_filter?" do
        it "is true" do
          expect(instance)
            .to be_ar_object_filter
        end
      end

      describe "#value_objects" do
        let(:user1) { build_stubbed(:user) }
        let(:user2) { build_stubbed(:user) }

        before do
          allow(Principal)
            .to receive(:where)
            .with(id: [user1.id.to_s, user2.id.to_s])
            .and_return([user1, user2])

          instance.values = [user1.id.to_s, user2.id.to_s]
        end

        it "returns an array with users" do
          expect(instance.value_objects)
            .to contain_exactly(user1, user2)
        end
      end
    end

    context "version cf" do
      let(:custom_field) { version_wp_custom_field }

      describe "#ar_object_filter?" do
        it "is true" do
          expect(instance)
            .to be_ar_object_filter
        end
      end

      describe "#value_objects" do
        let(:version1) { build_stubbed(:version) }
        let(:version2) { build_stubbed(:version) }

        before do
          allow(Version)
            .to receive(:where)
            .with(id: [version1.id.to_s, version2.id.to_s])
            .and_return([version1, version2])

          instance.values = [version1.id.to_s, version2.id.to_s]
        end

        it "returns an array with users" do
          expect(instance.value_objects)
            .to contain_exactly(version1, version2)
        end
      end
    end

    context "date cf" do
      let(:custom_field) { date_wp_custom_field }

      it_behaves_like "non ar filter"
    end

    context "string cf" do
      let(:custom_field) { string_wp_custom_field }

      it_behaves_like "non ar filter"
    end
  end
end
