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

module LlmConnections
  # Refreshes the cached model catalogue from the remote server.
  #
  # Kept separate from the contract probe so that the same code path serves the
  # "Refresh models" button, the update service and the environment seeder.
  class SyncModelsService
    def initialize(connection)
      @connection = connection
    end

    def call
      store(catalogue_attributes(client.models))

      ServiceResult.success(result: connection)
    rescue Llm::Client::Error => e
      Rails.logger.info { "LLM model sync for #{connection.base_url} failed: #{e.class} #{e.message}" }
      ServiceResult.failure(errors: e.message)
    end

    private

    attr_reader :connection

    def store(attributes)
      ActiveRecord::Base.transaction do
        discard_verdicts_for_a_different_deployment(attributes[:connection_fingerprint])
        connection.update!(attributes)
        discard_verdicts_for_vanished_models
      end
    end

    # A changed base URL or key means we are talking to a different deployment,
    # so everything we learned about the old one is void -- including
    # administrator assertions, which were about that deployment, not this one.
    def discard_verdicts_for_a_different_deployment(fingerprint)
      return if connection.connection_fingerprint.blank?
      return if connection.connection_fingerprint == fingerprint

      connection.capability_verdicts.delete_all
    end

    # Same deployment, but a model is gone. Its verdict is meaningless now, except
    # an administrator's assertion: an operator restarting a server must not
    # silently lose one.
    def discard_verdicts_for_vanished_models
      known = connection.catalogue_model_ids
      return if known.empty?

      connection.capability_verdicts.where.not(model_id: known).where.not(source: "admin").delete_all
    end

    def catalogue_attributes(catalogue)
      now = Time.current

      {
        catalogue:,
        catalogue_fetched_at: now,
        last_connected_at: now,
        connection_fingerprint: fingerprint,
        options: connection.options.merge("server_flavour" => detect_server_flavour(catalogue))
      }
    end

    def client
      Llm::Client.new(base_url: connection.base_url, api_key: connection.api_key)
    end

    def fingerprint
      Digest::SHA256.hexdigest("#{connection.base_url}\0#{connection.api_key}")
    end

    # Which server we are talking to decides which non-standard metadata endpoint
    # is worth asking later. +owned_by+ is the documented hint; the structural
    # fallback catches servers whose operator overrode it.
    def detect_server_flavour(catalogue)
      cards = Array(catalogue["data"])
      owner = cards.first&.dig("owned_by").to_s.downcase

      case owner
      when "vllm", "sglang", "llamacpp", "openai" then owner
      else
        cards.any? { |card| card.key?("max_model_len") || card.key?("root") } ? "vllm" : "unknown"
      end
    end
  end
end
