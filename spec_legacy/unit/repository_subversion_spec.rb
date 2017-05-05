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

describe Repository::Subversion, type: :model do
  fixtures :all

  before do
    skip 'Subversion test repository NOT FOUND. Skipping unit tests !!!' unless repository_configured?('subversion')

    @project = Project.find(3)
    @repository = Repository::Subversion.create(project: @project,
                                                scm_type: 'existing',
                                                url: self.class.subversion_repository_url)
    assert @repository
  end

  it 'should fetch changesets from scratch' do
    @repository.fetch_changesets
    @repository.reload

    assert_equal 14, @repository.changesets.count
    assert_equal 34, @repository.file_changes.count
    assert_equal 'Initial import.', @repository.changesets.find_by(revision: '1').comments
  end

  it 'should fetch changesets incremental' do
    @repository.fetch_changesets
    # Remove changesets with revision > 5
    @repository.changesets.each do |c| c.destroy if c.revision.to_i > 5 end
    @repository.reload
    assert_equal 5, @repository.changesets.count

    @repository.fetch_changesets
    assert_equal 14, @repository.changesets.count
  end

  it 'should latest changesets' do
    @repository.fetch_changesets

    # with limit
    changesets = @repository.latest_changesets('', nil, 2)
    assert_equal 2, changesets.size
    assert_equal @repository.latest_changesets('', nil).take(2), changesets

    # with path
    changesets = @repository.latest_changesets('subversion_test/folder', nil)
    assert_equal ['10', '9', '7', '6', '5', '2'], changesets.map(&:revision)

    # with path and revision
    changesets = @repository.latest_changesets('subversion_test/folder', 8)
    assert_equal ['7', '6', '5', '2'], changesets.map(&:revision)
  end

  it 'should directory listing with square brackets in path' do
    @repository.fetch_changesets
    @repository.reload

    entries = @repository.entries('subversion_test/[folder_with_brackets]')
    refute_nil entries, 'Expect to find entries in folder_with_brackets'
    assert_equal 1, entries.size, 'Expect one entry in folder_with_brackets'
    assert_equal 'README.txt', entries.first.name
  end

  it 'should directory listing with square brackets in base' do
    @project = Project.find(3)
    @repository = Repository::Subversion.create(
      project: @project,
      scm_type: 'local',
      url: "file:///#{self.class.repository_path('subversion')}/subversion_test/[folder_with_brackets]")

    @repository.fetch_changesets
    @repository.reload

    assert_equal 1, @repository.changesets.count, 'Expected to see 1 revision'
    assert_equal 2, @repository.file_changes.count, 'Expected to see 2 changes, dir add and file add'

    entries = @repository.entries('')
    refute_nil entries, 'Expect to find entries'
    assert_equal 1, entries.size, 'Expect a single entry'
    assert_equal 'README.txt', entries.first.name
  end

  it 'should identifier' do
    @repository.fetch_changesets
    @repository.reload
    c = @repository.changesets.find_by(revision: '1')
    assert_equal c.revision, c.identifier
  end

  it 'should find changeset by empty name' do
    @repository.fetch_changesets
    @repository.reload
    ['', ' ', nil].each do |r|
      assert_nil @repository.find_changeset_by_name(r)
    end
  end

  it 'should identifier nine digit' do
    c = Changeset.new(repository: @repository, committed_on: Time.now,
                      revision: '123456789', comments: 'test')
    assert_equal c.identifier, c.revision
  end

  it 'should format identifier' do
    @repository.fetch_changesets
    @repository.reload
    c = @repository.changesets.find_by(revision: '1')
    assert_equal c.format_identifier, c.revision
  end

  it 'should format identifier nine digit' do
    c = Changeset.new(repository: @repository, committed_on: Time.now,
                      revision: '123456789', comments: 'test')
    assert_equal c.format_identifier, c.revision
  end

  it 'should activities' do
    c = Changeset.create(repository: @repository, committed_on: Time.now,
                         revision: '1', comments: 'test')
    event = find_events(User.find(2)).first # manager
    assert event.event_title.include?('1:')
    assert event.event_path =~ /\?rev=1$/
  end

  it 'should activities nine digit' do
    c = Changeset.create(repository: @repository, committed_on: Time.now,
                         revision: '123456789', comments: 'test')
    event = find_events(User.find(2)).first # manager
    assert event.event_title.include?('123456789:')
    assert event.event_path =~ /\?rev=123456789$/
  end

  it 'should log encoding ignore setting' do
    Setting.commit_logs_encoding = 'windows-1252'
    s1 = "\xC2\x80"
    s2 = "\xc3\x82\xc2\x80"
    if s1.respond_to?(:force_encoding)
      s1.force_encoding('ISO-8859-1')
      s2.force_encoding('UTF-8')
      assert_equal s1.encode('UTF-8'), s2
    end
    c = Changeset.new(repository: @repository,
                      comments:   s2,
                      revision:   '123',
                      committed_on: Time.now)
    assert c.save
    assert_equal s2, c.comments
  end

  it 'should previous' do
    @repository.fetch_changesets
    @repository.reload
    changeset = @repository.find_changeset_by_name('3')
    assert_equal @repository.find_changeset_by_name('2'), changeset.previous
  end

  it 'should previous nil' do
    @repository.fetch_changesets
    @repository.reload
    changeset = @repository.find_changeset_by_name('1')
    assert_nil changeset.previous
  end

  it 'should next' do
    @repository.fetch_changesets
    @repository.reload
    changeset = @repository.find_changeset_by_name('2')
    assert_equal @repository.find_changeset_by_name('3'), changeset.next
  end

  it 'should next nil' do
    @repository.fetch_changesets
    @repository.reload
    changeset = @repository.find_changeset_by_name('14')
    assert_nil changeset.next
  end

  private

  def find_events(user, options = {})
    fetcher = Redmine::Activity::Fetcher.new(user, options)
    fetcher.scope = ['changesets']
    fetcher.events(Date.today - 30, Date.today + 1)
  end
end
