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
  # Records what a model on this server can do.
  #
  # Probing every listed model would be wrong: a gateway can list hundreds, each
  # probe is a request, and some providers bill per request. So the models worth
  # asking about are either the one an administrator is about to bind, or a small
  # number whose names suggest they are embedding models.
  class DetectCapabilitiesService
    # Naming is a hint for which models are worth spending a probe on, never a
    # verdict in itself.
    EMBEDDING_NAME_HINT = %r{embed|bge|nomic|minilm|(^|[-_./])(e5|gte)}i
    BACKGROUND_LIMIT = 10
    RETRY_INCONCLUSIVE_AFTER = 1.day

    def initialize(connection)
      @connection = connection
    end

    # Probes a specific model, synchronously. Used when an administrator binds a
    # model to a feature that requires embeddings -- the verdict that matters.
    #
    # @return [ServiceResult] carrying the verdict
    def detect(model_id)
      return ServiceResult.success(result: existing_admin_verdict(model_id)) if admin_asserted?(model_id)

      result = probe.call(model_id)
      ServiceResult.success(result: record(model_id, result))
    end

    # Pre-colours the model list after a connect, without spending a request per
    # model. Everything not probed stays unknown, which never blocks.
    #
    # @return [ServiceResult] carrying the verdicts that were recorded
    def detect_likely_embedding_models
      recorded = []

      candidates.each do |model_id|
        result = probe.call(model_id)
        recorded << record(model_id, result)
        break if server_wide_failure?(result)
      end

      ServiceResult.success(result: recorded.compact)
    end

    private

    attr_reader :connection

    def probe
      @probe ||= Llm::Probes::EmbeddingsProbe.new(connection)
    end

    # Narrowed before anything is sent, because a probe is a billed request on
    # some providers: only models whose name suggests they embed at all, never
    # one that is already settled, and never more than the batch limit in one
    # background run. A definite probe verdict can be trusted until a sync
    # discards it, which it does when the deployment behind the connection
    # changes or the model disappears from it. A model the probe could not
    # answer for a reason of its own is not asked again within a day.
    def candidates
      settled = settled_model_ids

      connection.available_model_ids
                .grep(EMBEDDING_NAME_HINT)
                .reject { |model_id| settled.include?(model_id) }
                .first(BACKGROUND_LIMIT)
    end

    def settled_model_ids
      embedding_verdicts = verdicts.for_capability(:embeddings)

      embedding_verdicts.sticky
                        .or(embedding_verdicts.source_probe.where.not(state: :unknown))
                        .pluck(:model_id)
                        .to_set
                        .merge(backed_off_model_ids(embedding_verdicts))
    end

    def backed_off_model_ids(embedding_verdicts)
      embedding_verdicts.source_probe
                        .unknown
                        .where(checked_at: RETRY_INCONCLUSIVE_AFTER.ago..)
                        .pluck(:model_id, :detail)
                        .reject { |_, detail| Llm::Probes::EmbeddingsProbe.server_wide?(detail["reason"]) }
                        .map(&:first)
    end

    # The server answered for itself, not for this model, so the requests the
    # rest of the batch would spend buy the same answer again. The stored
    # verdict may have turned definite while the probe ran, and this
    # inconclusive answer leaves it in place, so only the probe result says
    # what happened now.
    def server_wide_failure?(result)
      result.state == :unknown && Llm::Probes::EmbeddingsProbe.server_wide?(result.detail["reason"])
    end

    # An administrator knows things about their deployment that a probe cannot
    # determine, so their assertion is never overwritten by re-detection.
    def admin_asserted?(model_id)
      verdicts.for_model(model_id).for_capability(:embeddings).sticky.exists?
    end

    def existing_admin_verdict(model_id)
      verdicts.for_model(model_id).for_capability(:embeddings).first
    end

    def record(model_id, result)
      verdicts.transaction do
        break unless deployment_unchanged?

        verdict = claim(model_id)
        # A refresh deletes probe verdicts and may have done so right after the
        # insert, leaving nothing to record against.
        break if verdict.nil?
        # Re-checked under the row lock: a probe runs for seconds, and an
        # administrator may have asserted the capability in the meantime.
        break verdict if verdict.source_admin?
        # A probe that learned nothing must not soften a definite verdict:
        # only :unsupported blocks, so downgrading it to :unknown on a transient
        # failure would quietly make a rejected model usable again.
        break verdict if result.state == :unknown && !verdict.unknown?

        verdict.update!(state: result.state.to_s,
                        source: "probe",
                        detail: result.detail,
                        checked_at: Time.current)
        verdict
      end
    end

    # A sync for another deployment discards the probe verdicts, and an answer
    # from the previous one arriving afterwards must not bring one back. The row
    # lock orders this read against the settings change that starts that sync.
    def deployment_unchanged?
      LlmConnection.lock.find_by(id: connection.id)&.settings_fingerprint == connection.settings_fingerprint
    end

    # FOR UPDATE has no row to lock before the first probe of a model, and a
    # synchronous detection can run alongside the background pass: inserting
    # through the unique index lands both on the same row.
    def claim(model_id)
      verdicts.insert_all([{ llm_connection_id: connection.id,
                             model_id:,
                             capability: "embeddings",
                             state: "unknown",
                             source: "probe",
                             checked_at: Time.current }],
                          unique_by: %i[llm_connection_id model_id capability])

      verdicts.for_model(model_id).for_capability(:embeddings).lock.first
    end

    def verdicts
      connection.capability_verdicts
    end
  end
end
