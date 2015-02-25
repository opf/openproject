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
  let(:cf_path) { "customField#{custom_field.id}" }
  let(:injector) { described_class.new(modified_class) }
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
        expect(described_class::TYPE_MAP[format]).to_not be_nil
      end
    end
  end

  describe '#inject_schema' do
    let(:modified_class) { Class.new(::API::Decorators::Schema) }
    let(:schema) { nil }
    subject { modified_class.new(schema).to_json }

    before do
      injector.inject_schema(custom_field, wp_schema: schema)
    end

    describe 'basic custom field' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { cf_path }
        let(:type) { 'Boolean' }
        let(:name) { custom_field.name }
        let(:required) { true }
        let(:writable) { true }
      end

      context 'when the custom field is not required' do
        let(:custom_field) { FactoryGirl.build(:custom_field, is_required: false) }

        it 'marks the field as not required' do
          is_expected.to be_json_eql(false.to_json).at_path("#{cf_path}/required")
        end
      end
    end

    describe 'version custom field' do
      let(:schema) {
        double('WorkPackageSchema',
               defines_assignable_values?: true,
               assignable_versions: versions)
      }
      let(:custom_field) {
        FactoryGirl.build(:custom_field,
                          field_format: 'version',
                          is_required: true)
      }
      let(:versions) { FactoryGirl.build_list(:version, 3) }

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
        let(:hrefs) { versions.map { |version| "/api/v3/versions/#{version.id}" } }
      end

      it 'embeds allowed values' do
        # N.B. we do not use the stricter 'links to and embeds allowed values directly' helper
        # because this would not allow us to easily mock the VersionRepresenter away
        is_expected.to have_json_size(versions.size).at_path("#{cf_path}/_embedded/allowedValues")
      end
    end

    describe 'list custom field' do
      let(:schema) {
        double('WorkPackageSchema',
               defines_assignable_values?: true)
      }
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
        let(:hrefs) { values.map { |value| "/api/v3/string_objects/#{value}" } }
      end
    end

    describe 'user custom field' do
      let(:schema) {
        double('WorkPackageSchema',
               defines_assignable_values?: true,
               project: double(id: 42))
      }
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
        let(:href) { '/api/v3/projects/42/available_assignees' }
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

    let(:represented) {
      double('represented',
             custom_value_for: double('custom_value',
                                      typed_value: custom_value))
    }
    let(:custom_value) { '' }
    let(:modified_class) { Class.new(::API::Decorators::Single) }
    subject { modified_class.new(represented).to_json }

    before do
      injector.inject_value(custom_field)
    end

    context 'link custom field' do
      let(:custom_value) { FactoryGirl.build(:user, id: 2) }
      let(:field_format) { 'user' }

      it_behaves_like 'has an untitled link' do
        let(:link) { cf_path }
        let(:href) { '/api/v3/users/2' }
      end

      context 'value is nil' do
        let(:represented) { double('represented', custom_value_for: nil) }

        it_behaves_like 'has an empty link' do
          let(:link) { cf_path }
        end
      end
    end

    context 'string custom field' do
      it_behaves_like 'injects property custom field' do
        let(:field_format) { 'string' }
        let(:custom_value) { 'Foobar' }
        let(:json_value) { 'Foobar' }
        let(:expected_setter) { json_value }
      end
    end

    context 'int custom field' do
      it_behaves_like 'injects property custom field' do
        let(:field_format) { 'int' }
        let(:custom_value) { 42 }
        let(:json_value) { 42 }
        let(:expected_setter) { json_value }
      end
    end

    context 'float custom field' do
      it_behaves_like 'injects property custom field' do
        let(:field_format) { 'float' }
        let(:custom_value) { 3.14 }
        let(:json_value) { 3.14 }
        let(:expected_setter) { json_value }
      end
    end

    context 'bool custom field' do
      it_behaves_like 'injects property custom field' do
        let(:field_format) { 'bool' }
        let(:custom_value) { true }
        let(:json_value) { true }
        let(:expected_setter) { json_value }
      end
    end

    context 'date custom field' do
      it_behaves_like 'injects property custom field' do
        let(:field_format) { 'date' }
        let(:custom_value) { Date.today.to_date }
        let(:json_value) { custom_value.to_date.iso8601 }
        let(:expected_setter) { json_value }
      end
    end

    context 'text custom field' do
      it_behaves_like 'injects property custom field' do
        let(:field_format) { 'text' }
        let(:custom_value) { 'Foobar' }
        let(:json_value) do
          {
            format: 'plain',
            raw: custom_value,
            html: "<p>#{custom_value}</p>"
          }
        end
        let(:expected_setter) { custom_value }
      end
    end
  end

  describe '#inject_patchable_link_value' do
    let(:represented) {
      double('represented',
             custom_value_for: double('custom_value',
                                      typed_value: custom_value))
    }
    let(:custom_value) { '' }
    let(:modified_class) { Class.new(::API::Decorators::Single) }
    subject { "{ \"_links\": #{modified_class.new(represented).to_json} }" }

    before do
      injector.inject_patchable_link_value(custom_field)
    end

    context 'reading' do
      let(:custom_value) { FactoryGirl.build(:user, id: 2) }
      let(:field_format) { 'user' }

      it_behaves_like 'has an untitled link' do
        let(:link) { cf_path }
        let(:href) { '/api/v3/users/2' }
      end

      context 'value is nil' do
        let(:represented) { double('represented', custom_value_for: nil) }

        it_behaves_like 'has an empty link' do
          let(:link) { cf_path }
        end
      end
    end

    context 'writing' do
      let(:custom_value) { nil }
      let(:field_format) { 'user' }

      it 'accepts a valid link' do
        json = { cf_path => { href: '/api/v3/users/2' } }.to_json
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
