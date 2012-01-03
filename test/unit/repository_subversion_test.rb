#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

class RepositorySubversionTest < ActiveSupport::TestCase
  fixtures :projects, :repositories, :enabled_modules, :users, :roles

  def setup
    @project = Project.find(3)
    @repository = Repository::Subversion.create(:project => @project,
             :url => self.class.subversion_repository_url)
    assert @repository
  end

  if repository_configured?('subversion')
    def test_fetch_changesets_from_scratch
      @repository.fetch_changesets
      @repository.reload

      assert_equal 11, @repository.changesets.count
      assert_equal 20, @repository.changes.count
      assert_equal 'Initial import.', @repository.changesets.find_by_revision('1').comments
    end

    def test_fetch_changesets_incremental
      @repository.fetch_changesets
      # Remove changesets with revision > 5
      @repository.changesets.find(:all).each {|c| c.destroy if c.revision.to_i > 5}
      @repository.reload
      assert_equal 5, @repository.changesets.count

      @repository.fetch_changesets
      assert_equal 11, @repository.changesets.count
    end

    def test_latest_changesets
      @repository.fetch_changesets

      # with limit
      changesets = @repository.latest_changesets('', nil, 2)
      assert_equal 2, changesets.size
      assert_equal @repository.latest_changesets('', nil).slice(0,2), changesets

      # with path
      changesets = @repository.latest_changesets('subversion_test/folder', nil)
      assert_equal ["10", "9", "7", "6", "5", "2"], changesets.collect(&:revision)

      # with path and revision
      changesets = @repository.latest_changesets('subversion_test/folder', 8)
      assert_equal ["7", "6", "5", "2"], changesets.collect(&:revision)
    end

    def test_directory_listing_with_square_brackets_in_path
      @repository.fetch_changesets
      @repository.reload

      entries = @repository.entries('subversion_test/[folder_with_brackets]')
      assert_not_nil entries, 'Expect to find entries in folder_with_brackets'
      assert_equal 1, entries.size, 'Expect one entry in folder_with_brackets'
      assert_equal 'README.txt', entries.first.name
    end

    def test_directory_listing_with_square_brackets_in_base
      @project = Project.find(3)
      @repository = Repository::Subversion.create(
                          :project => @project,
                          :url => "file:///#{self.class.repository_path('subversion')}/subversion_test/[folder_with_brackets]")

      @repository.fetch_changesets
      @repository.reload

      assert_equal 1, @repository.changesets.count, 'Expected to see 1 revision'
      assert_equal 2, @repository.changes.count, 'Expected to see 2 changes, dir add and file add'

      entries = @repository.entries('')
      assert_not_nil entries, 'Expect to find entries'
      assert_equal 1, entries.size, 'Expect a single entry'
      assert_equal 'README.txt', entries.first.name
    end

    def test_identifier
      @repository.fetch_changesets
      @repository.reload
      c = @repository.changesets.find_by_revision('1')
      assert_equal c.revision, c.identifier
    end

    def test_find_changeset_by_empty_name
      @repository.fetch_changesets
      @repository.reload
      ['', ' ', nil].each do |r|
        assert_nil @repository.find_changeset_by_name(r)
      end
    end

    def test_identifier_nine_digit
      c = Changeset.new(:repository => @repository, :committed_on => Time.now,
                        :revision => '123456789', :comments => 'test')
      assert_equal c.identifier, c.revision
    end

    def test_format_identifier
      @repository.fetch_changesets
      @repository.reload
      c = @repository.changesets.find_by_revision('1')
      assert_equal c.format_identifier, c.revision
    end

    def test_format_identifier_nine_digit
      c = Changeset.new(:repository => @repository, :committed_on => Time.now,
                        :revision => '123456789', :comments => 'test')
      assert_equal c.format_identifier, c.revision
    end

    def test_activities
      c = Changeset.create(:repository => @repository, :committed_on => Time.now,
                        :revision => '1', :comments => 'test')
      assert c.event_title.include?('1:')
      assert_equal '1', c.event_url[:rev]
    end

    def test_activities_nine_digit
      c = Changeset.create(:repository => @repository, :committed_on => Time.now,
                        :revision => '123456789', :comments => 'test')
      assert c.event_title.include?('123456789:')
      assert_equal '123456789', c.event_url[:rev]
    end

    def test_log_encoding_ignore_setting
      with_settings :commit_logs_encoding => 'windows-1252' do
        s1 = "\xC2\x80"
        s2 = "\xc3\x82\xc2\x80"
        if s1.respond_to?(:force_encoding)
          s1.force_encoding('ISO-8859-1')
          s2.force_encoding('UTF-8')
          assert_equal s1.encode('UTF-8'), s2
        end
        c = Changeset.new(:repository => @repository,
                          :comments   => s2,
                          :revision   => '123',
                          :committed_on => Time.now)
        assert c.save
        assert_equal s2, c.comments
      end
    end

    def test_previous
      @repository.fetch_changesets
      @repository.reload
      changeset = @repository.find_changeset_by_name('3')
      assert_equal @repository.find_changeset_by_name('2'), changeset.previous
    end

    def test_previous_nil
      @repository.fetch_changesets
      @repository.reload
      changeset = @repository.find_changeset_by_name('1')
      assert_nil changeset.previous
    end

    def test_next
      @repository.fetch_changesets
      @repository.reload
      changeset = @repository.find_changeset_by_name('2')
      assert_equal @repository.find_changeset_by_name('3'), changeset.next
    end

    def test_next_nil
      @repository.fetch_changesets
      @repository.reload
      changeset = @repository.find_changeset_by_name('11')
      assert_nil changeset.next
    end
  else
    puts "Subversion test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
