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

RSpec.describe API::V3::Utilities::CustomFieldInjector do
  include API::V3::Utilities::PathHelper

  let(:cf_path) { custom_field.attribute_name(:camel_case) }
  let(:field_format) { "bool" }
  let(:custom_field) do
    build(:custom_field,
          id: 1,
          field_format:,
          is_required: true)
  end

  describe "TYPE_MAP" do
    it "supports all available formats" do
      OpenProject::CustomFieldFormat.available_formats.each do |format|
        expect(described_class::TYPE_MAP[format]).not_to be_nil
      end
    end
  end

  describe "#inject_schema" do
    let(:base_class) { Class.new(API::Decorators::SchemaRepresenter) }
    let(:modified_class) { described_class.create_schema_representer([custom_field], base_class) }
    let(:schema_writable) { true }
    let(:model) { build_stubbed(:work_package) }
    let(:schema) do
      instance_double(API::V3::WorkPackages::Schema::SpecificWorkPackageSchema,
                      project_id: 42,
                      model:,
                      available_custom_fields: [custom_field],
                      writable?: schema_writable)
    end

    subject { modified_class.new(schema, current_user: nil, form_embedded: true).to_json }

    describe "basic custom field" do
      let(:path) { cf_path }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Boolean" }
        let(:name) { custom_field.name }
        let(:required) { true }
        let(:writable) { true }
        let(:has_default) { false }
      end

      context "with schema not writable" do
        let(:schema_writable) { false }

        it_behaves_like "has basic schema properties" do
          let(:type) { "Boolean" }
          let(:name) { custom_field.name }
          let(:required) { true }
          let(:writable) { false }
          let(:has_default) { false }
        end
      end

      context "with default set" do
        let(:custom_field) do
          build(:custom_field,
                id: 1,
                field_format: "string",
                default_value: "foo",
                is_required: true)
        end

        it_behaves_like "has basic schema properties" do
          let(:type) { "String" }
          let(:name) { custom_field.name }
          let(:required) { true }
          let(:writable) { true }
          let(:has_default) { true }
        end
      end

      it "indicates no regular expression" do
        expect(subject).not_to have_json_path("#{cf_path}/regularExpression")
      end

      # meaning they won't as no values are specified
      it_behaves_like "indicates length requirements"

      context "when custom field is not required" do
        let(:custom_field) { build(:custom_field, is_required: false) }

        it "marks the field as not required" do
          expect(subject).to be_json_eql(false.to_json).at_path("#{cf_path}/required")
        end
      end

      context "when custom field has regex" do
        let(:custom_field) { build(:custom_field, regexp: "Foo+bar") }

        it "renders the regular expression" do
          expect(subject).to be_json_eql("Foo+bar".to_json).at_path("#{cf_path}/regularExpression")
        end
      end

      context "when custom field has minimum length" do
        let(:custom_field) { build(:custom_field, min_length: 5) }

        it_behaves_like "indicates length requirements" do
          let(:min_length) { 5 }
        end
      end

      context "when custom field has maximum length" do
        let(:custom_field) { build(:custom_field, max_length: 5) }

        it_behaves_like "indicates length requirements" do
          let(:max_length) { 5 }
        end
      end
    end

    describe "version custom field" do
      let(:custom_field) do
        build(:version_wp_custom_field,
              is_required: true)
      end

      let(:assignable_versions) { build_list(:version, 3) }

      before do
        allow(schema)
          .to receive(:assignable_custom_field_values)
          .with(custom_field)
          .and_return(assignable_versions)

        allow(API::V3::Versions::VersionRepresenter).to receive(:create).and_return(double)
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { cf_path }
        let(:type) { "Version" }
        let(:name) { custom_field.name }
        let(:required) { true }
        let(:writable) { true }
        let(:location) { "_links" }
      end

      context "with schema not writable" do
        let(:schema_writable) { false }

        it_behaves_like "has basic schema properties" do
          let(:path) { cf_path }
          let(:type) { "Version" }
          let(:name) { custom_field.name }
          let(:required) { true }
          let(:writable) { false }
          let(:location) { "_links" }
        end
      end

      it_behaves_like "links to allowed values directly" do
        let(:path) { cf_path }
        let(:hrefs) { assignable_versions.map { |version| api_v3_paths.version version.id } }
      end

      it "embeds allowed values" do
        # N.B. we do not use the stricter 'links to and embeds allowed values directly' helper
        # because this would not allow us to easily mock the VersionRepresenter away
        expect(subject)
          .to have_json_size(assignable_versions.size)
          .at_path("#{cf_path}/_embedded/allowedValues")
      end
    end

    describe "list custom field" do
      before do
        allow(schema)
          .to receive(:assignable_custom_field_values)
          .with(custom_field)
          .and_return(custom_field.possible_values)
      end

      let(:custom_field) do
        create(
          :list_wp_custom_field,
          is_required: true,
          possible_values: values
        )
      end

      let(:values) { ["foo", "bar", "baz"] }

      it_behaves_like "has basic schema properties" do
        let(:path) { cf_path }
        let(:type) { "CustomOption" }
        let(:name) { custom_field.name }
        let(:required) { true }
        let(:writable) { true }
        let(:location) { "_links" }
      end

      context "with schema not writable" do
        let(:schema_writable) { false }

        it_behaves_like "has basic schema properties" do
          let(:path) { cf_path }
          let(:type) { "CustomOption" }
          let(:name) { custom_field.name }
          let(:required) { true }
          let(:writable) { false }
          let(:location) { "_links" }
        end
      end

      it_behaves_like "links to and embeds allowed values directly" do
        let(:path) { cf_path }
        let(:hrefs) do
          custom_field.possible_values.map do |value|
            api_v3_paths.custom_option(value.id)
          end
        end
      end
    end

    describe "user custom field" do
      let(:custom_field) do
        build(:custom_field,
              field_format: "user",
              is_required: true)
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { cf_path }
        let(:type) { "User" }
        let(:name) { custom_field.name }
        let(:required) { true }
        let(:writable) { true }
        let(:location) { "_links" }
      end

      context "with schema not writable" do
        let(:schema_writable) { false }

        it_behaves_like "has basic schema properties" do
          let(:path) { cf_path }
          let(:type) { "User" }
          let(:name) { custom_field.name }
          let(:required) { true }
          let(:writable) { false }
          let(:location) { "_links" }
        end
      end

      it_behaves_like "links to allowed values via collection link" do
        let(:path) { cf_path }
        let(:href) do
          params = [
            { status: { operator: "!", values: [Principal.statuses[:locked].to_s] } },
            { type: { operator: "=", values: %w[User Group PlaceholderUser] } },
            { member: { operator: "=", values: [schema.project_id.to_s] } }
          ]

          query = CGI.escape(JSON.dump(params))

          "#{api_v3_paths.principals}?filters=#{query}&pageSize=-1"
        end
      end
    end

    describe "user custom field on new project" do
      let(:schema) do
        instance_double(API::V3::WorkPackages::Schema::SpecificWorkPackageSchema,
                        id: nil,
                        model: Project.new,
                        available_custom_fields: [custom_field])
      end
      let(:custom_field) do
        build(:custom_field,
              field_format: "user",
              is_required: true)
      end

      it_behaves_like "links to allowed values via collection link" do
        let(:path) { cf_path }
        let(:href) do
          params = [
            { status: { operator: "!", values: [Principal.statuses[:locked].to_s] } },
            { type: { operator: "=", values: %w[User Group PlaceholderUser] } },
            { member: { operator: "*", values: [] } }
          ]

          query = CGI.escape(JSON.dump(params))

          "#{api_v3_paths.principals}?filters=#{query}&pageSize=-1"
        end
      end
    end
  end

  describe "#inject_value" do
    shared_examples_for "injects property custom field" do
      it "has a readable value" do
        expect(subject).to be_json_eql(json_value.to_json).at_path(cf_path)
      end

      it "on writing it sets on the represented" do
        allow(represented).to receive(custom_field.attribute_setter)
        modified_class
          .new(represented, current_user: nil)
          .from_json({ cf_path => json_value }.to_json)

        expect(represented)
          .to have_received(custom_field.attribute_setter)
          .with(expected_setter)
      end
    end

    let(:base_class) do
      Class.new(API::Decorators::Single) do
        def self.custom_field_injector_config
          {}
        end
      end
    end
    let(:modified_class) { described_class.create_value_representer([custom_field], base_class) }
    let(:represented) do
      double("represented",
             available_custom_fields: [custom_field],
             custom_field.attribute_name => value)
    end
    let(:custom_value) { instance_double(CustomValue, value: raw_value, typed_value:) }
    let(:raw_value) { nil }
    let(:typed_value) { raw_value }
    let(:value) { "" }
    let(:current_user) { build(:user) }

    subject { modified_class.new(represented, current_user:, embed_links: true).to_json }

    before do
      # should only be called when building links
      allow(represented).to receive(:custom_value_for).with(custom_field).and_return(custom_value)
    end

    context "for user custom field" do
      let(:raw_value) { value.id.to_s }
      let(:typed_value) { value }
      let(:field_format) { "user" }

      %w[user group placeholder_user].each do |type|
        describe "#{type} assignment" do
          let(:value) { build(type, id: 2) }

          it_behaves_like "has a titled link" do
            let(:link) { cf_path }
            let(:href) { api_v3_paths.send type, 2 }
            let(:title) { value.name }
          end

          it "has the user embedded" do
            expect(subject).to be_json_eql(type.classify.to_json).at_path("_embedded/#{cf_path}/_type")
            expect(subject).to be_json_eql(value.name.to_json).at_path("_embedded/#{cf_path}/name")
          end
        end
      end

      context "when value is nil" do
        let(:value) { nil }
        let(:raw_value) { "" }

        it_behaves_like "has an empty link" do
          let(:link) { cf_path }
        end
      end
    end

    context "for version custom field" do
      let(:value) { build_stubbed(:version, id: 2) }
      let(:raw_value) { value.id.to_s }
      let(:typed_value) { value }
      let(:field_format) { "version" }

      it_behaves_like "has a titled link" do
        let(:link) { cf_path }
        let(:href) { api_v3_paths.version 2 }
        let(:title) { value.name }
      end

      it "has the version embedded" do
        expect(subject).to be_json_eql("Version".to_json).at_path("_embedded/#{cf_path}/_type")
        expect(subject).to be_json_eql(value.name.to_json).at_path("_embedded/#{cf_path}/name")
      end

      context "when value is nil" do
        let(:value) { nil }
        let(:raw_value) { "" }

        it_behaves_like "has an empty link" do
          let(:link) { cf_path }
        end
      end
    end

    context "for list custom field" do
      let(:value) { build_stubbed(:custom_option) }
      let(:typed_value) { value.value }
      let(:raw_value) { value.id.to_s }
      let(:field_format) { "list" }

      it_behaves_like "has a titled link" do
        let(:link) { cf_path }
        let(:href) { api_v3_paths.custom_option(value.id) }
        let(:title) { value.value }
      end

      context "when value is nil" do
        let(:value) { nil }
        let(:raw_value) { "" }
        let(:typed_value) { "" }

        it_behaves_like "has an empty link" do
          let(:link) { cf_path }
        end
      end

      context "when value is some invalid string" do
        let(:value) { "some invalid string" }
        let(:raw_value) { "some invalid string" }
        let(:typed_value) { "some invalid string not found" }

        it "has an empty href" do
          expect(subject)
            .to be_json_eql(nil.to_json)
            .at_path("_links/#{cf_path}/href")
        end

        it "has the invalid value as title" do
          expect(subject)
            .to be_json_eql(typed_value.to_json)
            .at_path("_links/#{cf_path}/title")
        end
      end
    end

    context "for string custom field" do
      it_behaves_like "injects property custom field" do
        let(:field_format) { "string" }
        let(:value) { "Foobar" }
        let(:json_value) { "Foobar" }
        let(:expected_setter) { json_value }
      end
    end

    context "for int custom field" do
      it_behaves_like "injects property custom field" do
        let(:field_format) { "int" }
        let(:value) { 42 }
        let(:json_value) { 42 }
        let(:expected_setter) { json_value }
      end
    end

    context "for float custom field" do
      it_behaves_like "injects property custom field" do
        let(:field_format) { "float" }
        let(:value) { 3.14 }
        let(:json_value) { 3.14 }
        let(:expected_setter) { json_value }
      end
    end

    context "for bool custom field" do
      it_behaves_like "injects property custom field" do
        let(:field_format) { "bool" }
        let(:value) { true }
        let(:json_value) { true }
        let(:expected_setter) { json_value }
      end
    end

    context "for date custom field" do
      it_behaves_like "injects property custom field" do
        let(:field_format) { "date" }
        let(:value) { Date.current }
        let(:json_value) { value.to_date.iso8601 }
        let(:expected_setter) { json_value }
      end
    end

    context "for text custom field" do
      it_behaves_like "injects property custom field" do
        let(:field_format) { "text" }
        let(:value) { "**Foobar**" }
        let(:json_value) do
          {
            format: "markdown",
            raw: value,
            html: '<p class="op-uc-p"><strong>Foobar</strong></p>'
          }
        end
        let(:expected_setter) { value }
      end
    end
  end

  describe "#inject_patchable_link_value" do
    let(:base_class) do
      Class.new(API::Decorators::Single) do
        def self.custom_field_injector_config
          {}
        end
      end
    end
    let(:modified_class) do
      described_class.create_value_representer([custom_field], base_class)
    end
    let(:represented) do
      double("represented", available_custom_fields: [custom_field])
    end
    let(:custom_value) { instance_double(CustomValue, value:, typed_value:) }
    let(:value) { "" }
    let(:user) { build_stubbed(:user) }
    let(:typed_value) { value }

    subject { modified_class.new(represented, current_user: user).to_json }

    before do
      allow(represented).to receive(:custom_value_for).with(custom_field).and_return(custom_value)
      allow(represented).to receive(custom_field.attribute_getter).and_return(typed_value)
    end

    context "for reading" do
      let(:value) { "2" }
      let(:field_format) { "user" }

      %w[user group placeholder_user].each do |type|
        describe "#{type} reading" do
          let(:typed_value) { build(type, id: 2) }

          it_behaves_like "has a titled link" do
            let(:link) { cf_path }
            let(:href) { api_v3_paths.send type, 2 }
            let(:title) { typed_value.name }
          end
        end
      end

      context "when value is nil" do
        let(:value) { nil }
        let(:typed_value) { nil }

        it_behaves_like "has an empty link" do
          let(:link) { cf_path }
        end
      end
    end

    context "for writing" do
      let(:value) { nil }
      let(:field_format) { "user" }

      %w[user group placeholder_user].each do |type|
        it "accepts a valid link of type #{type}" do
          path = api_v3_paths.send type, 2
          json = { cf_path => { href: path } }.to_json
          expected = ["2"]

          allow(represented).to receive(custom_field.attribute_setter)
          modified_class.new(represented, current_user: nil).from_json(json)

          expect(represented).to have_received(custom_field.attribute_setter).with(expected)
        end
      end

      it "accepts an empty link" do
        json = { cf_path => { href: nil } }.to_json
        expected = []

        allow(represented).to receive(custom_field.attribute_setter)
        modified_class.new(represented, current_user: nil).from_json(json)

        expect(represented).to have_received(custom_field.attribute_setter).with(expected)
      end
    end
  end
end
