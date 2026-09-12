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
# persisted. It is guarded on the attributes that identify the connection:
# without that guard every unrelated save -- and every form render that builds a
# model through SetAttributesService -- would fire an outbound HTTP request.
class LlmServerValidator < ActiveModel::EachValidator
  # Changing any of these means talking to a different server, or to the same
  # server in a different dialect, so the connection must be proven again and
  # its models resynchronised.
  CONNECTION_ATTRIBUTES = %w[base_url api_key api_format].freeze

  # Statuses that mean "this server has no model list here", as opposed to "this
  # server is broken". A gateway may route chat completions and nothing else.
  MODELS_ENDPOINT_ABSENT = [404, 405, 501].freeze

  def validate_each(contract, attribute, value)
    return if value.blank?
    return unless queries_the_server?(contract)
    return unless connection_changed?(contract)
    return unless host_allowed?(contract, attribute, value)

    probe(contract, attribute, value)
  end

  private

  # Only OpenAI-compatible connections discover models from the server. For the
  # other formats the list comes from the model registry, so there is nothing at
  # this URL to probe.
  def queries_the_server?(contract)
    contract.model.api_format == Llm::Adapters::OPENAI_COMPATIBLE
  end

  def connection_changed?(contract)
    contract.model.changed_attributes.keys.intersect?(CONNECTION_ATTRIBUTES)
  end

  # A pre-flight check purely so the administrator gets an actionable message
  # naming the environment variable, rather than a bare connection failure from
  # the transport-level SSRF filter.
  def host_allowed?(contract, attribute, value)
    host = URI.parse(value).host
    return false if host.blank?

    addresses = resolve(host)
    if addresses.empty?
      # Nothing resolved: a typo or a DNS problem, not a policy decision.
      contract.errors.add(attribute, :cannot_be_connected_to)
      return false
    end

    return true if addresses.any? { |address| OpenProject::SsrfProtection.safe_ip?(address) }

    contract.errors.add(attribute, :ssrf_filtered, env_name: ssrf_allowlist_env_name)
    false
  rescue URI::InvalidURIError
    false
  end

  def resolve(host)
    return [IPAddr.new(host)] if host.match?(Resolv::IPv4::Regex) || host.match?(Resolv::IPv6::Regex)

    OpenProject::SsrfProtection.resolver.call(host)
  rescue Resolv::ResolvError, IPAddr::InvalidAddressError
    []
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

  # A missing model list does not block the save.
  #
  # The server answered, so it is reachable and the credentials were accepted; it
  # simply does not offer a list here. OpenProject's own hosted gateway is exactly
  # this case, and it will not be the only one. Blocking would leave an
  # administrator unable to save a working connection -- and unable to reach the
  # manual model entry that exists for precisely this situation.
  def add_api_error(contract, attribute, error)
    return if error.status.in?(MODELS_ENDPOINT_ABSENT)

    contract.errors.add(attribute, :not_openai_compatible)
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
