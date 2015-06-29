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

class Scm::DeleteRepositoryJob
  def initialize(root, managed_path)
    @managed_root = root
    @managed_path = managed_path
  end

  def perform
    Dir.chdir(@managed_root) do
      # Delete the repository project itself.
      FileUtils.remove_dir(@managed_path)

      # Traverse all parent directories within repositories,
      # searching for empty project directories.
      parent = Pathname.new(@managed_path).parent
      remove_empty_parents(parent)
    end
  end

  def destroy_failed_jobs?
    true
  end

  private

  def remove_empty_parents(parent)
    managed_root_path = Pathname.new(@managed_root)
    loop do
      # Stop deletion upon finding a non-empty parent repository
      break unless parent.children.empty?

      # Stop if we're in the project root
      break if parent == managed_root_path

      FileUtils.rmdir(parent)

      parent = parent.parent
    end
  end
end
