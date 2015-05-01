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
require 'tableless_spec_helper'

class CopyDummy < Tableless
  include CopyModel

  attr_accessor :call_order

  copy_precedence([:relation4, :relation1, :relation2])

  not_to_copy :safe_attribute_that_should_not_be_copied

  safe_attributes 'safe_attribute1',
                  'safe_attribute2',
                  'safe_attribute_that_should_not_be_copied'

  column :safe_attribute1, :string
  column :safe_attribute2, :string
  column :unsafe_attribute, :string
  column :safe_attribute_that_should_not_be_copied, :string

  column :relation1_id, :integer
  column :relation2_id, :integer
  column :relation3_id, :integer
  column :relation4_id, :integer
  column :relation5_id, :integer

  belongs_to :relation1
  belongs_to :relation2
  belongs_to :relation3
  belongs_to :relation4
  belongs_to :relation5

  def copy_relation1(other)
    call_order << :relation1
    self.relation1 = other.relation1
  end

  def copy_relation2(other)
    call_order << :relation2
    self.relation2 = other.relation2
  end

  def copy_relation4(other)
    call_order << :relation4
    self.relation4 = other.relation4
  end

  # used to test error handling
  def copy_relation5(_other)
    raise 'Could not be copied!'
  end

  def call_order
    @call_order ||= []
    @call_order
  end
end

class Relation1 < Tableless
end

class Relation2 < Tableless
end

class Relation3 < Tableless
end

class Relation4 < Tableless
end

describe 'Copying Models' do
  before do
    # supress warnings
    I18n.backend.store_translations :en, activerecord: {
      attributes: {
        copy_dummy: {
          relation5: 'Relation5'
        } } }
  end
  let(:dummy) { CopyDummy.new }

  describe 'copying attributes' do
    it 'should copy safe attributes' do
      dummy.safe_attribute1 = 'foo'
      dummy.safe_attribute2 = 'bar'

      copy = CopyDummy.copy(dummy)

      expect(dummy.safe_attribute1).to eq(copy.safe_attribute1)
      expect(dummy.safe_attribute2).to eq(copy.safe_attribute2)
    end

    it 'should not copy unsafe attributes' do
      dummy.unsafe_attribute = 'foo'
      dummy.safe_attribute1 = 'foo'

      copy = CopyDummy.copy(dummy)

      expect(dummy.safe_attribute1).to eq(copy.safe_attribute1)
      expect(dummy.unsafe_attribute).not_to eq(copy.unsafe_attribute)
    end

    it 'should not copy safe attributes that are flagged as not_to_copy' do
      dummy.safe_attribute_that_should_not_be_copied = 'foo'
      dummy.safe_attribute1 = 'foo'

      copy = CopyDummy.copy(dummy)

      expect(dummy.safe_attribute1).to eq(copy.safe_attribute1)
      expect(dummy.safe_attribute_that_should_not_be_copied).not_to eq(copy.safe_attribute_that_should_not_be_copied)
    end
  end

  describe 'copying associations' do
    it 'should copy associations, for which there are methods in our model' do
      dummy.relation1 = Relation1.new
      dummy.relation2 = Relation2.new

      copy = CopyDummy.copy(dummy)

      expect(copy.relation1).to eq(dummy.relation1)
      expect(copy.relation1).not_to eq(nil)
      expect(copy.relation2).to eq(dummy.relation2)
      expect(copy.relation2).not_to eq(nil)
    end

    it 'should not copy associations, for which there are no methods in our model' do
      dummy.relation1 = Relation1.new
      dummy.relation3 = Relation3.new

      copy = CopyDummy.copy(dummy)

      expect(copy.relation1).to eq(dummy.relation1)
      expect(copy.relation1).not_to eq(nil)
      expect(copy.relation3).not_to eq(dummy.relation3)
      expect(copy.relation3).to eq(nil)
    end

    it 'should copy stuff within order (ordered by #copy_precedence)' do
      dummy.relation1 = Relation1.new
      dummy.relation2 = Relation2.new
      dummy.relation4 = Relation4.new

      copy = CopyDummy.copy(dummy)

      expect(copy.relation1).to eq(dummy.relation1)
      expect(copy.relation2).to eq(dummy.relation2)
      expect(copy.relation4).to eq(dummy.relation4)
      expect(copy.call_order).to eq(copy.copy_precedence)
    end

    it 'should produce some errors when failing to copy associations' do
      copy = CopyDummy.new
      copy.copy_associations(dummy)

      expect(copy.errors.count).to eq(1)
    end
  end
end
