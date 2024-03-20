#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# Implements the creation of a local repository.
class SCM::CreateManagedRepositoryService < SCM::BaseRepositoryService
  ##
  # Checks if a given repository may be created and managed locally.
  # Registers an job to create the repository on disk.
  #
  # @return True if the repository creation request has been initiated, false otherwise.
  def call
    if repository.managed? && repository.manageable?

      ##
      # We want to move this functionality in a Delayed Job,
      # but this heavily interferes with the error handling of the whole
      # repository management process.
      # Instead, this will be refactored into a single service wrapper for
      # creating and deleting repositories, which provides transactional DB access
      # as well as filesystem access.
      if repository.class.manages_remote?
        SCM::CreateRemoteRepositoryJob.perform_now(repository)
      else
        SCM::CreateLocalRepositoryJob.ensure_not_existing!(repository)
        SCM::CreateLocalRepositoryJob.perform_later(repository)
      end
      return true
    end

    false
  rescue Errno::EACCES
    @rejected = I18n.t('repositories.errors.path_permission_failed',
                       path: repository.root_url)
    false
  rescue SystemCallError => e
    @rejected = I18n.t('repositories.errors.filesystem_access_failed',
                       message: e.message)
    false
  rescue OpenProject::SCM::Exceptions::SCMError => e
    @rejected = e.message
    false
  end

  ##
  # Returns the error symbol
  def localized_rejected_reason
    @rejected ||= I18n.t('repositories.errors.not_manageable')
  end
end
