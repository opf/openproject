#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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

##
# Provides an asynchronous job to delete a managed repository on the filesystem.
# Currently, this is run synchronously due to potential issues
# with error handling.
# We envision a repository management wrapper that covers transactional
# creation and deletion of repositories BOTH on the database and filesystem.
# Until then, a synchronous process is more failsafe.
class Scm::DeleteRepositoryJob
  def initialize(managed_path, parents)
    @managed_path = managed_path
    @parents = parents
  end

  def perform
    # Delete the repository project itself.
    FileUtils.remove_dir(@managed_path)

    # Traverse all parent directories within repositories,
    # searching for empty project directories.
    remove_empty_parents
  end

  def destroy_failed_jobs?
    true
  end

  private

  def remove_empty_parents

    parent_path = Pathname.new(@managed_path).parent

    ##
    # Iterate the hierarchy in reverse, looking
    # for empty directories that equal the parent identifier name
    # but are empty.
    @parents.reverse_each do |parent|

      # Stop unless the given parent path is the parent project path
      break unless parent_path.basename.to_s == parent

      # Stop deletion upon finding a non-empty parent repository
      break unless parent_path.exist? && parent_path.children.empty?

      FileUtils.rmdir(parent_path)

      parent_path = parent_path.parent
    end
  end
end
