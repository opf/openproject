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
  let(:type2) { FactoryGirl.build(:type) }
  let(:project) { FactoryGirl.build(:project) }

  describe '.enabled_in(project)' do
    before do
      type.projects << project
      type.save

      type2.save
    end

    it 'returns the types enabled in the provided project' do
      expect(Type.enabled_in(project)).to match_array([type])
    end
  end

  describe "#attribute_groups" do
    it 'returns #default_attribute_groups if not yet set' do
      expect(type.read_attribute(:attribute_groups)).to be_empty
      expect(type.attribute_groups).to_not be_empty
      expect(type.attribute_groups).to eq type.default_attribute_groups
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

    it "each attribute group's 1st element is a String (the group name)" do
      expect(subject.detect { |g| g.first.class != String }).to be_falsey
    end

    it "each attribute group's 2nd element is a String (the group members)" do
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
      expect { type.save }.to raise_exception
      # Exampel for invalid structure:
      type.attribute_groups = [[]]
      expect { type.save }.to raise_exception
      # Exampel for invalid group name:
      type.attribute_groups = [['', ['date']]]
      expect { type.save }.to raise_exception
    end

    it 'fails validations for unknown attributes' do
      type.attribute_groups = [['foo', ['bar']]]
      expect(type.save).to be_falsey
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
end
