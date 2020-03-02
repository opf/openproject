#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

##
# Provides an asynchronous job to relocate a managed repository on the local or remote system
class SCM::RelocateRepositoryJob < SCM::RemoteRepositoryJob
  queue_with_priority :low

  def perform(repository)
    super(repository)

    if repository.class.manages_remote?
      relocate_remote
    else
      relocate_on_disk
    end
  end

  private

  ##
  # POST to the remote managed repository a request to relocate the repository
  def relocate_remote
    response = send_request(repository_request.merge(
       action: :relocate,
       old_identifier: File.basename(repository.root_url)))
    repository.root_url = response['path']
    repository.url = response['url']

    unless repository.save
      Rails.logger.error("Could not relocate the remote repository " \
                         "#{repository.repository_identifier}.")
    end
  end

  ##
  # Tries to relocate the repository on disk.
  # As we're performing this in a job and currently have no explicit means
  # of error handling in this context, there's not much to do here in case of failure.
  def relocate_on_disk
    FileUtils.mv repository.root_url, repository.managed_repository_path
    repository.update_columns(root_url: repository.managed_repository_path,
                              url: repository.managed_repository_url)
  end
end
