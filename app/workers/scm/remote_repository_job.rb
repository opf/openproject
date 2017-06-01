#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

##
# Provides an asynchronous job to create a managed repository on the filesystem.
# Currently, this is run synchronously due to potential issues
# with error handling.
# We envision a repository management wrapper that covers transactional
# creation and deletion of repositories BOTH on the database and filesystem.
# Until then, a synchronous process is more failsafe.
class Scm::RemoteRepositoryJob < ApplicationJob
  attr_reader :repository

  ##
  # Initialize the job, optionally saving the whole repository object
  # (use only when not serializing the job.)
  # As we're using the jobs majorly synchronously for the time being, it saves a db trip.
  # When we have error handling for asynchronous tasks, refactor this.
  def initialize(repository, perform_now: false)
    if perform_now
      @repository = repository
    else
      @repository_id = repository.id
    end
  end

  protected

  ##
  # Submits the request to the configured managed remote as JSON.
  def send_request(request)
    uri = repository.class.managed_remote
    req = ::Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = request.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.verify_mode = configured_verification
    response = http.request(req)

    info = try_to_parse_response(response.body)

    unless response.is_a? ::Net::HTTPSuccess
      raise OpenProject::Scm::Exceptions::ScmError.new(
              I18n.t('repositories.errors.remote_call_failed',
                     code: response.code,
                     message: info['message']
              )
            )
    end

    info
  end

  def try_to_parse_response(body)
    JSON.parse(body)
  rescue JSON::JSONError => e
    raise OpenProject::Scm::Exceptions::ScmError.new(
            I18n.t('repositories.errors.remote_invalid_response')
          )
  end

  def repository_request
    project = repository.project

    {
      token: repository.scm.config[:access_token],
      identifier: repository.repository_identifier,
      vendor: repository.vendor,
      scm_type: repository.scm_type,
      project: {
        id: project.id,
        name: project.name,
        identifier: project.identifier,
      }
    }
  end

  def repository
    @repository ||= Repository.find(@repository_id)
  end

  ##
  # For packager and snakeoil-ssl certificates, we need to provide the user
  # with an option to skip SSL certificate verification when communicating
  # with the remote repository manager.
  # It may be overridden in the +configuration.yml+.
  def configured_verification
    insecure = repository.class.scm_config[:insecure]
    if insecure
      OpenSSL::SSL::VERIFY_NONE
    else
      OpenSSL::SSL::VERIFY_PEER
    end
  end
end
