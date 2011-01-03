# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

require File.expand_path('../../test_helper', __FILE__)

class RepositorySubversionTest < ActiveSupport::TestCase
  fixtures :projects, :repositories, :enabled_modules, :users, :roles 
  
  def setup
    @project = Project.find(1)
    assert @repository = Repository::Subversion.create(:project => @project, :url => "file:///#{self.class.repository_path('subversion')}")
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
      @project = Project.find(1)
      @repository = Repository::Subversion.create(:project => @project, :url => "file:///#{self.class.repository_path('subversion')}/subversion_test/[folder_with_brackets]")

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
      c = Changeset.new(:repository => @repository, :committed_on => Time.now,
                        :revision => '1', :comments => 'test')
      assert c.event_title.include?('1:')
      assert_equal c.event_url[:rev], '1'
    end

    def test_activities_nine_digit
      c = Changeset.new(:repository => @repository, :committed_on => Time.now,
                        :revision => '123456789', :comments => 'test')
      assert c.event_title.include?('123456789:')
      assert_equal c.event_url[:rev], '123456789'
    end
  else
    puts "Subversion test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
