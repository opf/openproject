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
  # Fills in what a public registry publishes about the models a connection offers.
  #
  # This is the "the provider tells us" path. A hosted provider's model ids are
  # catalogued, so capabilities arrive without asking the server anything. A
  # self-hosted deployment naming its model "default" or "my-finetune-v3" is not
  # catalogued, nothing is filled in, and the administrator enters capabilities
  # by hand instead.
  #
  # An administrator's assertion is never overwritten: they know things about
  # their deployment that no registry can.
  class EnrichCapabilitiesService
    def initialize(connection)
      @connection = connection
    end

    def call
      connection.models.active.find_each { |llm_model| enrich(llm_model) }

      ServiceResult.success(result: connection)
    end

    private

    attr_reader :connection

    def enrich(llm_model)
      published = Llm::Capabilities.published_for(llm_model.external_id)
      return if published.nil?

      apply_metadata(llm_model, published)
      published[:states].each { |capability, state| record(llm_model.external_id, capability, state) }
    end

    def apply_metadata(llm_model, published)
      attributes = {}
      attributes[:display_name] = published[:display_name] if llm_model.display_name.blank?

      if published[:context_window].present? && llm_model.raw_metadata["max_model_len"].blank?
        attributes[:raw_metadata] = llm_model.raw_metadata.merge("context_window" => published[:context_window])
      end

      llm_model.update!(attributes) if attributes.any?
    end

    def record(model_id, capability, state)
      verdict = connection.capability_verdicts.find_or_initialize_by(model_id:, capability: capability.to_s)
      # Anything an administrator or a probe established beats a published claim:
      # both looked at this deployment, the registry did not.
      return if verdict.persisted? && verdict.source.in?(%w[admin probe])

      verdict.update!(state: state.to_s, source: "metadata", checked_at: Time.current)
    end
  end
end
