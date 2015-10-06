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
# Provides an asynchronous job to create a managed repository on the filesystem.
# Currently, this is run synchronously due to potential issues
# with error handling.
# We envision a repository management wrapper that covers transactional
# creation and deletion of repositories BOTH on the database and filesystem.
# Until then, a synchronous process is more failsafe.
class Scm::RemoteRepositoryJob
  include OpenProject::BeforeDelayedJob

  def initialize(repository)
    # TODO currently uses the full repository object,
    # as the Job is performed synchronously.
    # Change this to serialize the ID once its turned to process asynchronously.
    @repository = repository
  end

  protected

  ##
  # Submits the request to the configured managed remote as JSON.
  def send(request)
    uri = @repository.class.managed_remote
    req = ::Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = request.to_json

    ::Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
  end

  def repository_request
    project = @repository.project

    {
      identifier: @repository.repository_identifier,
      vendor: @repository.vendor,
      scm_type: @repository.scm_type,
      project: {
        id: project.id,
        name: project.name,
        identifier: project.identifier,
      }
    }
  end
end
