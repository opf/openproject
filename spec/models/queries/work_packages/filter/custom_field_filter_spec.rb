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

describe Queries::WorkPackages::Filter::CustomFieldFilter, type: :model do
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:instance) { described_class.create(project)["cf_#{list_wp_custom_field.id}"] }
  let(:instance_key) { nil }
  let(:name) { field.name }

  let(:list_wp_custom_field) { FactoryGirl.build_stubbed(:list_wp_custom_field) }
  let(:bool_wp_custom_field) { FactoryGirl.build_stubbed(:bool_wp_custom_field) }
  let(:int_wp_custom_field) { FactoryGirl.build_stubbed(:int_wp_custom_field) }
  let(:float_wp_custom_field) { FactoryGirl.build_stubbed(:float_wp_custom_field) }
  let(:text_wp_custom_field) { FactoryGirl.build_stubbed(:text_wp_custom_field) }
  let(:user_wp_custom_field) { FactoryGirl.build_stubbed(:user_wp_custom_field) }
  let(:version_wp_custom_field) { FactoryGirl.build_stubbed(:version_wp_custom_field) }
  let(:date_wp_custom_field) { FactoryGirl.build_stubbed(:date_wp_custom_field) }
  let(:string_wp_custom_field) { FactoryGirl.build_stubbed(:string_wp_custom_field) }

  let(:all_custom_fields) {
    [list_wp_custom_field,
     bool_wp_custom_field,
     int_wp_custom_field,
     float_wp_custom_field,
     text_wp_custom_field,
     user_wp_custom_field,
     version_wp_custom_field,
     date_wp_custom_field,
     string_wp_custom_field]
  }

  before do
    if project
      allow(project)
        .to receive(:all_work_package_custom_fields)
        .with(include: :translations)
        .and_return(all_custom_fields)
    end
  end

  describe '.create' do
    context 'within a project' do
      it 'returns a hash with a subject key and a filter instance for every custom field' do
        expect(described_class.create(project)["cf_#{list_wp_custom_field.id}"])
          .to be_a(described_class)
        expect(described_class.create(project)["cf_#{bool_wp_custom_field.id}"])
          .to be_a(described_class)
        expect(described_class.create(project)["cf_#{int_wp_custom_field.id}"])
          .to be_a(described_class)
        expect(described_class.create(project)["cf_#{float_wp_custom_field.id}"])
          .to be_a(described_class)
        expect(described_class.create(project)["cf_#{text_wp_custom_field.id}"])
          .to be_a(described_class)
        expect(described_class.create(project)["cf_#{user_wp_custom_field.id}"])
          .to be_a(described_class)
        expect(described_class.create(project)["cf_#{version_wp_custom_field.id}"])
          .to be_a(described_class)
        expect(described_class.create(project)["cf_#{date_wp_custom_field.id}"])
          .to be_a(described_class)
        expect(described_class.create(project)["cf_#{string_wp_custom_field.id}"])
          .to be_a(described_class)
      end
    end

    context 'outside of a project' do
      let(:project) { nil }

      before do
        allow(WorkPackageCustomField)
          .to receive_message_chain(:filter, :for_all, :where, :not, :includes)
          .and_return([list_wp_custom_field,
                       bool_wp_custom_field,
                       int_wp_custom_field,
                       float_wp_custom_field,
                       text_wp_custom_field,
                       date_wp_custom_field,
                       string_wp_custom_field])
      end

      it 'returns a hash with a subject key and a filter instance for every custom field' do
        expect(described_class.create(project)["cf_#{list_wp_custom_field.id}"])
          .to be_a(described_class)
        expect(described_class.create(project)["cf_#{bool_wp_custom_field.id}"])
          .to be_a(described_class)
        expect(described_class.create(project)["cf_#{int_wp_custom_field.id}"])
          .to be_a(described_class)
        expect(described_class.create(project)["cf_#{float_wp_custom_field.id}"])
          .to be_a(described_class)
        expect(described_class.create(project)["cf_#{text_wp_custom_field.id}"])
          .to be_a(described_class)
        expect(described_class.create(project)["cf_#{user_wp_custom_field.id}"])
          .to be_nil
        expect(described_class.create(project)["cf_#{version_wp_custom_field.id}"])
          .to be_nil
        expect(described_class.create(project)["cf_#{date_wp_custom_field.id}"])
          .to be_a(described_class)
        expect(described_class.create(project)["cf_#{string_wp_custom_field.id}"])
          .to be_a(described_class)
      end
    end
  end

  describe '.key' do
    it 'is a regular expression' do
      expect(described_class.key).to eql(/cf_\d+/)
    end
  end

  describe '#key' do
    it 'is the custom fields id prefixed with cf_' do
      all_custom_fields.each do |cf|
        expect(described_class.create(project)["cf_#{cf.id}"].key).to eql(:"cf_#{cf.id}")
      end
    end
  end

  describe '#order' do
    it 'is 20' do
      all_custom_fields.each do |cf|
        expect(described_class.create(project)["cf_#{cf.id}"].order).to eql(20)
      end
    end
  end

  describe '#type' do
    it 'is integer for an integer' do
      expect(described_class.create(project)["cf_#{int_wp_custom_field.id}"].type)
        .to eql(:integer)
    end

    it 'is integer for a float' do
      expect(described_class.create(project)["cf_#{float_wp_custom_field.id}"].type)
        .to eql(:integer)
    end

    it 'is text for a text' do
      expect(described_class.create(project)["cf_#{text_wp_custom_field.id}"].type)
        .to eql(:text)
    end

    it 'is list_optional for a list' do
      expect(described_class.create(project)["cf_#{list_wp_custom_field.id}"].type)
        .to eql(:list_optional)
    end

    it 'is list_optional for a user' do
      expect(described_class.create(project)["cf_#{user_wp_custom_field.id}"].type)
        .to eql(:list_optional)
    end

    it 'is list_optional for a version' do
      expect(described_class.create(project)["cf_#{version_wp_custom_field.id}"].type)
        .to eql(:list_optional)
    end

    it 'is date for a date' do
      expect(described_class.create(project)["cf_#{date_wp_custom_field.id}"].type)
        .to eql(:date)
    end

    it 'is list for a bool' do
      expect(described_class.create(project)["cf_#{bool_wp_custom_field.id}"].type)
        .to eql(:list)
    end

    it 'is string for a string' do
      expect(described_class.create(project)["cf_#{string_wp_custom_field.id}"].type)
        .to eql(:string)
    end
  end

  describe '#name' do
    it 'is the field name' do
      expect(described_class.create(project)["cf_#{string_wp_custom_field.id}"].name)
        .to eql(string_wp_custom_field.name)
    end
  end

  describe '#available' do
    it 'is true' do
      all_custom_fields.each do |cf|
        expect(described_class.create(project)["cf_#{cf.id}"]).to be_available
      end
    end
  end

  describe '#values' do
    it 'is nil for an integer' do
      expect(described_class.create(project)["cf_#{int_wp_custom_field.id}"].values)
        .to be_nil
    end

    it 'is integer for a float' do
      expect(described_class.create(project)["cf_#{float_wp_custom_field.id}"].values)
        .to be_nil
    end

    it 'is text for a text' do
      expect(described_class.create(project)["cf_#{text_wp_custom_field.id}"].values)
        .to be_nil
    end

    it 'is list_optional for a list' do
      expect(described_class.create(project)["cf_#{list_wp_custom_field.id}"].values)
        .to match_array list_wp_custom_field.possible_values
    end

    it 'is list_optional for a user' do
      bogus_return_value = ['user1', 'user2']
      allow(user_wp_custom_field)
        .to receive(:possible_values_options)
        .with(project)
        .and_return(bogus_return_value)

      expect(described_class.create(project)["cf_#{user_wp_custom_field.id}"].values)
        .to match_array bogus_return_value
    end

    it 'is list_optional for a version' do
      bogus_return_value = ['version1', 'version2']
      allow(version_wp_custom_field)
        .to receive(:possible_values_options)
        .with(project)
        .and_return(bogus_return_value)

      expect(described_class.create(project)["cf_#{version_wp_custom_field.id}"].values)
        .to match_array bogus_return_value
    end

    it 'is nil for a date' do
      expect(described_class.create(project)["cf_#{date_wp_custom_field.id}"].values)
        .to be_nil
    end

    it 'is list for a bool' do
      expect(described_class.create(project)["cf_#{bool_wp_custom_field.id}"].values)
        .to match_array [[I18n.t(:general_text_yes), ActiveRecord::Base.connection.unquoted_true],
                         [I18n.t(:general_text_no), ActiveRecord::Base.connection.unquoted_false]]
    end

    it 'is nil for a string' do
      expect(described_class.create(project)["cf_#{string_wp_custom_field.id}"].values)
        .to be_nil
    end
  end
end
