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
  module Probes
    # Determines whether a model can produce embeddings, by asking it to.
    #
    # This is the only behavioural probe in the system, and it qualifies because
    # it cannot lie: a server either returns a vector or it does not. Probes for
    # tool calling deliberately do not exist -- several current vLLM releases
    # return HTTP 200 with the tool call as plain text on a fully capable server,
    # deterministically, so retries would launder a wrong answer into a confident
    # one rather than correcting it.
    #
    # The 200 case is checked by shape rather than by status, because unknown
    # parameters are silently dropped by vLLM, llama.cpp and Ollama alike: a 200
    # on its own proves nothing.
    class EmbeddingsProbe
      PROBE_INPUT = "openproject"

      Result = Data.define(:state, :detail) do
        def supported? = state == :supported
      end

      def initialize(connection)
        @connection = connection
      end

      def call(model_id)
        body = client.embeddings(model: model_id, input: PROBE_INPUT)
        classify(body)
      rescue Llm::Client::ApiError => e
        # The server understood the request and refused it for this model.
        return unsupported(e.status) if e.status.in?([400, 404, 405, 501])

        # 5xx and anything else says something about the server, not the model.
        unknown("http_#{e.status}")
      rescue Llm::Client::AuthenticationError
        unknown("unauthorized")
      rescue Llm::Client::Error => e
        unknown(e.class.name.demodulize.underscore)
      end

      private

      attr_reader :connection

      def client
        @client ||= Llm::Client.new(base_url: connection.base_url, api_key: connection.api_key)
      end

      def classify(body)
        vector = Array(body["data"]).first&.dig("embedding")

        if vector.is_a?(Array) && vector.any? && vector.all?(Numeric)
          Result.new(state: :supported, detail: { "dimensions" => vector.length })
        else
          # A 200 whose body is not an embedding response: the server accepted the
          # request but answered with something else entirely.
          unknown("unexpected_body")
        end
      end

      def unsupported(status)
        Result.new(state: :unsupported, detail: { "http_status" => status })
      end

      def unknown(reason)
        Result.new(state: :unknown, detail: { "reason" => reason })
      end
    end
  end
end
