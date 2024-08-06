#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

##
# Provides an asynchronous job to create a managed repository on the filesystem.
# Currently, this is run synchronously due to potential issues
# with error handling.
# We envision a repository management wrapper that covers transactional
# creation and deletion of repositories BOTH on the database and filesystem.
# Until then, a synchronous process is more failsafe.
class SCM::CreateLocalRepositoryJob < ApplicationJob
  def self.ensure_not_existing!(repository)
    # Cowardly refusing to override existing local repository
    if File.directory?(repository.root_url)
      raise OpenProject::SCM::Exceptions::SCMError.new(
        I18n.t("repositories.errors.exists_on_filesystem")
      )
    end
  end

  def perform(repository)
    @repository = repository

    self.class.ensure_not_existing!(repository)

    # Create the repository locally.
    mode = config[:mode] || default_mode

    # Ensure that chmod receives an octal number
    unless mode.is_a? Integer
      mode = mode.to_i(8)
    end

    create(mode)

    # Allow adapter to act upon the created repository
    # e.g., initializing an empty scm repository within it
    repository.managed_repo_created

    # Ensure group ownership after creation
    ensure_group(mode, config[:group])
  end

  def destroy_failed_jobs?
    true
  end

  private

  ##
  # Creates the repository at the +root_url+.
  # Accepts an overridden permission mode mask from the scm config,
  # or sets a sensible default of 0700.
  def create(mode)
    FileUtils.mkdir_p(repository.root_url, mode:)
  end

  ##
  # Overrides the group permission of the created repository
  # after the adapter was able to work in the directory.
  def ensure_group(mode, group)
    FileUtils.chmod_R(mode, repository.root_url)

    # Note that this is effectively a noop when group is nil,
    # and then permissions remain OPs runuser/-group
    FileUtils.chown_R(nil, group, repository.root_url)
  end

  def config
    @config ||= repository.class.scm_config
  end

  def repository
    @repository
  end

  def default_mode
    0o700
  end
end
