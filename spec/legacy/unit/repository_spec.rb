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

describe Repository, type: :model do
  fixtures :all

  before do
    @repository = Project.find(1).repository
  end

  around do |example|
    with_settings enabled_scm: %w(Subversion) do
      example.run
    end
  end

  it 'should create' do
    repository = Repository::Subversion.new(project: Project.find(3))
    assert !repository.save

    repository.url = 'svn://localhost'
    assert repository.save
    repository.reload

    project = Project.find(3)
    assert_equal repository, project.repository
  end

  it 'should destroy' do
    changesets = Changeset.where('repository_id = 10').size
    changes = Change.includes(:changeset).where("#{Changeset.table_name}.repository_id = 10").size
    assert_difference 'Changeset.count', -changesets do
      assert_difference 'Change.count', -changes do
        Repository.find(10).destroy
      end
    end
  end

  it 'should not create with disabled scm' do
    Setting.enabled_scm = ['Git'] # disable Subversion
    repository = Repository::Subversion.new(project: Project.find(3), url: 'svn://localhost')
    assert !repository.save
    assert_include repository.errors[:type], I18n.translate('activerecord.errors.messages.invalid')
    # re-enable Subversion for following tests
    Setting.delete_all
  end

  it 'should scan changesets for work package ids' do
    WorkPackage.all.each(&:recreate_initial_journal!)

    Setting.default_language = 'en'
    Setting.notified_events = ['work_package_added', 'work_package_updated']

    # choosing a status to apply to fix issues
    Setting.commit_fix_status_id = Status.find(:first, conditions: ['is_closed = ?', true]).id
    Setting.commit_fix_done_ratio = '90'
    Setting.commit_ref_keywords = 'refs , references, IssueID'
    Setting.commit_fix_keywords = 'fixes , closes'
    Setting.default_language = 'en'
    ActionMailer::Base.deliveries.clear

    # make sure work package 1 is not already closed
    fixed_work_package = WorkPackage.find(1)
    assert !fixed_work_package.status.is_closed?
    old_status = fixed_work_package.status

    Repository.scan_changesets_for_work_package_ids
    assert_equal [101, 102], WorkPackage.find(3).changeset_ids

    # fixed issues
    fixed_work_package.reload
    assert fixed_work_package.status.is_closed?
    assert_equal 90, fixed_work_package.done_ratio
    assert_equal [101], fixed_work_package.changeset_ids

    # issue change
    journal = fixed_work_package.journals.last
    assert_equal User.find_by_login('dlopper'), journal.user
    assert_equal 'Applied in changeset r2.', journal.notes

    # 2 email notifications to 5 users
    assert_equal 5, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries.first
    assert_kind_of Mail::Message, mail
    assert mail.subject.starts_with?("[#{fixed_work_package.project.name} - #{fixed_work_package.type.name} ##{fixed_work_package.id}]")
    assert mail.body.encoded.include?("Status changed from #{old_status} to #{fixed_work_package.status}")

    # ignoring commits referencing an issue of another project
    assert_equal [], WorkPackage.find(4).changesets
  end

  it 'should for changeset comments strip' do
    repository = Repository::Subversion.create(project: Project.find(4), url: 'svn://:login:password@host:/path/to/the/repository')
    comment = 'This is a looooooooooooooong comment' + (' ' * 80 + "\n") * 5
    changeset = Changeset.new(
      comments: comment, commit_date: Time.now, revision: 0, scmid: 'f39b7922fb3c',
      committer: 'foo <foo@example.com>', committed_on: Time.now, repository: repository)
    assert(changeset.save)
    assert_not_equal(comment, changeset.comments)
    assert_equal('This is a looooooooooooooong comment', changeset.comments)
  end

  it 'should for urls strip' do
    repository = Repository::Subversion.create(
      project: Project.find(4),
      url: ' svn://:login:password@host:/path/to/the/repository',
      log_encoding: 'UTF-8')
    repository.root_url = 'foo  ' # can't mass-assign this attr
    assert repository.save
    repository.reload
    assert_equal 'svn://:login:password@host:/path/to/the/repository', repository.url
    assert_equal 'foo', repository.root_url
  end

  it 'should manual user mapping' do
    assert_no_difference "Changeset.count(:conditions => 'user_id <> 2')" do
      c = Changeset.create!(repository: @repository, committer: 'foo', committed_on: Time.now, revision: 100, comments: 'Committed by foo.')
      assert_nil c.user
      @repository.committer_ids = { 'foo' => '2' }
      assert_equal User.find(2), c.reload.user
      # committer is now mapped
      c = Changeset.create!(repository: @repository, committer: 'foo', committed_on: Time.now, revision: 101, comments: 'Another commit by foo.')
      assert_equal User.find(2), c.user
    end
  end

  it 'should auto user mapping by username' do
    c = Changeset.create!(repository: @repository, committer: 'jsmith', committed_on: Time.now, revision: 100, comments: 'Committed by john.')
    assert_equal User.find(2), c.user
  end

  it 'should auto user mapping by email' do
    c = Changeset.create!(repository: @repository, committer: 'john <jsmith@somenet.foo>', committed_on: Time.now, revision: 100, comments: 'Committed by john.')
    assert_equal User.find(2), c.user
  end
end
