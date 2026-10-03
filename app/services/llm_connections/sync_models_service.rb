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
    # A catalogue no administrator could read through anyway, and an upper bound
    # on how many rows one unbounded response can write.
    MAX_CARDS = 2_000

    def initialize(connection)
      @connection = connection
    end

    def call
      # Before the fetch, so that a deployment change invalidates the old state
      # even when the new server refuses the model list: keeping the previous
      # deployment's models and verdicts for another server would be wrong.
      invalidate_a_different_deployment

      store(fetched_cards)
      Llm::DetectCapabilitiesJob.perform_later

      ServiceResult.success(result: connection)
    rescue Llm::Client::Error => e
      failed("failed: #{e.class} #{e.message}", e.message)
    rescue ActiveRecord::ActiveRecordError => e
      # Two syncs racing find_or_initialize_by can hit a uniqueness violation.
      failed("could not be stored: #{e.class}", e.class.to_s)
    end

    private

    attr_reader :connection

    def failed(reason, errors)
      Rails.logger.info { "LLM model sync for #{connection.base_url} #{reason}" }

      ServiceResult.failure(errors:)
    end

    def adapter
      @adapter ||= Llm::Adapters.for(connection)
    end

    def fetched_cards
      capped(storable(adapter.models))
    end

    def storable(cards)
      oversized, fitting = cards.partition { |card| card.fetch(:id).to_s.length > LlmModel::MAX_EXTERNAL_ID_LENGTH }
      return cards if oversized.empty?

      Rails.logger.warn do
        "LLM server at #{connection.base_url} listed #{oversized.size} models with an id longer than " \
          "#{LlmModel::MAX_EXTERNAL_ID_LENGTH} characters; skipping them"
      end
      fitting
    end

    def capped(cards)
      return cards if cards.size <= MAX_CARDS

      Rails.logger.warn do
        "LLM server at #{connection.base_url} listed #{cards.size} models; storing the first #{MAX_CARDS}"
      end
      cards.first(MAX_CARDS)
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
        last_synced_at: now,
        last_connected_at: now,
        connection_fingerprint: fingerprint,
        options: connection.options.merge("server_flavour" => adapter.server_flavour)
      }
    end

    def fingerprint
      @fingerprint ||= connection.settings_fingerprint
    end

    def upsert(cards)
      now = Time.current

      cards.each do |card|
        model = connection.models.find_or_initialize_by(external_id: card.fetch(:id))
        model.update!(raw_metadata: merged_metadata(model, card),
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

    # A changed base URL or API format means a different deployment, so what
    # the registry and the probes established about the old one is void. What
    # an administrator asserted is theirs and survives, as it does on a refresh.
    def invalidate_a_different_deployment
      return if connection.connection_fingerprint.blank?
      return if connection.connection_fingerprint == fingerprint

      forget_the_previous_deployment
    end

    # Only a successful fetch records the fingerprint (see
    # +connection_attributes+), so a failed refresh leaves the list stale.
    #
    # Discovered rows are deleted rather than switched off. Withdrawal is for a
    # model the same server stopped offering, where a verdict pointing at it
    # still names something real; here the server itself is gone, and a list of
    # another deployment's models is not a catalogue but a leftover. Manual
    # entries stay: an administrator typed those, and a server change does not
    # un-type them.
    #
    # The two default_*_model_id columns reference llm_models with
    # on_delete: :nullify, so the database clears them as the rows go. A feature
    # bound to one is released here, because the binding names a string and
    # would otherwise silently re-attach to whatever the new server happens to
    # call by the same name. Administrator assertions survive, as they do on an
    # ordinary refresh: they are statements about a model, not about a server.
    def forget_the_previous_deployment
      ActiveRecord::Base.transaction do
        discard_discovered_models(connection.models.discovered.pluck(:external_id))
      end

      connection.reload
    end

    def discard_discovered_models(discarded)
      connection.models.discovered.delete_all
      connection.capability_verdicts.where.not(source: "admin").delete_all
      connection.feature_bindings.where(model_id: discarded).delete_all
    end

    # The administrator's context-window override is theirs, and a routine
    # refresh must not silently discard it.
    #
    # The incoming card is stripped of the override's key first. Without that, a
    # server sending "admin_context_window" of its own would have it stored
    # verbatim and reported as an administrator's.
    def merged_metadata(model, card)
      raw = normalised_window(card.fetch(:raw, {})).except("admin_context_window")
      admin_window = model.raw_metadata["admin_context_window"]

      admin_window ? raw.merge("admin_context_window" => admin_window) : raw
    end

    # OpenRouter and gateways following it publish the window as
    # +context_length+, where vLLM and SGLang report +max_model_len+, the
    # operator's actual limit and therefore the better figure of the two.
    def normalised_window(raw)
      return raw if raw["context_length"].blank? || raw["max_model_len"].present?

      raw.merge("context_window" => raw["context_length"])
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
