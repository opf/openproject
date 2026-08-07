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
    EMBEDDING_NAME_HINT = /embed|bge|e5|gte|nomic|minilm/i
    BACKGROUND_LIMIT = 10

    def initialize(connection)
      @connection = connection
    end

    # Probes a specific model, synchronously. Used when an administrator binds a
    # model to a feature that requires embeddings -- the verdict that matters.
    def detect(model_id)
      return existing_admin_verdict(model_id) if admin_asserted?(model_id)

      result = probe.call(model_id)
      record(model_id, result)
    end

    # Pre-colours the model list after a connect, without spending a request per
    # model. Everything not probed stays unknown, which never blocks.
    def detect_likely_embedding_models
      candidates.each { |model_id| detect(model_id) }
    end

    private

    attr_reader :connection

    def probe
      @probe ||= Llm::Probes::EmbeddingsProbe.new(connection)
    end

    def candidates
      connection.catalogue_model_ids
                .grep(EMBEDDING_NAME_HINT)
                .reject { |model_id| admin_asserted?(model_id) }
                .first(BACKGROUND_LIMIT)
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
      verdict = verdicts.find_or_initialize_by(model_id:, capability: "embeddings")
      verdict.update!(state: result.state.to_s,
                      source: "probe",
                      detail: result.detail,
                      checked_at: Time.current)
      verdict
    end

    def verdicts
      connection.capability_verdicts
    end
  end
end
