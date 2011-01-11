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

class RepositoryGitTest < ActiveSupport::TestCase
  fixtures :projects, :repositories, :enabled_modules, :users, :roles 
  
  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/git_repository'
  REPOSITORY_PATH.gsub!(/\//, "\\") if Redmine::Platform.mswin?
  
  def setup
    @project = Project.find(1)
    assert @repository = Repository::Git.create(:project => @project, :url => REPOSITORY_PATH)
  end
  
  if File.directory?(REPOSITORY_PATH)  
    def test_fetch_changesets_from_scratch
      @repository.fetch_changesets
      @repository.reload
      
      assert_equal 15, @repository.changesets.count
      assert_equal 24, @repository.changes.count
      
      commit = @repository.changesets.find(:first, :order => 'committed_on ASC')
      assert_equal "Initial import.\nThe repository contains 3 files.", commit.comments
      assert_equal "jsmith <jsmith@foo.bar>", commit.committer
      assert_equal User.find_by_login('jsmith'), commit.user
      # TODO: add a commit with commit time <> author time to the test repository
      assert_equal "2007-12-14 09:22:52".to_time, commit.committed_on
      assert_equal "2007-12-14".to_date, commit.commit_date
      assert_equal "7234cb2750b63f47bff735edc50a1c0a433c2518", commit.revision
      assert_equal "7234cb2750b63f47bff735edc50a1c0a433c2518", commit.scmid
      assert_equal 3, commit.changes.count
      change = commit.changes.sort_by(&:path).first
      assert_equal "README", change.path
      assert_equal "A", change.action
    end
    
    def test_fetch_changesets_incremental
      @repository.fetch_changesets
      # Remove the 3 latest changesets
      @repository.changesets.find(:all, :order => 'committed_on DESC', :limit => 3).each(&:destroy)
      @repository.reload
      assert_equal 12, @repository.changesets.count
      
      @repository.fetch_changesets
      assert_equal 15, @repository.changesets.count
    end

    def test_identifier
      @repository.fetch_changesets
      @repository.reload
      c = @repository.changesets.find_by_revision('7234cb2750b63f47bff735edc50a1c0a433c2518')
      assert_equal c.scmid, c.identifier
    end

    def test_format_identifier
      @repository.fetch_changesets
      @repository.reload
      c = @repository.changesets.find_by_revision('7234cb2750b63f47bff735edc50a1c0a433c2518')
      assert_equal '7234cb27', c.format_identifier
    end

    def test_activities
      c = Changeset.new(:repository => @repository,
                        :committed_on => Time.now,
                        :revision => 'abc7234cb2750b63f47bff735edc50a1c0a433c2',
                        :scmid    => 'abc7234cb2750b63f47bff735edc50a1c0a433c2',
                        :comments => 'test')
      assert c.event_title.include?('abc7234c:')
      assert_equal 'abc7234cb2750b63f47bff735edc50a1c0a433c2', c.event_url[:rev]
    end
  else
    puts "Git test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
