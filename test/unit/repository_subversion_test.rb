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

require File.dirname(__FILE__) + '/../test_helper'

class RepositorySubversionTest < Test::Unit::TestCase
  fixtures :projects
  
  # No '..' in the repository path for svn
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/subversion_repository'
  
  def setup
    @project = Project.find(1)
    assert @repository = Repository::Subversion.create(:project => @project, :url => "file:///#{REPOSITORY_PATH}")
  end
  
  if File.directory?(REPOSITORY_PATH)  
    def test_fetch_changesets_from_scratch
      @repository.fetch_changesets
      @repository.reload
      
      assert_equal 8, @repository.changesets.count
      assert_equal 16, @repository.changes.count
      assert_equal 'Initial import.', @repository.changesets.find_by_revision('1').comments
    end
    
    def test_fetch_changesets_incremental
      @repository.fetch_changesets
      # Remove changesets with revision > 5
      @repository.changesets.find(:all).each {|c| c.destroy if c.revision.to_i > 5}
      @repository.reload
      assert_equal 5, @repository.changesets.count
      
      @repository.fetch_changesets
      assert_equal 8, @repository.changesets.count
    end
    
    def test_changesets_for_path_with_limit
      @repository.fetch_changesets
      changesets = @repository.changesets_for_path('', :limit => 2)
      assert_equal 2, changesets.size
      assert_equal @repository.changesets_for_path('').slice(0,2), changesets
    end
  else
    puts "Subversion test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
