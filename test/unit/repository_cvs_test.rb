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
require 'pp'
class RepositoryCvsTest < Test::Unit::TestCase
  fixtures :projects
  
  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/cvs_repository'
  REPOSITORY_PATH.gsub!(/\//, "\\") if RUBY_PLATFORM =~ /mswin/
  # CVS module
  MODULE_NAME = 'test'
  
  def setup
    @project = Project.find(1)
    assert @repository = Repository::Cvs.create(:project => @project, 
                                                :root_url => REPOSITORY_PATH,
                                                :url => MODULE_NAME)
  end
  
  if File.directory?(REPOSITORY_PATH)  
    def test_fetch_changesets_from_scratch
      @repository.fetch_changesets
      @repository.reload
      
      assert_equal 5, @repository.changesets.count
      assert_equal 14, @repository.changes.count
      assert_equal 'Two files changed', @repository.changesets.find_by_revision(3).comments
    end
    
    def test_fetch_changesets_incremental
      @repository.fetch_changesets
      # Remove changesets with revision > 2
      @repository.changesets.find(:all, :conditions => 'revision > 2').each(&:destroy)
      @repository.reload
      assert_equal 2, @repository.changesets.count
      
      @repository.fetch_changesets
      assert_equal 5, @repository.changesets.count
    end
  else
    puts "CVS test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
