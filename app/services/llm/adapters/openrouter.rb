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
  module Adapters
    # OpenRouter, whose catalogue is served in several parts.
    #
    # GET /models answers with the chat catalogue alone. Embedding models are
    # served only to a request that asks for them by output modality, so
    # discovering them takes a second call.
    class Openrouter < Openai
      EMBEDDINGS_FILTER = { output_modalities: "embeddings" }.freeze

      def server_flavour = "openrouter"

      private

      def fetch_models
        chat = cards(client.models)
        chat + embedding_cards.reject { |card| chat.any? { |listed| listed[:id] == card[:id] } }
      end

      # A gateway configured with this format need not implement the filter. It
      # may answer with the unfiltered catalogue, which the caller deduplicates,
      # or refuse the request, which must not cost the administrator the chat
      # catalogue they did get.
      def embedding_cards
        cards(client.models(EMBEDDINGS_FILTER))
      rescue Llm::Client::Error => e
        Rails.logger.info { "LLM embedding model discovery for #{connection.base_url} failed: #{e.class} #{e.message}" }
        []
      end
    end
  end
end
