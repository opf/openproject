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
require 'legacy_spec_helper'

describe 'IssueNestedSet', type: :model do
  include MiniTest::Assertions # refute

  fixtures :all

  self.use_transactional_fixtures = false

  before do
    WorkPackage.delete_all
  end

  it 'should creating a child in different project should not validate unless allowed' do
    Setting.cross_project_work_package_relations = '0'
    issue = create_issue!
    child = WorkPackage.new.tap do |i|
      i.attributes = { project_id: 2,
                             type_id: 1,
                             author_id: 1,
                             subject: 'child',
                             parent_id: issue.id }
    end
    assert !child.save
    refute_empty child.errors[:parent_id]
  end

  it 'should creating a child in different project should validate if allowed' do
    Setting.cross_project_work_package_relations = '1'
    issue = create_issue!
    child = WorkPackage.new.tap do |i|
      i.attributes = { project_id: 2,
                             type_id: 1,
                             author_id: 1,
                             subject: 'child',
                             parent_id: issue.id }
    end
    assert child.save
    assert_empty child.errors[:parent_id]
  end

  it 'should invalid move to another project' do
    parent1 = create_issue!
    child =   create_issue!(parent_id: parent1.id)
    grandchild = create_issue!(parent_id: child.id, type_id: 2)
    Project.find(2).type_ids = [1]

    parent1.reload
    assert_equal [1, parent1.id, 5], [parent1.project_id, parent1.root_id, parent1.nested_set_span]

    # child can not be moved to Project 2 because its child is on a disabled type
    service = MoveWorkPackageService.new(child, User.find(1))
    assert_equal false, service.call(Project.find(2))
    child.reload
    grandchild.reload
    parent1.reload

    # no change
    assert_equal [1, parent1.id, 5], [parent1.project_id, parent1.root_id, parent1.nested_set_span]
    assert_equal [1, parent1.id, 3], [child.project_id, child.root_id, child.nested_set_span]
    assert_equal [1, parent1.id, 1], [grandchild.project_id, grandchild.root_id, grandchild.nested_set_span]
  end

  it 'should moving an to a descendant should not validate' do
    parent1 = create_issue!
    parent2 = create_issue!
    child =   create_issue!(parent_id: parent1.id)
    grandchild = create_issue!(parent_id: child.id)

    child.reload
    child.parent_id = grandchild.id
    assert !child.save
    refute_empty child.errors[:parent_id]
  end

  it 'should moving an issue should keep valid relations only' do
    issue1 = create_issue!
    issue2 = create_issue!
    issue3 = create_issue!(parent_id: issue2.id)
    issue4 = create_issue!
    (r1 = Relation.new.tap do |i|
      i.attributes = { from: issue1,
                             to: issue2,
                             relation_type: Relation::TYPE_PRECEDES }
    end).save!
    (r2 = Relation.new.tap do |i|
      i.attributes = { from: issue1,
                             to: issue3,
                             relation_type: Relation::TYPE_PRECEDES }
    end).save!
    (r3 = Relation.new.tap do |i|
      i.attributes = { from: issue2,
                             to: issue4,
                             relation_type: Relation::TYPE_PRECEDES }
    end).save!
    issue2.reload
    issue2.parent_id = issue1.id
    issue2.save!
    assert !Relation.exists?(r1.id)
    assert !Relation.exists?(r2.id)
    assert Relation.exists?(r3.id)
  end

  it 'should destroy should destroy children' do
    issue1 = create_issue!
    issue2 = create_issue!
    issue3 = create_issue!(parent_id: issue2.id)
    issue4 = create_issue!(parent_id: issue1.id)

    issue3.add_journal(User.find(2))
    issue3.subject = 'child with journal'
    issue3.save!

    assert_difference 'WorkPackage.count', -2 do
      # FIXME: wrong result returned for Journal.count
      # assert_difference 'Journal.count', -3 do
      WorkPackage.find(issue2.id).destroy
      # end
    end

    issue1.reload
    issue4.reload
    assert !WorkPackage.exists?(issue2.id)
    assert !WorkPackage.exists?(issue3.id)
    assert_equal [issue1.id, 3], [issue1.root_id, issue1.nested_set_span]
    assert_equal [issue1.id, 1], [issue4.root_id, issue4.nested_set_span]
  end

  it 'should destroy parent work package updated during children destroy' do
    parent = create_issue!
    create_issue!(start_date: Date.today, parent_id: parent.id)
    create_issue!(start_date: 2.days.from_now, parent_id: parent.id)

    assert_difference 'WorkPackage.count', -3 do
      WorkPackage.find(parent.id).destroy
    end
  end

  it 'should destroy child issue with children' do
    root = create_issue!(project_id: 1, author_id: 2, type_id: 1, subject: 'root').reload
    child = create_issue!(project_id: 1, author_id: 2, type_id: 1, subject: 'child', parent_id: root.id).reload
    leaf = create_issue!(project_id: 1, author_id: 2, type_id: 1, subject: 'leaf', parent_id: child.id).reload
    leaf.add_journal(User.find(2))
    leaf.subject = 'leaf with journal'
    leaf.save!

    total_journals_on_children = leaf.reload.journals.count + child.reload.journals.count
    assert_difference 'WorkPackage.count', -2 do
      assert_difference 'Journal.count', -total_journals_on_children do
        WorkPackage.find(child.id).destroy
      end
    end

    root = WorkPackage.find(root.id)
    assert root.leaf?, "Root issue is not a leaf (lft: #{root.lft}, rgt: #{root.rgt})"
  end

  it 'should destroy issue with grand child' do
    parent = create_issue!
    issue = create_issue!(parent_id: parent.id)
    child = create_issue!(parent_id: issue.id)
    grandchild1 = create_issue!(parent_id: child.id)
    grandchild2 = create_issue!(parent_id: child.id)

    assert_difference 'WorkPackage.count', -4 do
      WorkPackage.find(issue.id).destroy
      parent.reload
      assert_equal [1, 2], [parent.lft, parent.rgt], 'parent should not have children'
    end
  end

  it 'should parent dates should be lowest start and highest due dates' do
    parent = create_issue!
    create_issue!(start_date: '2010-01-25', due_date: '2010-02-15', parent_id: parent.id)
    create_issue!(due_date: '2010-02-13', parent_id: parent.id)
    create_issue!(start_date: '2010-02-01', due_date: '2010-02-22', parent_id: parent.id)
    parent.reload
    assert_equal Date.parse('2010-01-25'), parent.start_date
    assert_equal Date.parse('2010-02-22'), parent.due_date
  end

  it 'should parent done ratio should be average done ratio of leaves' do
    parent = create_issue!
    create_issue!(done_ratio: 20, parent_id: parent.id)
    assert_equal 20, parent.reload.done_ratio
    create_issue!(done_ratio: 70, parent_id: parent.id)
    assert_equal 45, parent.reload.done_ratio

    child = create_issue!(done_ratio: 0, parent_id: parent.id)
    assert_equal 30, parent.reload.done_ratio

    create_issue!(done_ratio: 30, parent_id: child.id)
    assert_equal 30, child.reload.done_ratio
    assert_equal 40, parent.reload.done_ratio
  end

  it 'should parent done ratio should be weighted by estimated times if any' do
    parent = create_issue!
    create_issue!(estimated_hours: 10, done_ratio: 20, parent_id: parent.id)
    assert_equal 20, parent.reload.done_ratio
    create_issue!(estimated_hours: 20, done_ratio: 50, parent_id: parent.id)
    assert_equal (50 * 20 + 20 * 10) / 30, parent.reload.done_ratio
  end

  it 'should parent estimate should be sum of leaves' do
    parent = create_issue!
    create_issue!(estimated_hours: nil, parent_id: parent.id)
    assert_equal nil, parent.reload.estimated_hours
    create_issue!(estimated_hours: 5, parent_id: parent.id)
    assert_equal 5, parent.reload.estimated_hours
    create_issue!(estimated_hours: 7, parent_id: parent.id)
    assert_equal 12, parent.reload.estimated_hours
  end

  it 'should move parent updates old parent attributes' do
    first_parent = create_issue!
    second_parent = create_issue!
    child = create_issue!(estimated_hours: 5,
                          parent_id: first_parent.id)
    assert_equal 5, first_parent.reload.estimated_hours
    child.update_attributes(estimated_hours: 7,
                            parent_id: second_parent.id)
    assert_equal 7, second_parent.reload.estimated_hours
    assert_nil first_parent.reload.estimated_hours
  end

  it 'should project copy should copy issue tree' do
    Project.delete_all # make sure unqiue identifiers
    p = Project.create!(name: 'Tree copy', identifier: 'tree-copy', type_ids: [1, 2])
    i1 = create_issue!(project_id: p.id, subject: 'i1')
    i2 = create_issue!(project_id: p.id, subject: 'i2', parent_id: i1.id)
    i3 = create_issue!(project_id: p.id, subject: 'i3', parent_id: i1.id)
    i4 = create_issue!(project_id: p.id, subject: 'i4', parent_id: i2.id)
    i5 = create_issue!(project_id: p.id, subject: 'i5')
    c = Project.new(name: 'Copy', identifier: 'copy', type_ids: [1, 2])
    c.copy(p, only: 'work_packages')
    c.reload

    assert_equal 5, c.work_packages.count
    ic1, ic2, ic3, ic4, ic5 = c.work_packages.reorder('subject')
    assert ic1.root?
    assert_equal ic1, ic2.parent
    assert_equal ic1, ic3.parent
    assert_equal ic2, ic4.parent
    assert ic5.root?
  end

  # Helper that creates an issue with default attributes
  def create_issue!(attributes = {})
    (i = WorkPackage.new.tap do |i|
      attr = { project_id: 1, type_id: 1, author_id: 1, subject: 'test' }.merge(attributes)
      i.attributes = attr
    end).save!
    i
  end
end
