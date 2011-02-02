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
require 'pp'
class RepositoryCvsTest < ActiveSupport::TestCase
  fixtures :projects
  
  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/cvs_repository'
  REPOSITORY_PATH.gsub!(/\//, "\\") if Redmine::Platform.mswin?
  # CVS module
  MODULE_NAME = 'test'
  
  def setup
    @project = Project.find(3)
    assert @repository = Repository::Cvs.create(:project => @project, 
                                                :root_url => REPOSITORY_PATH,
                                                :url => MODULE_NAME)
  end
  
  if File.directory?(REPOSITORY_PATH)  
    def test_fetch_changesets_from_scratch
      assert_equal 0, @repository.changesets.count
      @repository.fetch_changesets
      @repository.reload
      
      assert_equal 5, @repository.changesets.count
      assert_equal 14, @repository.changes.count
      assert_not_nil @repository.changesets.find_by_comments('Two files changed')
    end
    
    def test_fetch_changesets_incremental
      assert_equal 0, @repository.changesets.count
      @repository.fetch_changesets
      # Remove the 3 latest changesets
      @repository.changesets.find(:all, :order => 'committed_on DESC', :limit => 3).each(&:destroy)
      @repository.reload
      assert_equal 2, @repository.changesets.count
      
      @repository.fetch_changesets
      assert_equal 5, @repository.changesets.count
    end
    
    def test_deleted_files_should_not_be_listed
      assert_equal 0, @repository.changesets.count
      @repository.fetch_changesets
      @repository.reload
      assert_equal 5, @repository.changesets.count

      entries = @repository.entries('sources')
      assert entries.detect {|e| e.name == 'watchers_controller.rb'}
      assert_nil entries.detect {|e| e.name == 'welcome_controller.rb'}
    end
  else
    puts "CVS test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
