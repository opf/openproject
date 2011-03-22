# Redmine - project management software
# Copyright (C) 2006-2011  Jean-Philippe Lang
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
require 'repositories_controller'

# Re-raise errors caught by the controller.
class RepositoriesController; def rescue_action(e) raise e end; end

class RepositoriesFilesystemControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :repositories, :enabled_modules

  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/filesystem_repository'
  PRJ_ID = 3

  def setup
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    Setting.enabled_scm << 'Filesystem' unless Setting.enabled_scm.include?('Filesystem')
    @repository = Repository::Filesystem.create(
                      :project => Project.find(PRJ_ID),
                      :url     => REPOSITORY_PATH,
                      :path_encoding => ''
                      )
    assert @repository
  end

  if File.directory?(REPOSITORY_PATH)
    def test_browse_root
      @repository.fetch_changesets
      @repository.reload
      get :show, :id => 3
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert assigns(:entries).size > 0
      assert_not_nil assigns(:changesets)
      assert assigns(:changesets).size == 0
    end
  else
    puts "Filesystem test repository NOT FOUND. Skipping functional tests !!!"
    def test_fake; assert true end
  end
end
