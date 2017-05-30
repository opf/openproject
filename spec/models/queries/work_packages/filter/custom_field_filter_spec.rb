#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe Queries::WorkPackages::Filter::CustomFieldFilter, type: :model do
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:query) { FactoryGirl.build_stubbed(:query, project: project) }
  let(:instance) do
    filter = described_class.new
    filter.name = "cf_#{custom_field.id}"
    filter.operator = '='
    filter.context = query
    filter
  end
  let(:instance_key) { nil }
  let(:name) { field.name }

  let(:list_wp_custom_field) { FactoryGirl.create(:list_wp_custom_field) }
  let(:bool_wp_custom_field) { FactoryGirl.build_stubbed(:bool_wp_custom_field) }
  let(:int_wp_custom_field) { FactoryGirl.build_stubbed(:int_wp_custom_field) }
  let(:float_wp_custom_field) { FactoryGirl.build_stubbed(:float_wp_custom_field) }
  let(:text_wp_custom_field) { FactoryGirl.build_stubbed(:text_wp_custom_field) }
  let(:user_wp_custom_field) { FactoryGirl.build_stubbed(:user_wp_custom_field) }
  let(:version_wp_custom_field) { FactoryGirl.build_stubbed(:version_wp_custom_field) }
  let(:date_wp_custom_field) { FactoryGirl.build_stubbed(:date_wp_custom_field) }
  let(:string_wp_custom_field) { FactoryGirl.build_stubbed(:string_wp_custom_field) }
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
     string_wp_custom_field]
  end

  before do
    all_custom_fields.each do |cf|
      allow(WorkPackageCustomField)
        .to receive(:find_by_id)
        .with(cf.id)
        .and_return(cf)
    end
  end

  describe '.valid?' do
    let(:custom_field) { string_wp_custom_field }
    before do
      instance.values = ['bogus']
    end

    before do
      if project
        allow(project)
          .to receive_message_chain(:all_work_package_custom_fields, :map, :include?)
          .and_return(true)
      else
        allow(WorkPackageCustomField)
          .to receive_message_chain(:filter, :for_all, :where, :not, :exists?)
          .and_return(true)
      end
    end

    it 'is invalid without a custom field' do
      allow(WorkPackageCustomField)
        .to receive(:find_by_id)
        .with(100)
        .and_return(nil)

      instance.name = 'cf_100'

      expect(instance).to_not be_valid
    end

    shared_examples_for 'custom field type dependent validity' do
      context 'with a string custom field' do
        it 'is valid' do
          expect(instance).to be_valid
        end
      end

      context 'with a list custom field' do
        let(:custom_field) { list_wp_custom_field }

        before do
          instance.values = [list_wp_custom_field.possible_values.first.id]
        end

        it 'is valid' do
          expect(instance).to be_valid
        end

        it "is invalid if the value is not one of the custom field's possible values" do
          instance.values = ['bogus']

          expect(instance).to_not be_valid
        end
      end
    end

    context 'within a project' do
      it 'is invalid with a custom field not active in the project' do
        scope = double('AR::Scope')
        allow(project)
          .to receive(:all_work_package_custom_fields)
          .and_return(scope)

        allow(scope)
          .to receive(:map)
          .and_return(scope)

        allow(scope)
          .to receive(:include?)
          .with(instance.custom_field.id)
          .and_return(false)

        expect(instance).to_not be_valid
      end

      it_behaves_like 'custom field type dependent validity'
    end

    context 'without a project' do
      let(:project) { nil }

      it 'is invalid with a custom field not valid as a global filter' do
        scope = double('AR::Scope')
        allow(WorkPackageCustomField)
          .to receive(:filter)
          .and_return(scope)

        allow(scope)
          .to receive(:for_all)
          .and_return(scope)

        allow(scope)
          .to receive(:where)
          .and_return(scope)

        allow(scope)
          .to receive(:not)
          .with(field_format: ['user', 'version'])
          .and_return(scope)

        allow(scope)
          .to receive(:exists?)
          .with(instance.custom_field.id)
          .and_return(false)

        expect(instance).to_not be_valid
      end

      it_behaves_like 'custom field type dependent validity'
    end
  end

  describe '.key' do
    it 'is a regular expression' do
      expect(described_class.key).to eql(/cf_(\d+)/)
    end
  end

  describe '#name' do
    it 'is the custom fields id prefixed with cf_' do
      all_custom_fields.each do |cf|
        filter = described_class.new
        filter.name = "cf_#{cf.id}"
        expect(filter.name).to eql(:"cf_#{cf.id}")
      end
    end
  end

  describe '#order' do
    it 'is 20' do
      all_custom_fields.each do |cf|
        filter = described_class.new
        filter.name = "cf_#{cf.id}"
        expect(filter.order).to eql(20)
      end
    end
  end

  describe '#type' do
    it 'is integer for an integer' do
      instance.name = "cf_#{int_wp_custom_field.id}"
      expect(instance.type)
        .to eql(:integer)
    end

    it 'is integer for a float' do
      instance.name = "cf_#{float_wp_custom_field.id}"
      expect(instance.type)
        .to eql(:integer)
    end

    it 'is text for a text' do
      instance.name = "cf_#{text_wp_custom_field.id}"
      expect(instance.type)
        .to eql(:text)
    end

    it 'is list_optional for a list' do
      instance.name = "cf_#{list_wp_custom_field.id}"
      expect(instance.type)
        .to eql(:list_optional)
    end

    it 'is list_optional for a user' do
      instance.name = "cf_#{user_wp_custom_field.id}"
      expect(instance.type)
        .to eql(:list_optional)
    end

    it 'is list_optional for a version' do
      instance.name = "cf_#{version_wp_custom_field.id}"
      expect(instance.type)
        .to eql(:list_optional)
    end

    it 'is date for a date' do
      instance.name = "cf_#{date_wp_custom_field.id}"
      expect(instance.type)
        .to eql(:date)
    end

    it 'is list for a bool' do
      instance.name = "cf_#{bool_wp_custom_field.id}"
      expect(instance.type)
        .to eql(:list)
    end

    it 'is string for a string' do
      instance.name = "cf_#{string_wp_custom_field.id}"
      expect(instance.type)
        .to eql(:string)
    end
  end

  describe '#human_name' do
    it 'is the field name' do
      expect(instance.human_name)
        .to eql(list_wp_custom_field.name)
    end
  end

  describe '#allowed_values' do
    it 'is nil for an integer' do
      instance.name = "cf_#{int_wp_custom_field.id}"
      expect(instance.allowed_values)
        .to be_nil
    end

    it 'is integer for a float' do
      instance.name = "cf_#{float_wp_custom_field.id}"
      expect(instance.allowed_values)
        .to be_nil
    end

    it 'is text for a text' do
      instance.name = "cf_#{text_wp_custom_field.id}"
      expect(instance.allowed_values)
        .to be_nil
    end

    it 'is list_optional for a list' do
      instance.name = "cf_#{list_wp_custom_field.id}"
      expect(instance.allowed_values)
        .to match_array(list_wp_custom_field.custom_options.map { |co| [co.value, co.id.to_s] })
    end

    it 'is list_optional for a user' do
      bogus_return_value = ['user1', 'user2']
      allow(user_wp_custom_field)
        .to receive(:possible_values_options)
        .with(project)
        .and_return(bogus_return_value)

      instance.context = project
      instance.name = "cf_#{user_wp_custom_field.id}"
      expect(instance.allowed_values)
        .to match_array bogus_return_value
    end

    it 'is list_optional for a version' do
      bogus_return_value = ['version1', 'version2']
      allow(version_wp_custom_field)
        .to receive(:possible_values_options)
        .with(project)
        .and_return(bogus_return_value)

      instance.context = project
      instance.name = "cf_#{version_wp_custom_field.id}"
      expect(instance.allowed_values)
        .to match_array bogus_return_value
    end

    it 'is nil for a date' do
      instance.name = "cf_#{date_wp_custom_field.id}"
      expect(instance.allowed_values)
        .to be_nil
    end

    it 'is list for a bool' do
      instance.name = "cf_#{bool_wp_custom_field.id}"
      expect(instance.allowed_values)
        .to match_array [[I18n.t(:general_text_yes), CustomValue::BoolStrategy::DB_VALUE_TRUE],
                         [I18n.t(:general_text_no), CustomValue::BoolStrategy::DB_VALUE_FALSE]]
    end

    it 'is nil for a string' do
      instance.name = "cf_#{string_wp_custom_field.id}"
      expect(instance.allowed_values)
        .to be_nil
    end
  end

  describe '#available?' do
    context 'for an existing custom field' do
      it 'is true' do
        instance.custom_field = list_wp_custom_field
        expect(instance).to be_available
      end
    end

    context 'for a non existing custom field (deleted)' do
      it 'is false' do
        instance.custom_field = nil
        expect(instance).not_to be_available
      end
    end
  end

  describe '.all_for' do
    context 'within a project' do
      before do
        allow(project)
          .to receive_message_chain(:all_work_package_custom_fields)
          .and_return(all_custom_fields)
      end

      it 'returns a list with a filter for every custom field' do
        filters = described_class.all_for(project)

        all_custom_fields.each do |cf|
          expect(filters.detect { |filter| filter.name == :"cf_#{cf.id}" }).to_not be_nil
        end
      end
    end

    context 'without a project' do
      before do
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

      it 'returns a list with a filter for every custom field' do
        filters = described_class.all_for

        [list_wp_custom_field,
         bool_wp_custom_field,
         int_wp_custom_field,
         float_wp_custom_field,
         text_wp_custom_field,
         date_wp_custom_field,
         string_wp_custom_field].each do |cf|
          expect(filters.detect { |filter| filter.name == :"cf_#{cf.id}" }).to_not be_nil
        end

        expect(filters.detect { |filter| filter.name == :"cf_#{version_wp_custom_field.id}" })
          .to be_nil
        expect(filters.detect { |filter| filter.name == :"cf_#{user_wp_custom_field.id}" })
          .to be_nil
      end
    end
  end

  context 'list cf' do
    describe '#ar_object_filter? / #value_objects' do
      let(:custom_field) { list_wp_custom_field }

      describe '#ar_object_filter?' do
        it 'is true' do
          expect(instance)
            .to be_ar_object_filter
        end
      end

      describe '#value_objects' do
        before do
          instance.values = [custom_field.custom_options.last.id,
                             custom_field.custom_options.first.id]
        end

        it 'returns an array with custom classes' do
          expect(instance.value_objects)
            .to match_array([custom_field.custom_options.last,
                             custom_field.custom_options.first])
        end

        it 'ignores invalid values' do
          instance.values = ['invalid',
                             custom_field.custom_options.last.id]

          expect(instance.value_objects)
            .to match_array([custom_field.custom_options.last])
        end
      end
    end

    context 'bool cf' do
      let(:custom_field) { bool_wp_custom_field }

      it_behaves_like 'non ar filter'
    end

    context 'int cf' do
      let(:custom_field) { int_wp_custom_field }

      it_behaves_like 'non ar filter'
    end

    context 'float cf' do
      let(:custom_field) { float_wp_custom_field }

      it_behaves_like 'non ar filter'
    end

    context 'text cf' do
      let(:custom_field) { text_wp_custom_field }

      it_behaves_like 'non ar filter'
    end

    context 'user cf' do
      let(:custom_field) { user_wp_custom_field }

      describe '#ar_object_filter?' do
        it 'is true' do
          expect(instance)
            .to be_ar_object_filter
        end
      end

      describe '#value_objects' do
        let(:user1) { FactoryGirl.build_stubbed(:user) }
        let(:user2) { FactoryGirl.build_stubbed(:user) }

        before do
          allow(User)
            .to receive(:where)
            .with(id: [user1.id.to_s, user2.id.to_s])
            .and_return([user1, user2])

          instance.values = [user1.id.to_s, user2.id.to_s]
        end

        it 'returns an array with users' do
          expect(instance.value_objects)
            .to match_array([user1, user2])
        end
      end
    end

    context 'version cf' do
      let(:custom_field) { version_wp_custom_field }

      describe '#ar_object_filter?' do
        it 'is true' do
          expect(instance)
            .to be_ar_object_filter
        end
      end

      describe '#value_objects' do
        let(:version1) { FactoryGirl.build_stubbed(:version) }
        let(:version2) { FactoryGirl.build_stubbed(:version) }

        before do
          allow(Version)
            .to receive(:where)
            .with(id: [version1.id.to_s, version2.id.to_s])
            .and_return([version1, version2])

          instance.values = [version1.id.to_s, version2.id.to_s]
        end

        it 'returns an array with users' do
          expect(instance.value_objects)
            .to match_array([version1, version2])
        end
      end
    end

    context 'date cf' do
      let(:custom_field) { date_wp_custom_field }

      it_behaves_like 'non ar filter'
    end

    context 'string cf' do
      let(:custom_field) { string_wp_custom_field }

      it_behaves_like 'non ar filter'
    end
  end
end
