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
    # The 200 case is checked by shape rather than by status, because unknown
    # parameters are silently dropped by vLLM, llama.cpp and Ollama alike: a 200
    # on its own proves nothing.
    class EmbeddingsProbe
      PROBE_INPUT = "openproject"

      # The server understood the request and refused it for this model. Anything
      # else -- 5xx, throttling -- says something about the server, not the model.
      REFUSED_STATUSES = [400, 404, 405, 501].freeze

      Result = Data.define(:state, :detail) do
        def supported? = state == :supported
      end

      def initialize(connection)
        @connection = connection
      end

      def call(model_id)
        classify(session.embed(PROBE_INPUT, model: model_id))
      rescue Llm::Errors::ApiError => e
        return unsupported(e.status) if e.status.in?(REFUSED_STATUSES)

        unknown("http_#{e.status}")
      rescue Llm::Errors::AuthenticationError
        unknown("unauthorized")
      rescue Llm::Errors::Error => e
        unknown(e.class.name.demodulize.underscore)
      end

      private

      attr_reader :connection

      # Never retried: a refusal is the answer we are looking for, and repeating
      # it would only slow the probe down.
      def session
        @session ||= Llm::Session.for(connection, timeout: Llm::Session::PROBE_TIMEOUT, max_retries: 0)
      end

      def classify(embedding)
        vector = embedding.vectors
        vector = vector.first if vector.is_a?(Array) && vector.first.is_a?(Array)

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
