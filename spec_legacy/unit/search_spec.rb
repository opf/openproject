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

describe 'Search' do # FIXME: naming (RSpec-port)
  fixtures :all

  before do
    @project = Project.find(1)
    @issue_keyword = '%unable to print recipes%'
    @issue = WorkPackage.find(1)
    @changeset_keyword = '%very first commit%'
    @changeset = Changeset.find(100)
  end

  it 'should search_by_anonymous' do
    User.current = nil

    r = WorkPackage.search(@issue_keyword).first
    assert r.include?(@issue)
    r = Changeset.search(@changeset_keyword).first
    assert r.include?(@changeset)

    # Removes the :view_changesets permission from Anonymous role
    remove_permission Role.anonymous, :view_changesets

    r = WorkPackage.search(@issue_keyword).first
    assert r.include?(@issue)
    r = Changeset.search(@changeset_keyword).first
    assert !r.include?(@changeset)

    # Make the project private
    @project.update_attribute :is_public, false
    r = WorkPackage.search(@issue_keyword).first
    assert !r.include?(@issue)
    r = Changeset.search(@changeset_keyword).first
    assert !r.include?(@changeset)
  end

  it 'should search_by_user' do
    User.current = User.find_by_login('rhill')
    assert User.current.memberships.empty?

    r = WorkPackage.search(@issue_keyword).first
    assert r.include?(@issue)
    r = Changeset.search(@changeset_keyword).first
    assert r.include?(@changeset)

    # Removes the :view_changesets permission from Non member role
    remove_permission Role.non_member, :view_changesets

    r = WorkPackage.search(@issue_keyword).first
    assert r.include?(@issue)
    r = Changeset.search(@changeset_keyword).first
    assert !r.include?(@changeset)

    # Make the project private
    @project.update_attribute :is_public, false
    r = WorkPackage.search(@issue_keyword).first
    assert !r.include?(@issue)
    r = Changeset.search(@changeset_keyword).first
    assert !r.include?(@changeset)
  end

  it 'should search_by_allowed_member' do
    User.current = User.find_by_login('jsmith')
    assert User.current.projects.include?(@project)

    r = WorkPackage.search(@issue_keyword).first
    assert r.include?(@issue)
    r = Changeset.search(@changeset_keyword).first
    assert r.include?(@changeset)

    # Make the project private
    @project.update_attribute :is_public, false
    r = WorkPackage.search(@issue_keyword).first
    assert r.include?(@issue)
    r = Changeset.search(@changeset_keyword).first
    assert r.include?(@changeset)
  end

  it 'should search_by_unallowed_member' do
    # Removes the :view_changesets permission from user's and non member role
    remove_permission Role.find(1), :view_changesets
    remove_permission Role.non_member, :view_changesets

    User.current = User.find_by_login('jsmith')
    assert User.current.projects.include?(@project)

    r = WorkPackage.search(@issue_keyword).first
    assert r.include?(@issue)
    r = Changeset.search(@changeset_keyword).first
    assert !r.include?(@changeset)

    # Make the project private
    @project.update_attribute :is_public, false
    r = WorkPackage.search(@issue_keyword).first
    assert r.include?(@issue)
    r = Changeset.search(@changeset_keyword).first
    assert !r.include?(@changeset)
  end

  it 'should search_issue_with_multiple_hits_in_journals' do
    i = WorkPackage.find(1)
    Journal.where(journable_id: i.id).delete_all
    i.add_journal User.current, 'Journal notes'
    i.save!
    i.add_journal User.current, 'Some notes with Redmine links: #2, r2.'
    i.save!

    assert_equal 2, i.journals.where("notes LIKE '%notes%'").count

    r = WorkPackage.search('%notes%').first
    assert_equal 1, r.size
    assert_equal i, r.first
  end

  private

  def remove_permission(role, permission)
    role.permissions = role.permissions - [permission]
    role.save
  end
end
