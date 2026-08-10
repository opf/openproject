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
    # Servers speaking the OpenAI API: OpenAI itself, and the great majority of
    # gateways and self-hosted inference servers.
    class Openai
      def initialize(connection)
        @connection = connection
      end

      # Normalised model cards.
      #
      # The raw card is kept alongside, because the fields worth having are the
      # non-standard ones: the OpenAI schema itself carries only id, object,
      # created and owned_by, while vLLM adds max_model_len -- the operator's
      # actual --max-model-len, and the only trustworthy context window for this
      # deployment.
      #
      # @return [Array<Hash>] cards with :id and :raw
      def models
        @models ||= Array(client.models["data"]).filter_map do |card|
          id = card["id"]
          next if id.blank?

          { id:, raw: card }
        end
      end

      def embeddings(model_id:, input:)
        client.embeddings(model: model_id, input:)
      end

      # Which server we are talking to decides which non-standard metadata is
      # worth reading later. +owned_by+ is the documented hint; the structural
      # fallback catches an operator who overrode it.
      def server_flavour
        cards = models
        owner = cards.first&.dig(:raw, "owned_by").to_s.downcase

        return owner if %w[vllm sglang llamacpp openai].include?(owner)

        cards.any? { |card| card[:raw].key?("max_model_len") || card[:raw].key?("root") } ? "vllm" : "unknown"
      end

      private

      attr_reader :connection

      def client
        @client ||= Llm::Client.new(base_url: connection.base_url,
                                    api_key: connection.api_key,
                                    headers: connection.custom_headers)
      end
    end
  end
end
