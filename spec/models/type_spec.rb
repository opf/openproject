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
end
