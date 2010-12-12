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

class RepositoryBazaarTest < ActiveSupport::TestCase
  fixtures :projects
  
  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/bazaar_repository'
  REPOSITORY_PATH.gsub!(/\/+/, '/')

  def setup
    @project = Project.find(1)
    assert @repository = Repository::Bazaar.create(:project => @project, :url => "file:///#{REPOSITORY_PATH}")
  end
  
  if File.directory?(REPOSITORY_PATH)  
    def test_fetch_changesets_from_scratch
      @repository.fetch_changesets
      @repository.reload
      
      assert_equal 4, @repository.changesets.count
      assert_equal 9, @repository.changes.count
      assert_equal 'Initial import', @repository.changesets.find_by_revision('1').comments
    end
    
    def test_fetch_changesets_incremental
      @repository.fetch_changesets
      # Remove changesets with revision > 5
      @repository.changesets.find(:all).each {|c| c.destroy if c.revision.to_i > 2}
      @repository.reload
      assert_equal 2, @repository.changesets.count
      
      @repository.fetch_changesets
      assert_equal 4, @repository.changesets.count
    end
    
    def test_entries
      entries = @repository.entries
      assert_equal 2, entries.size
      
      assert_equal 'dir', entries[0].kind
      assert_equal 'directory', entries[0].name
      
      assert_equal 'file', entries[1].kind
      assert_equal 'doc-mkdir.txt', entries[1].name
    end
    
    def test_entries_in_subdirectory
      entries = @repository.entries('directory')
      assert_equal 3, entries.size

      assert_equal 'file', entries.last.kind
      assert_equal 'edit.png', entries.last.name
    end
    
    def test_cat
      cat = @repository.scm.cat('directory/document.txt')
      assert cat =~ /Write the contents of a file as of a given revision to standard output/
    end
    
    def test_annotate
      annotate = @repository.scm.annotate('doc-mkdir.txt')
      assert_equal 17, annotate.lines.size
      assert_equal 1, annotate.revisions[0].identifier
      assert_equal 'jsmith@', annotate.revisions[0].author
      assert_equal 'mkdir', annotate.lines[0]
    end
  else
    puts "Bazaar test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
