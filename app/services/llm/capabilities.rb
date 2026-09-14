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
  # The capabilities a model may have, and how to read the published ones.
  module Capabilities
    ALL = %i[embeddings function_calling structured_output vision reasoning].freeze

    # Capabilities a chat model can be asked about. +embeddings+ is deliberately
    # absent: it is a different kind of model, not a feature of a chat one.
    CHAT = (ALL - %i[embeddings]).freeze
    EMBEDDING = %i[embeddings].freeze

    module_function

    # What a public registry says about this model id.
    #
    # Advisory only. The registry describes a model as some vendor deploys it,
    # which is not the same as this deployment: the same weights are catalogued
    # with contradictory capability flags and context windows an order of
    # magnitude apart across providers. Verdicts derived from it are therefore
    # recorded with source "metadata", and an administrator can overrule them.
    #
    # @return [Hash{Symbol => Symbol}, nil] capability => :supported / :unsupported,
    #   or nil when the registry does not know the model -- the normal case for a
    #   self-hosted server.
    def published_for(model_id)
      info = RubyLLM.models.find(model_id)

      { states: states_from(info), context_window: info.context_window, display_name: info.name }
    rescue RubyLLM::ModelNotFoundError
      nil
    rescue StandardError => e
      # Registry lookup is an enrichment; it must never break a model sync.
      Rails.logger.info { "LLM capability lookup for #{model_id} failed: #{e.class} #{e.message}" }
      nil
    end

    def states_from(info)
      embedding = info.type.to_s == "embedding"
      published = Array(info.capabilities).map(&:to_sym)
      relevant = embedding ? EMBEDDING : CHAT

      states = relevant.index_with { |capability| published.include?(capability) ? :supported : :unsupported }
      states.merge(embeddings: embedding ? :supported : :unsupported)
    end

    def label(capability)
      I18n.t("llm.capabilities.#{capability}.label")
    end
  end
end
