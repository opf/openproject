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
# Implements the asynchronous deletion of a local repository.
Scm::DeleteManagedRepositoryService = Struct.new :repository do
  ##
  # Checks if a given repository may be deleted
  # Registers an asynchronous job to delete the repository on disk.
  #
  def call
    if repository.managed?

      # Create necessary changes to repository to mark
      # it as managed by OP, but delete asynchronously.
      managed_path = repository.managed_repository_path
      parents = repository.parent_projects

      if File.directory?(managed_path)
        ##
        # We want to move this functionality in a Delayed Job,
        # but this heavily interferes with the error handling of the whole
        # repository management process.
        # Instead, this will be refactored into a single service wrapper for
        # creating and deleting repositories, which provides transactional DB access
        # as well as filesystem access.
        Scm::DeleteRepositoryJob.new(managed_path, parents).perform
      end

      true
    else
      false
    end
  end
end
