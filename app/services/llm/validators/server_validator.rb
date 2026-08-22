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
  module Validators
    # Whether the server answers, and whether it accepts our credentials.
    #
    # Uses the model list, which costs nothing on any provider. That only exists
    # for OpenAI-compatible endpoints -- for the others the catalogue comes from
    # RubyLLM's registry, so there is nothing free to ask, and reachability can
    # only be established by the inference group's billed request.
    class ServerValidator < HealthReports::ValidatorGroup
      # A gateway may implement chat and nothing else. That is a supported
      # deployment, not a broken one, so it must not read as unreachable.
      MODELS_ENDPOINT_ABSENT = LlmServerValidator::MODELS_ENDPOINT_ABSENT

      def self.key = :server

      private

      def validate
        # For a registry-backed format there is nothing free to ask, so the
        # group is omitted entirely rather than rendered as two skipped checks
        # that read as neither healthy nor warning.
        return unless queries_the_server?

        register_checks(:reachable, :credentials_accepted)

        list_models
      end

      def queries_the_server?
        subject.api_format == Llm::Adapters::OPENAI_COMPATIBLE
      end

      def list_models
        client.models
        pass_check(:reachable)
        pass_check(:credentials_accepted)
      rescue Llm::Errors::AuthenticationError
        pass_check(:reachable)
        fail_check(:credentials_accepted, :invalid_api_key)
      rescue Llm::Errors::TimeoutError
        fail_check(:reachable, :request_timed_out)
      rescue Llm::Errors::SsrfError
        fail_check(:reachable, :ssrf_filtered)
      rescue Llm::Errors::ApiError => e
        answered_with_error(e)
      rescue Llm::Errors::ParseError
        pass_check(:reachable)
        fail_check(:credentials_accepted, :not_openai_compatible)
      rescue Llm::Errors::Error
        fail_check(:reachable, :connection_error)
      end

      # The server answered, so it is reachable and did not reject us.
      def answered_with_error(error)
        pass_check(:reachable)

        if error.status.in?(MODELS_ENDPOINT_ABSENT)
          # It simply does not publish a catalogue. A supported deployment.
          warn_check(:credentials_accepted, :no_models_endpoint)
        else
          fail_check(:credentials_accepted, :server_error, context: { status: error.status.to_s })
        end
      end

      def client
        Llm::Client.new(base_url: subject.base_url,
                        api_key: subject.api_key,
                        headers: subject.custom_headers)
      end
    end
  end
end
