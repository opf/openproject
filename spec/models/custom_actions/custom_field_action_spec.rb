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

describe CustomActions::CustomFieldAction, type: :model do
  let(:list_custom_field) do
    FactoryGirl.build_stubbed(:list_wp_custom_field)
  end
  let(:version_custom_field) do
    FactoryGirl.build_stubbed(:version_wp_custom_field)
  end
  let(:bool_custom_field) do
    FactoryGirl.build_stubbed(:bool_wp_custom_field)
  end
  let(:user_custom_field) do
    FactoryGirl.build_stubbed(:user_wp_custom_field)
  end
  let(:int_custom_field) do
    FactoryGirl.build_stubbed(:int_wp_custom_field)
  end
  let(:float_custom_field) do
    FactoryGirl.build_stubbed(:float_wp_custom_field)
  end
  let(:text_custom_field) do
    FactoryGirl.build_stubbed(:text_wp_custom_field)
  end
  let(:string_custom_field) do
    FactoryGirl.build_stubbed(:string_wp_custom_field)
  end
  let(:date_custom_field) do
    FactoryGirl.build_stubbed(:date_wp_custom_field)
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
     date_custom_field]
  end
  let(:klass) do
    allow(WorkPackageCustomField)
      .to receive(:find_by)
      .with(id: custom_field.id.to_s)
      .and_return(custom_field)

    described_class.for(:"custom_field_#{custom_field.id}")
  end
  let(:instance) do
    klass.new
  end

  describe '.all' do
    before do
      allow(WorkPackageCustomField)
        .to receive(:order)
        .and_return(custom_fields)
    end

    it 'is an array with a list of subclasses for every custom_field' do
      expect(described_class.all.length)
        .to eql custom_fields.length

      expect(described_class.all.map(&:custom_field))
        .to match_array(custom_fields)

      expect(described_class.all.all? { |a| described_class >= a })
        .to be_truthy
    end
  end

  describe '.key' do
    it 'is the custom field accessor' do
      expect(klass.key)
        .to eql(:"custom_field_#{custom_field.id}")
    end
  end

  describe '#key' do
    it 'is the custom field accessor' do
      expect(instance.key)
        .to eql(:"custom_field_#{custom_field.id}")
    end
  end

  describe '#value' do
    it 'can be provided on initialization' do
      i = klass.new(1)

      expect(i.value)
        .to eql 1
    end

    it 'can be set and read' do
      instance.value = 1

      expect(instance.value)
        .to eql 1
    end
  end

  describe '#human_name' do
    it 'is the name of the custom field' do
      expect(instance.human_name)
        .to eql(custom_field.name)
    end
  end

  describe '#type' do
    context 'for a list custom field' do
      it 'is :associated_property' do
        expect(instance.type)
          .to eql(:associated_property)
      end
    end

    context 'for a list custom field allowing multiple values' do
      let(:custom_field) do
        FactoryGirl.build_stubbed(:list_wp_custom_field, multi_value: true)
      end

      it 'is :associated_property_multi' do
        expect(instance.type)
          .to eql(:associated_property_multi)
      end
    end

    context 'for a text custom field' do
      let(:custom_field) { text_custom_field }

      it 'is :text_property' do
        expect(instance.type)
          .to eql(:text_property)
      end
    end

    context 'for a string custom field' do
      let(:custom_field) { string_custom_field }

      it 'is :string_property' do
        expect(instance.type)
          .to eql(:string_property)
      end
    end

    context 'for a version custom field' do
      let(:custom_field) { version_custom_field }

      it 'is :associated_property' do
        expect(instance.type)
          .to eql(:associated_property)
      end
    end

    context 'for a bool custom field' do
      let(:custom_field) { bool_custom_field }

      it 'is :boolean' do
        expect(instance.type)
          .to eql(:boolean)
      end
    end

    context 'for a user custom field' do
      let(:custom_field) { user_custom_field }

      it 'is :associated_property' do
        expect(instance.type)
          .to eql(:associated_property)
      end
    end

    context 'for an int custom field' do
      let(:custom_field) { int_custom_field }

      it 'is :integer_property' do
        expect(instance.type)
          .to eql(:integer_property)
      end
    end

    context 'for a float custom field' do
      let(:custom_field) { float_custom_field }

      it 'is :float_property' do
        expect(instance.type)
          .to eql(:float_property)
      end
    end

    context 'for a date custom field' do
      let(:custom_field) { date_custom_field }

      it 'is :date_property' do
        expect(instance.type)
          .to eql(:date_property)
      end
    end
  end

  describe '#allowed_values' do
    context 'for a list custom field' do
      let(:expected) do
        custom_field.custom_options
          .map { |o| { value: o.id, label: o.value } }
      end

      context 'for a non required field' do
        it 'is the list of options and an empty placeholder' do
          expect(instance.allowed_values)
            .to eql(expected.unshift(value: nil, label: '-'))
        end
      end

      context 'for a required field' do
        before do
          custom_field.is_required = true
        end

        it 'is the list of options' do
          expect(instance.allowed_values)
            .to eql(expected)
        end
      end
    end

    context 'for a version custom field' do
      let(:custom_field) { version_custom_field }
      let(:versions) do
        [FactoryGirl.build_stubbed(:version),
         FactoryGirl.build_stubbed(:version),
         FactoryGirl.build_stubbed(:version)]
      end

      before do
        allow(Version)
          .to receive(:systemwide)
          .and_return(versions)
      end
      let(:expected) do
        versions
          .map { |o| { value: o.id, label: o.name } }
      end

      context 'for a non required field' do
        it 'is the list of options and an empty placeholder' do
          expect(instance.allowed_values)
            .to eql(expected.unshift(value: nil, label: '-'))
        end
      end

      context 'for a required field' do
        before do
          custom_field.is_required = true
        end

        it 'is the list of options' do
          expect(instance.allowed_values)
            .to eql(expected)
        end
      end
    end

    context 'for a user custom field' do
      let(:custom_field) { user_custom_field }
      let(:users) do
        [FactoryGirl.build_stubbed(:user),
         FactoryGirl.build_stubbed(:user),
         FactoryGirl.build_stubbed(:user)]
      end

      before do
        allow(Principal)
          .to receive(:in_visible_project_or_me)
          .with(User.current)
          .and_return(users)
      end
      let(:expected) do
        users
          .map { |u| { value: u.id, label: u.name } }
      end

      context 'for a non required field' do
        it 'is the list of options and an empty placeholder' do
          expect(instance.allowed_values)
            .to eql(expected.unshift(value: nil, label: '-'))
        end
      end

      context 'for a required field' do
        before do
          custom_field.is_required = true
        end

        it 'is the list of options' do
          expect(instance.allowed_values)
            .to eql(expected)
        end
      end
    end

    context 'for a bool custom field' do
      let(:custom_field) { bool_custom_field }

      let(:expected) do
        [
          { label: I18n.t(:general_text_yes), value: CustomValue::BoolStrategy::DB_VALUE_TRUE },
          { label: I18n.t(:general_text_no), value: CustomValue::BoolStrategy::DB_VALUE_FALSE }
        ]
      end

      it 'is the list of options' do
        expect(instance.allowed_values)
          .to eql(expected)
      end
    end
  end
end
