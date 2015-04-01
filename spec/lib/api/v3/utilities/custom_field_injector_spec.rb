#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Utilities::CustomFieldInjector do
  include API::V3::Utilities::PathHelper

  let(:cf_path) { "customField#{custom_field.id}" }
  let(:field_format) { 'bool' }
  let(:custom_field) {
    FactoryGirl.build(:custom_field,
                      id: 1,
                      field_format: field_format,
                      is_required: true)
  }

  describe 'TYPE_MAP' do
    it 'supports all available formats' do
      Redmine::CustomFieldFormat.available_formats.each do |format|
        expect(described_class::TYPE_MAP[format]).not_to be_nil
      end
    end
  end

  describe '#inject_schema' do
    let(:base_class) { Class.new(::API::Decorators::Schema) }
    let(:modified_class) { described_class.create_schema_representer(schema, base_class) }
    let(:schema) {
      double('WorkPackageSchema',
             project: double(id: 42),
             defines_assignable_values?: true,
             available_custom_fields: [custom_field],
             assignable_versions: versions)
    }
    let(:versions) { [] }

    subject { modified_class.new(schema, form_embedded: true).to_json }

    describe 'basic custom field' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { cf_path }
        let(:type) { 'Boolean' }
        let(:name) { custom_field.name }
        let(:required) { true }
        let(:writable) { true }
      end

      it 'indicates no regular expression' do
        is_expected.not_to have_json_path("#{cf_path}/regularExpression")
      end

      it 'indicates no minimum size' do
        is_expected.not_to have_json_path("#{cf_path}/minLength")
      end

      it 'indicates no maximum size' do
        is_expected.not_to have_json_path("#{cf_path}/maxLength")
      end

      context 'custom field is not required' do
        let(:custom_field) { FactoryGirl.build(:custom_field, is_required: false) }

        it 'marks the field as not required' do
          is_expected.to be_json_eql(false.to_json).at_path("#{cf_path}/required")
        end
      end

      context 'custom field has regex' do
        let(:custom_field) { FactoryGirl.build(:custom_field, regexp: 'Foo+bar') }

        it 'renders the regular expression' do
          is_expected.to be_json_eql('Foo+bar'.to_json).at_path("#{cf_path}/regularExpression")
        end
      end

      context 'custom field has minimum length' do
        let(:custom_field) { FactoryGirl.build(:custom_field, min_length: 5) }

        it 'renders the minimum length' do
          is_expected.to be_json_eql(5.to_json).at_path("#{cf_path}/minLength")
        end
      end

      context 'custom field has maximum length' do
        let(:custom_field) { FactoryGirl.build(:custom_field, max_length: 5) }

        it 'renders the maximum length' do
          is_expected.to be_json_eql(5.to_json).at_path("#{cf_path}/maxLength")
        end
      end
    end

    describe 'version custom field' do
      let(:custom_field) {
        FactoryGirl.build(:custom_field,
                          field_format: 'version',
                          is_required: true)
      }
      let(:assignable_versions) { FactoryGirl.build_list(:version, 3) }

      before do
        allow(::API::V3::Versions::VersionRepresenter).to receive(:new).and_return(double)
      end

      it_behaves_like 'has basic schema properties' do
        let(:path) { cf_path }
        let(:type) { 'Version' }
        let(:name) { custom_field.name }
        let(:required) { true }
        let(:writable) { true }
      end

      it_behaves_like 'links to allowed values directly' do
        let(:path) { cf_path }
        let(:hrefs) { versions.map { |version| api_v3_paths.version version.id } }
      end

      it 'embeds allowed values' do
        # N.B. we do not use the stricter 'links to and embeds allowed values directly' helper
        # because this would not allow us to easily mock the VersionRepresenter away
        is_expected.to have_json_size(versions.size).at_path("#{cf_path}/_embedded/allowedValues")
      end
    end

    describe 'list custom field' do
      let(:custom_field) {
        FactoryGirl.build(:custom_field,
                          field_format: 'list',
                          is_required: true,
                          possible_values: values)
      }
      let(:values) { ['foo', 'bar', 'baz'] }

      it_behaves_like 'has basic schema properties' do
        let(:path) { cf_path }
        let(:type) { 'StringObject' }
        let(:name) { custom_field.name }
        let(:required) { true }
        let(:writable) { true }
      end

      it_behaves_like 'links to and embeds allowed values directly' do
        let(:path) { cf_path }
        let(:hrefs) { values.map { |value| api_v3_paths.string_object(value) } }
      end
    end

    describe 'user custom field' do
      let(:custom_field) {
        FactoryGirl.build(:custom_field,
                          field_format: 'user',
                          is_required: true)
      }

      it_behaves_like 'has basic schema properties' do
        let(:path) { cf_path }
        let(:type) { 'User' }
        let(:name) { custom_field.name }
        let(:required) { true }
        let(:writable) { true }
      end

      it_behaves_like 'links to allowed values via collection link' do
        let(:path) { cf_path }
        let(:href) { api_v3_paths.available_assignees 42 }
      end
    end
  end

  describe '#inject_value' do
    shared_examples_for 'injects property custom field' do
      it 'has a readable value' do
        is_expected.to be_json_eql(json_value.to_json).at_path(cf_path)
      end

      it 'on writing it sets on the represented' do
        expected = { custom_field.id => expected_setter }
        expect(represented).to receive(:custom_field_values=).with(expected)
        modified_class.new(represented).from_json({ cf_path => json_value }.to_json)
      end
    end

    let(:base_class) { Class.new(::API::Decorators::Single) }
    let(:modified_class) { described_class.create_value_representer(represented, base_class) }
    let(:represented) {
      double('represented',
             available_custom_fields: [custom_field],
             custom_field.accessor_name => value)
    }
    let(:custom_value) { double('CustomValue', value: raw_value) }
    let(:raw_value) { nil }
    let(:value) { '' }
    let(:current_user) { FactoryGirl.build(:user) }
    subject { modified_class.new(represented, current_user: current_user).to_json }

    before do
      # should only be called when building links
      allow(represented).to receive(:custom_value_for).with(custom_field).and_return(custom_value)
    end

    context 'user custom field' do
      let(:value) { FactoryGirl.build(:user, id: 2) }
      let(:raw_value) { value.id.to_s }
      let(:field_format) { 'user' }

      it_behaves_like 'has an untitled link' do
        let(:link) { cf_path }
        let(:href) { api_v3_paths.user 2 }
      end

      it 'has the user embedded' do
        is_expected.to be_json_eql('User'.to_json).at_path("_embedded/#{cf_path}/_type")
        is_expected.to be_json_eql(value.name.to_json).at_path("_embedded/#{cf_path}/name")
      end

      context 'value is nil' do
        let(:value) { nil }
        let(:raw_value) { '' }

        it_behaves_like 'has an empty link' do
          let(:link) { cf_path }
        end
      end
    end

    context 'version custom field' do
      let(:value) { FactoryGirl.build(:version, id: 2) }
      let(:raw_value) { value.id.to_s }
      let(:field_format) { 'version' }

      it_behaves_like 'has an untitled link' do
        let(:link) { cf_path }
        let(:href) { api_v3_paths.version 2 }
      end

      it 'has the version embedded' do
        is_expected.to be_json_eql('Version'.to_json).at_path("_embedded/#{cf_path}/_type")
        is_expected.to be_json_eql(value.name.to_json).at_path("_embedded/#{cf_path}/name")
      end

      context 'value is nil' do
        let(:value) { nil }
        let(:raw_value) { '' }

        it_behaves_like 'has an empty link' do
          let(:link) { cf_path }
        end
      end
    end

    context 'list custom field' do
      let(:value) { 'Foobar' }
      let(:raw_value) { value }
      let(:field_format) { 'list' }

      it_behaves_like 'has an untitled link' do
        let(:link) { cf_path }
        let(:href) { api_v3_paths.string_object 'Foobar' }
      end

      it 'has the string object embedded' do
        is_expected.to be_json_eql('StringObject'.to_json).at_path("_embedded/#{cf_path}/_type")
        is_expected.to be_json_eql(value.to_json).at_path("_embedded/#{cf_path}/value")
      end

      context 'value is nil' do
        let(:value) { nil }

        it_behaves_like 'has an empty link' do
          let(:link) { cf_path }
        end
      end
    end

    context 'string custom field' do
      it_behaves_like 'injects property custom field' do
        let(:field_format) { 'string' }
        let(:value) { 'Foobar' }
        let(:json_value) { 'Foobar' }
        let(:expected_setter) { json_value }
      end
    end

    context 'int custom field' do
      it_behaves_like 'injects property custom field' do
        let(:field_format) { 'int' }
        let(:value) { 42 }
        let(:json_value) { 42 }
        let(:expected_setter) { json_value }
      end
    end

    context 'float custom field' do
      it_behaves_like 'injects property custom field' do
        let(:field_format) { 'float' }
        let(:value) { 3.14 }
        let(:json_value) { 3.14 }
        let(:expected_setter) { json_value }
      end
    end

    context 'bool custom field' do
      it_behaves_like 'injects property custom field' do
        let(:field_format) { 'bool' }
        let(:value) { true }
        let(:json_value) { true }
        let(:expected_setter) { json_value }
      end
    end

    context 'date custom field' do
      it_behaves_like 'injects property custom field' do
        let(:field_format) { 'date' }
        let(:value) { Date.today.to_date }
        let(:json_value) { value.to_date.iso8601 }
        let(:expected_setter) { json_value }
      end
    end

    context 'text custom field' do
      it_behaves_like 'injects property custom field' do
        let(:field_format) { 'text' }
        let(:value) { 'Foobar' }
        let(:json_value) do
          {
            format: 'plain',
            raw: value,
            html: "<p>#{value}</p>"
          }
        end
        let(:expected_setter) { value }
      end
    end
  end

  describe '#inject_patchable_link_value' do
    let(:base_class) { Class.new(::API::Decorators::Single) }
    let(:modified_class) {
      described_class.create_value_representer_for_link_patching(represented, base_class)
    }
    let(:represented) {
      double('represented',
             available_custom_fields: [custom_field])
    }
    let(:custom_value) { double('CustomValue', value: value) }
    let(:value) { '' }
    subject { "{ \"_links\": #{modified_class.new(represented).to_json} }" }

    before do
      allow(represented).to receive(:custom_value_for).with(custom_field).and_return(custom_value)
    end

    context 'reading' do
      let(:value) { '2' }
      let(:field_format) { 'user' }

      it_behaves_like 'has an untitled link' do
        let(:link) { cf_path }
        let(:href) { api_v3_paths.user 2 }
      end

      context 'value is nil' do
        let(:value) { nil }

        it_behaves_like 'has an empty link' do
          let(:link) { cf_path }
        end
      end
    end

    context 'writing' do
      let(:value) { nil }
      let(:field_format) { 'user' }

      it 'accepts a valid link' do
        json = { cf_path => { href: (api_v3_paths.user 2) } }.to_json
        expected = { custom_field.id => '2' }

        expect(represented).to receive(:custom_field_values=).with(expected)
        modified_class.new(represented).from_json(json)
      end

      it 'accepts an empty link' do
        json = { cf_path => { href: nil } }.to_json
        expected = { custom_field.id => nil }

        expect(represented).to receive(:custom_field_values=).with(expected)
        modified_class.new(represented).from_json(json)
      end
    end
  end
end
