require 'rest-client'

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

class RepresentedWebhookJob < WebhookJob
  include ::OpenProjectErrorHelper

  attr_reader :resource

  def perform(webhook_id, resource, event_name)
    @resource = resource
    super(webhook_id, event_name)

    return unless accepted_in_project?

    body = request_body
    headers = request_headers
    exception = nil
    response = nil

    if signature = request_signature(body)
      headers['X-OP-Signature'] = signature
    end

    begin
      response = RestClient.post webhook.url, request_body, headers
    rescue RestClient::Exception => e
      response = e.response
      exception = e
    rescue StandardError => e
      op_handle_error(e.message, reference: :webhook_job)
      exception = e
    end

    ::Webhooks::Log.create(
      webhook: webhook,
      event_name: event_name,
      url: webhook.url,
      request_headers: headers,
      request_body: body,
      response_code: response.try(:code).to_i,
      response_headers: response.try(:headers),
      response_body: response.try(:to_s) || exception.try(:message)
    )
  end

  def accepted_in_project?
    webhook.enabled_for_project?(resource.project_id)
  end

  def request_signature(request_body)
    if secret = webhook.secret.presence
      'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret, request_body)
    end
  end

  def request_headers
    {
      content_type: "application/json",
      accept: "application/json"
    }
  end

  def payload_key
    raise NotImplementedError
  end

  def payload_representer
    raise NotImplementedError
  end

  def request_body
    {
      :action => event_name,
      payload_key => payload_representer
    }.to_json
  end
end
