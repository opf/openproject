#-- encoding: UTF-8
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
require 'legacy_spec_helper'

describe Relation, type: :model do
  include MiniTest::Assertions # refute

  fixtures :all

  it 'should create' do
    from = WorkPackage.find(1)
    to = WorkPackage.find(2)

    relation = Relation.new from: from, to: to, relation_type: Relation::TYPE_PRECEDES
    assert relation.save
    relation.reload
    assert_equal Relation::TYPE_PRECEDES, relation.relation_type
    assert_equal from, relation.from
    assert_equal to, relation.to
  end

  it 'should follows relation should be reversed' do
    from = WorkPackage.find(1)
    to = WorkPackage.find(2)

    relation = Relation.new from: from, to: to, relation_type: Relation::TYPE_FOLLOWS
    assert relation.save
    relation.reload
    assert_equal Relation::TYPE_PRECEDES, relation.relation_type
    assert_equal to, relation.from
    assert_equal from, relation.to
  end

  it 'should follows relation should not be reversed if validation fails' do
    from = WorkPackage.find(1)
    to = WorkPackage.find(2)

    relation = Relation.new from: from, to: to, relation_type: Relation::TYPE_FOLLOWS, delay: 'xx'
    assert !relation.save
    assert_equal Relation::TYPE_FOLLOWS, relation.relation_type
    assert_equal from, relation.from
    assert_equal to, relation.to
  end

  it 'should relation type for' do
    from = WorkPackage.find(1)
    to = WorkPackage.find(2)

    relation = Relation.new from: from, to: to, relation_type: Relation::TYPE_PRECEDES
    assert_equal Relation::TYPE_PRECEDES, relation.relation_type_for(from)
    assert_equal Relation::TYPE_FOLLOWS, relation.relation_type_for(to)
  end

  it 'should set dates of target without to' do
    r = Relation.new(from: WorkPackage.new(start_date: Date.today), relation_type: Relation::TYPE_PRECEDES, delay: 1)
    assert_nil r.set_dates_of_target
  end

  it 'should set dates of target without issues' do
    r = Relation.new(relation_type: Relation::TYPE_PRECEDES, delay: 1)
    assert_nil r.set_dates_of_target
  end

  it 'should validates circular dependency' do
    Relation.delete_all
    assert Relation.create!(from: WorkPackage.find(1), to: WorkPackage.find(2), relation_type: Relation::TYPE_PRECEDES)
    assert Relation.create!(from: WorkPackage.find(2), to: WorkPackage.find(3), relation_type: Relation::TYPE_PRECEDES)
    r = Relation.new(from: WorkPackage.find(3), to: WorkPackage.find(1), relation_type: Relation::TYPE_PRECEDES)
    assert !r.save
    refute_empty r.errors[:base]
  end
end
