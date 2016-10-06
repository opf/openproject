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

shared_examples_for 'work package query filter' do
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:instance) { described_class.create(project)[instance_key || class_key] }
  let(:instance_key) { nil }
  let(:class_key) { raise "needs to be defined" }
  let(:name) { WorkPackage.human_attribute_name(instance_key || class_key) }

  describe '.create' do
    it 'returns a hash with a subject key and a filter instance' do
      expect(described_class.create(project)[instance_key || class_key]).to be_a(described_class)
    end
  end

  describe '.key' do
    it 'is the defined key' do
      expect(described_class.key).to eql(class_key)
    end
  end

  describe '#key' do
    it 'is the defined key' do
      expect(instance.key).to eql(instance_key || class_key)
    end
  end

  describe '#order' do
    it 'has the defined order' do
      expect(instance.order).to eql(order)
    end
  end

  describe '#type' do
    it 'is the defined filter type' do
      expect(instance.type).to eql(type)
    end
  end

  describe '#name' do
    it 'is the l10 name for the filter' do
      expect(instance.name).to eql(name)
    end
  end
end
