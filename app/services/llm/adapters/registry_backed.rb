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
    # Discovery for providers that do not speak the OpenAI model-list API.
    #
    # Anthropic, Gemini, Bedrock and the rest each list models differently -- and
    # some, like Bedrock, need request signing rather than a bearer token. Rather
    # than implement each, the model list comes from RubyLLM's registry for that
    # provider, which is a published catalogue rather than a live query.
    #
    # The consequence is worth stating: this list is what the provider offers in
    # general, not what these particular credentials can reach. An administrator
    # can add anything missing by hand.
    class RegistryBacked
      def initialize(connection)
        @connection = connection
      end

      def models
        RubyLLM.models.by_provider(connection.api_format.to_sym).map do |info|
          {
            id: info.id,
            display_name: info.name,
            raw: { "context_window" => info.context_window, "owned_by" => connection.api_format }
          }
        end
      rescue StandardError => e
        raise Llm::Client::ApiError.new("Model registry lookup failed: #{e.class} #{e.message}", status: nil)
      end

      # Nothing is queried, so there is no server to characterise.
      def server_flavour = connection.api_format

      private

      attr_reader :connection
    end
  end
end
