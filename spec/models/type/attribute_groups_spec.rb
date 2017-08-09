#-- encoding: UTF-8

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

describe ::Type, type: :model do
  let(:type) { FactoryGirl.build(:type) }

  before do
    # Clear up the request store cache for all_work_package_attributes
    RequestStore.clear!
  end

  describe "#attribute_groups" do
    it 'returns #default_attribute_groups if not yet set' do
      expect(type.read_attribute(:attribute_groups)).to be_empty
      expect(type.attribute_groups).to_not be_empty
      expect(type.attribute_groups).to eq type.default_attribute_groups
    end

    it 'removes unknown attributes from a group' do
      type.attribute_groups = [['foo', ['bar', 'date']]]
      expect(type.attribute_groups).to eq [['foo', ['date']]]
    end

    it 'keeps groups without attributes' do
      type.attribute_groups = [['foo', []], ['bar', ['date']]]
      expect(type.attribute_groups).to eq [['foo', []], ['bar', ['date']]]
    end
  end

  describe '#default_attribute_groups' do
    subject { type.default_attribute_groups }

    it 'returns an array' do
      expect(subject.any?).to be_truthy
    end

    it 'each attribute group is an array' do
      expect(subject.detect { |g| g.class != Array }).to be_falsey
    end

    it "each attribute group's 1st element is a String (the group name) or symbol (for i18n)" do
      expect(subject.detect { |g| g.first.class != String && g.first.class != Symbol }).to be_falsey
    end

    it "each attribute group's 2nd element is an Array (the group members)" do
      expect(subject.detect { |g| g.second.class != Array }).to be_falsey
    end

    it 'does not return empty groups' do
      # For instance, the `type` factory instance does not have custom fields.
      # Thus the `other` group shall not be returned.
      expect(subject.detect do |attribute_group|
        group_members = attribute_group[1]
        group_members.nil? || group_members.size.zero?
      end).to be_falsey
    end
  end

  describe "#validate_attribute_groups" do
    it 'raises an exception for invalid structure' do
      # Exampel for invalid structure:
      type.attribute_groups = ['foo']
      expect { type.save }.to raise_exception(NoMethodError)
      # Exampel for invalid structure:
      type.attribute_groups = [[]]
      expect { type.save }.to raise_exception(NoMethodError)
      # Exampel for invalid group name:
      type.attribute_groups = [['', ['date']]]
      expect(type).not_to be_valid
    end

    it 'fails for duplicate group names' do
      type.attribute_groups = [['foo', ['date']], ['foo', ['date']]]
      expect(type).not_to be_valid
    end

    it 'passes validations for known attributes' do
      type.attribute_groups = [['foo', ['date']]]
      expect(type.save).to be_truthy
    end

    it 'passes validation for defaults' do
      expect(type.save).to be_truthy
    end

    it 'passes validation for reset' do
      # A reset is to save an empty Array
      type.attribute_groups = []
      expect(type.save).to be_truthy
      expect(type.attribute_groups).to eq type.default_attribute_groups
    end
  end

  describe "#form_configuration_groups" do
    it "returns a Hash with the keys :actives and :inactives Arrays" do
      expect(type.form_configuration_groups[:actives]).to be_an Array
      expect(type.form_configuration_groups[:inactives]).to be_an Array
    end

    describe ":inactives" do
      subject { type.form_configuration_groups[:inactives] }

      before do
        type.attribute_groups = [["group one", ["assignee"]]]
      end

      it 'contains Hashes ordered by key :translation' do
        # The first left over attribute should currently be "date"
        expect(subject.first[:translation]).to be_present
        expect(subject.first[:translation] <= subject.second[:translation]).to be_truthy
      end

      # The "assignee" is in "group one". It should not appear in :inactives.
      it 'does not contain attributes that do not exist anymore' do
        expect(subject.map { |inactive| inactive[:key] }).to_not include "assignee"
      end
    end

    describe ":actives" do
      subject { type.form_configuration_groups[:actives] }

      before do
        allow(type).to receive(:attribute_groups).and_return [["group one", ["date"]]]
      end

      it 'has a proper structure' do
        # The group's name/key
        expect(subject.first.first).to eq "group one"

        # The groups attributes
        expect(subject.first.second).to be_an Array
        expect(subject.first.second.first[:key]).to eq "date"
        expect(subject.first.second.first[:translation]).to eq "Date"
      end
    end
  end

  describe 'custom fields' do
    let!(:custom_field) do
      FactoryGirl.create(
        :work_package_custom_field,
        field_format: 'string'
      )
    end
    let(:cf_identifier) do
      :"custom_field_#{custom_field.id}"
    end

    it 'can be put into attribute groups' do
      # Is in inactive group
      form = type.form_configuration_groups
      expect(form[:inactives][0][:key]).to eq(cf_identifier.to_s)

      # Can be enabled
      type.attribute_groups = [['foo', [cf_identifier.to_s]]]
      expect(type.save).to be_truthy
      expect(type.read_attribute(:attribute_groups)).not_to be_empty
    end
  end
end
