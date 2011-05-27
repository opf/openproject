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

class RepositoryFilesystemTest < ActiveSupport::TestCase
  fixtures :projects

  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/filesystem_repository'

  def setup
    @project = Project.find(3)
    Setting.enabled_scm = Setting.enabled_scm.dup << 'Filesystem' unless Setting.enabled_scm.include?('Filesystem')
    assert @repository = Repository::Filesystem.create(
                            :project => @project, :url => REPOSITORY_PATH)
  end

  if File.directory?(REPOSITORY_PATH)  
    def test_fetch_changesets
      @repository.fetch_changesets
      @repository.reload

      assert_equal 0, @repository.changesets.count
      assert_equal 0, @repository.changes.count
    end

    def test_entries
      assert_equal 3, @repository.entries("", 2).size
      assert_equal 2, @repository.entries("dir", 3).size
    end

    def test_cat
      assert_equal "TEST CAT\n", @repository.scm.cat("test")
    end

  else
    puts "Filesystem test repository NOT FOUND. Skipping unit tests !!! See doc/RUNNING_TESTS."
    def test_fake; assert true end
  end
end
