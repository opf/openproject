# frozen_string_literal: true

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

class RepresentedWebhookJob < WebhookJob
  attr_reader :resource, :actor

  def perform(webhook_id, resource, event_name, actor: nil)
    @resource = resource
    @actor = actor
    super(webhook_id, event_name)

    return unless accepted_in_project?

    body = request_body
    headers = request_headers

    if (signature = request_signature(body))
      headers["X-OP-Signature"] = signature
    end

    ::Webhooks::Outgoing::RequestWebhookService
      .new(webhook, event_name:, current_user: User.system)
      .call!(body:, headers:)
  end

  def accepted_in_project?
    webhook.enabled_for_project?(project_id)
  end

  def request_signature(request_body)
    if (secret = webhook.secret.presence)
      "sha1=#{OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret, request_body)}"
    end
  end

  def request_headers
    {
      "Content-Type": "application/json",
      Accept: "application/json"
    }
  end

  def represented_payload
    payload_representer_class
      .create(resource, current_user: User.current, embed_links: true)
  end

  def payload_key
    raise SubclassResponsibilityError
  end

  def payload_representer_class
    raise SubclassResponsibilityError
  end

  def project_id # rubocop:disable Rails/Delegate
    resource.project_id
  end

  def request_body
    # to_json needs to be called within the system user block in order to
    # have all the custom field visibility permissions set up correctly.
    User.system.run_given do
      payload = { action: event_name, payload_key => represented_payload }
      payload[:actor] = actor_payload if actor
      payload.to_json
    end
  end

  def actor_payload
    return nil unless actor

    ::API::V3::Users::UserRepresenter.create(actor, current_user: User.current)
  end
end
