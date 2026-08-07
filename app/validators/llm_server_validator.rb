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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Verifies that the configured URL really is an OpenAI-API-compatible server that
# accepts the configured credentials, by fetching its model list.
#
# Runs inside the contract so that a server which cannot be reached never gets
# persisted. It is guarded on the credential attributes: without that guard every
# unrelated save -- and every form render that builds a model through
# SetAttributesService -- would fire an outbound HTTP request.
class LlmServerValidator < ActiveModel::EachValidator
  CREDENTIAL_ATTRIBUTES = %w[base_url api_key].freeze

  def validate_each(contract, attribute, value)
    return if value.blank?
    return unless credentials_changed?(contract)
    return unless host_allowed?(contract, attribute, value)

    probe(contract, attribute, value)
  end

  private

  def credentials_changed?(contract)
    contract.model.changed_attributes.keys.intersect?(CREDENTIAL_ATTRIBUTES)
  end

  # A pre-flight check purely so the administrator gets an actionable message
  # naming the environment variable, rather than a bare connection failure from
  # the transport-level SSRF filter.
  def host_allowed?(contract, attribute, value)
    host = URI.parse(value).host
    return false if host.blank?
    return true if OpenProject::SsrfProtection.safe_ip?(host)

    contract.errors.add(attribute, :ssrf_filtered, env_name: ssrf_allowlist_env_name)
    false
  rescue URI::InvalidURIError
    false
  end

  def ssrf_allowlist_env_name
    Settings::Definition[:ssrf_protection_ip_allowlist].env_name
  end

  def probe(contract, attribute, value)
    client(contract, value).models
  rescue Llm::Client::Error => e
    log(value, e)
    add_error(contract, attribute, e)
  end

  # Order matters: SsrfError and TimeoutError are both ConnectionError subclasses.
  def add_error(contract, attribute, error)
    case error
    when Llm::Client::SsrfError
      contract.errors.add(attribute, :ssrf_filtered, env_name: ssrf_allowlist_env_name)
    when Llm::Client::AuthenticationError
      contract.errors.add(:api_key, :invalid_api_key)
    when Llm::Client::TimeoutError
      contract.errors.add(attribute, :request_timed_out)
    when Llm::Client::ConnectionError
      contract.errors.add(attribute, :cannot_be_connected_to)
    when Llm::Client::ApiError
      add_api_error(contract, attribute, error)
    else
      contract.errors.add(attribute, :not_openai_compatible)
    end
  end

  # A 404 is worth separating: the server answered, so it is reachable and the
  # credentials were not the problem. Either the URL is missing or carries the
  # wrong version segment, or the server genuinely does not expose a model list.
  def add_api_error(contract, attribute, error)
    if error.status == 404
      contract.errors.add(attribute, :models_endpoint_missing, path: "#{contract.model.base_url}/models")
    else
      contract.errors.add(attribute, :not_openai_compatible)
    end
  end

  def client(contract, base_url)
    Llm::Client.new(base_url:, api_key: contract.model.api_key)
  end

  # The upstream message is logged but never surfaced: an OpenAI-compatible
  # gateway routinely echoes credentials and internal hostnames in error bodies.
  def log(base_url, error)
    Rails.logger.info { "LLM connection probe to #{base_url} failed: #{error.class} #{error.message}" }
  end
end
