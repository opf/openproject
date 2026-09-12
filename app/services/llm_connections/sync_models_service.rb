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
  # Refreshes the model list from the remote server.
  #
  # Kept separate from the contract probe so the same path serves the "Refresh
  # models" button, the update service and the environment seeder.
  class SyncModelsService
    def initialize(connection)
      @connection = connection
    end

    def call
      # Before the fetch, so that a deployment change invalidates the old state
      # even when the new server refuses the model list: keeping the previous
      # deployment's models and verdicts under new credentials would be wrong.
      invalidate_a_different_deployment

      store(adapter.models)

      ServiceResult.success(result: connection)
    rescue Llm::Client::Error => e
      Rails.logger.info { "LLM model sync for #{connection.base_url} failed: #{e.class} #{e.message}" }
      ServiceResult.failure(errors: e.message)
    end

    private

    attr_reader :connection

    def adapter
      @adapter ||= Llm::Adapters.for(connection)
    end

    def store(cards)
      ActiveRecord::Base.transaction do
        connection.update!(connection_attributes)
        upsert(cards)
        withdraw_models_absent_from(cards)
        discard_verdicts_for_vanished_models
      end

      EnrichCapabilitiesService.new(connection).call
    end

    def connection_attributes
      now = Time.current

      {
        catalogue_fetched_at: now,
        last_connected_at: now,
        connection_fingerprint: fingerprint,
        options: connection.options.merge("server_flavour" => adapter.server_flavour)
      }
    end

    def fingerprint
      @fingerprint ||= Digest::SHA256.hexdigest("#{connection.api_format}\0#{connection.base_url}\0#{connection.api_key}")
    end

    def upsert(cards)
      now = Time.current

      cards.each do |card|
        model = connection.models.find_or_initialize_by(external_id: card.fetch(:id))
        model.update!(display_name: card[:display_name],
                      raw_metadata: merged_metadata(model, card),
                      last_seen_at: now,
                      active: true)
      end
    end

    # Deactivated rather than deleted, so a binding or verdict pointing at one
    # still has something to name. Manual entries are left alone: the server was
    # never the thing that confirmed them.
    # where.not against an empty id list matches nothing, so an empty catalogue
    # needs its own branch to withdraw everything discovered.
    def withdraw_models_absent_from(cards)
      ids = cards.map { |card| card.fetch(:id) }
      scope = connection.models.discovered
      scope = scope.where.not(external_id: ids) if ids.any?

      scope.update_all(active: false)
    end

    # A changed base URL or key means a different deployment, so everything we
    # learned about the old one is void -- including administrator assertions,
    # which were about that deployment.
    def invalidate_a_different_deployment
      return if connection.connection_fingerprint.blank?
      return if connection.connection_fingerprint == fingerprint

      forget_the_previous_deployment
    end

    def forget_the_previous_deployment
      ActiveRecord::Base.transaction do
        connection.capability_verdicts.delete_all
        connection.models.discovered.update_all(active: false)
        connection.update!(connection_fingerprint: fingerprint)
      end
    end

    # The server names the model; the administrator's context-window override is
    # theirs, and a routine refresh must not silently discard it.
    def merged_metadata(model, card)
      raw = card.fetch(:raw, {})
      admin_window = model.raw_metadata["admin_context_window"]

      admin_window ? raw.merge("admin_context_window" => admin_window) : raw
    end

    # Same deployment, but a model is gone. Its verdict is meaningless now,
    # except an administrator's assertion: an operator restarting a server must
    # not silently lose one.
    def discard_verdicts_for_vanished_models
      known = connection.available_model_ids
      scope = connection.capability_verdicts.where.not(source: "admin")
      scope = scope.where.not(model_id: known) if known.any?

      scope.delete_all
    end
  end
end
