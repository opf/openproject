#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

shared_examples_for 'query column' do
  describe '#groupable' do
    it 'is the name if true is provided' do
      instance.groupable = true

      expect(instance.groupable).to eql(instance.name.to_s)
    end

    it 'is the value if something trueish is provided' do
      instance.groupable = 'lorem ipsum'

      expect(instance.groupable).to eql('lorem ipsum')
    end

    it 'is false if false is provided' do
      instance.groupable = false

      expect(instance.groupable).to be_falsey
    end

    it 'is false if nothing is provided' do
      instance.groupable = nil

      expect(instance.groupable).to be_falsey
    end
  end

  describe '#sortable' do
    it 'is the name if true is provided' do
      instance.sortable = true

      expect(instance.sortable).to eql(instance.name.to_s)
    end

    it 'is the value if something trueish is provided' do
      instance.sortable = 'lorem ipsum'

      expect(instance.sortable).to eql('lorem ipsum')
    end

    it 'is false if false is provided' do
      instance.sortable = false

      expect(instance.sortable).to be_falsey
    end

    it 'is false if nothing is provided' do
      instance.sortable = nil

      expect(instance.sortable).to be_falsey
    end
  end

  describe '#groupable?' do
    it 'is false by default' do
      expect(instance.groupable?).to be_falsey
    end

    it 'is true if told so' do
      instance.groupable = true

      expect(instance.groupable?).to be_truthy
    end

    it 'is true if a value is provided (e.g. for specifying sql code)' do
      instance.groupable = 'COALESCE(null, 1)'

      expect(instance.groupable?).to be_truthy
    end
  end

  describe '#sortable?' do
    it 'is false by default' do
      expect(instance.sortable?).to be_falsey
    end

    it 'is true if told so' do
      instance.sortable = true

      expect(instance.sortable?).to be_truthy
    end

    it 'is true if a value is provided (e.g. for specifying sql code)' do
      instance.sortable = 'COALESCE(null, 1)'

      expect(instance.sortable?).to be_truthy
    end
  end
end
