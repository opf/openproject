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

module Llm
  # Refreshes the cached model catalogue out of band.
  #
  # Used by the environment seeder, which must not block on -- or fail because of
  # -- an LLM server that has not finished starting.
  class SyncModelsJob < ApplicationJob
    class SyncFailed < StandardError; end
    class NoModelsYet < StandardError; end

    Failure = Data.define(:error, :reason)

    # The tenth and last attempt starts roughly 4.5 hours after the first.
    retry_on SyncFailed, wait: :polynomially_longer, attempts: 10

    # An empty sync records last_synced_at like any other, so which connections
    # had never synced is taken on the first attempt and carried through the
    # retries.
    def serialize
      super.merge("never_synced_ids" => @never_synced_ids)
    end

    def deserialize(job_data)
      super
      @never_synced_ids = job_data["never_synced_ids"]
    end

    def perform
      @never_synced_ids ||= LlmConnection.where(last_synced_at: nil).ids
      failures = LlmConnection.find_each.filter_map { |connection| failure_for(connection) }
      return if failures.empty?

      reasons = failures.map(&:reason).join("; ")
      raise SyncFailed, reasons if failures.any? { |failure| transient?(failure.error) }

      Rails.logger.warn { "LLM model sync failed and will not be retried: #{reasons}" }
    end

    private

    # Every connection is attempted before anything is raised. One server still
    # starting, or one row carrying a format no adapter serves, must not leave
    # the connections after it without a catalogue.
    def failure_for(connection)
      started_at = Time.current
      result = LlmConnections::SyncModelsService.new(connection).call
      return still_loading(connection, since: started_at) if result.success?

      Failure.new(error: result.result, reason: result.errors.to_s)
    rescue StandardError => e
      Rails.logger.error { "LLM model sync failed for connection #{connection.id}: #{e.class}" }
      Failure.new(error: e, reason: e.class.to_s)
    end

    # An Ollama sidecar answers with an empty list while it still pulls its model.
    def still_loading(connection, since:)
      return unless @never_synced_ids.include?(connection.id) && connection.models.where(last_seen_at: since..).none?

      Failure.new(error: NoModelsYet.new, reason: "No models listed yet")
    end

    def transient?(error)
      case error
      when NoModelsYet, ActiveRecord::ActiveRecordError then true
      else Llm::Errors.transient?(error)
      end
    end
  end
end
