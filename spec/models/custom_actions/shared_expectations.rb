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

shared_examples_for 'associated custom action' do
  let(:instance) do
    described_class.new
  end
  let(:expected_key) do
    if defined?(key)
      key
    else
      raise ":key needs to be defined"
    end
  end

  describe '.all' do
    it 'is an array with the class itself' do
      expect(described_class.all)
        .to match_array [described_class]
    end
  end

  describe '.key' do
    it 'is the expected key' do
      expect(described_class.key)
        .to eql(expected_key)
    end
  end

  describe '#key' do
    it 'is the expected key' do
      expect(instance.key)
        .to eql(expected_key)
    end
  end

  describe '#values' do
    it 'can be provided on initialization' do
      i = described_class.new(1)

      expect(i.values)
        .to eql [1]
    end

    it 'can be set and read' do
      instance.values = 1

      expect(instance.values)
        .to eql [1]
    end
  end

  describe '#human_name' do
    it 'is the human_attribute_name' do
      expect(instance.human_name)
        .to eql(WorkPackage.human_attribute_name(expected_key))
    end
  end

  describe '#type' do
    it 'is :associated_property' do
      expect(instance.type)
        .to eql(:associated_property)
    end
  end
end

shared_examples_for 'associated custom condition' do
  let(:instance) do
    described_class.new
  end
  let(:expected_key) do
    if defined?(key)
      key
    else
      raise ":key needs to be defined"
    end
  end

  describe '.key' do
    it 'is the expected key' do
      expect(described_class.key)
        .to eql(expected_key)
    end
  end

  describe '#key' do
    it 'is the expected key' do
      expect(instance.key)
        .to eql(expected_key)
    end
  end

  describe '#values' do
    it 'can be provided on initialization' do
      i = described_class.new(1)

      expect(i.values)
        .to eql [1]
    end

    it 'can be set and read' do
      instance.values = 1

      expect(instance.values)
        .to eql [1]
    end
  end

  describe '#human_name' do
    it 'is the human_attribute_name' do
      expect(instance.human_name)
        .to eql(WorkPackage.human_attribute_name(expected_key))
    end
  end
end
