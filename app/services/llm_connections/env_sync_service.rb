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
  # Applies an environment-provided configuration to the connection record.
  #
  # Uses EnvironmentUpdateContract, which lifts the "configured from environment
  # is read-only" guard and, crucially, does not probe the LLM server: the
  # container running the seed may well start before the server does.
  class EnvSyncService
    # A JSON string from the environment variable, since nested variable names
    # cannot spell a header name such as api-version, or a Hash from
    # configuration.yml. Anything that is not an object is passed on unparsed
    # for LlmConnection's validation to refuse.
    def self.custom_headers(value)
      return {} if value.nil? || value == ""
      return value unless value.is_a?(String)

      parsed = JSON.parse(value)
      parsed.is_a?(Hash) ? parsed : value
    rescue JSON::ParserError
      value
    end

    # Only the top level is symbolized: the custom header names are sent as given.
    def initialize(env_config)
      @config = env_config.symbolize_keys
    end

    def call
      result = nil

      ApplicationRecord.transaction(requires_new: true) do
        result = write(attributes)
        raise ActiveRecord::Rollback if result.failure?

        result = write(default_model_references(result.result), model: result.result)
        raise ActiveRecord::Rollback if result.failure?
      end

      result
    end

    private

    attr_reader :config

    # Absent connection keys are cleared on purpose: the environment is the source
    # of truth here, and the form is read-only while it is. Keeping a stored
    # value that was removed from the environment would leave, for example, an
    # obsolete API key in use with no supported way to clear it.
    def attributes
      {
        base_url: config.fetch(:base_url),
        api_key: config[:api_key],
        custom_headers: self.class.custom_headers(config[:custom_headers]),
        llm_features_enabled:
      }
    end

    # Unlike the connection's own values, the features switch is instance-wide
    # and has its own variable, so an absent key leaves it as it is.
    def llm_features_enabled
      return Setting.llm_features_enabled? unless config.key?(:enabled)

      ActiveRecord::Type::Boolean.new.deserialize(config[:enabled])
    end

    def write(attributes, model: LlmConnection.active_connection)
      UpdateService
        .new(user: User.system,
             model:,
             contract_class: EnvironmentUpdateContract)
        .call(**attributes)
    end

    # The environment names a model, and on a fresh installation nothing has
    # asked the server for a catalogue yet, so the row it must reference is
    # entered here the way an administrator would enter it by hand.
    def default_model_references(connection)
      { default_chat_model_id: model_row_id(connection, config[:default_chat_model]),
        default_embedding_model_id: model_row_id(connection, config[:default_embedding_model]) }
    end

    def model_row_id(connection, external_id)
      return if external_id.blank?

      connection.models.create_with(manual: true).find_or_create_by!(external_id:).id
    end
  end
end
