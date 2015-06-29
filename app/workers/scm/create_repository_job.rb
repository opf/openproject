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

class Scm::CreateRepositoryJob
  def initialize(repository, managed_path)
    @id = repository.id
    @managed_path = managed_path
  end

  def perform
    # Create the repository locally.
    mode = config[:mode] || default_mode
    create(mode)

    # Allow adapter to act upon the created repository
    # e.g., initializing an empty scm repository within it
    repository.managed_repo_created

    # Ensure ownership after creation
    ensure_ownership(mode, config[:owner], config[:group])
  end

  def destroy_failed_jobs?
    true
  end

  private

  ##
  # Creates the repository at the +@managed_path+.
  # Accepts an overriden permission mode mask from the scm config,
  # or sets a sensible default of 0700.
  def create(mode)
    FileUtils.mkdir_p(@managed_path, mode: mode)
  end

  ##
  # Overrides the owner/group permission of the created repository
  # after the adapter was able to work in the directory.
  def ensure_ownership(mode, owner, group)
    FileUtils.chmod_R(mode, @managed_path)

    # Note that this is effectively a noop when owner or group is nil,
    # and then permissions remain OPs runuser/-group
    FileUtils.chown_R(owner, group, @managed_path)
  end

  def config
    @config ||= repository.scm.config
  end

  def repository
    @repository ||= Repository.find @id
  end

  def default_mode
    0700
  end
end
