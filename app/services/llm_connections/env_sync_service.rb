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
    def initialize(env_config)
      @config = env_config.deep_symbolize_keys
    end

    def call
      ApplicationRecord.transaction do
        result = write(attributes)
        break result if result.failure?

        write(default_model_references(result.result), model: result.result)
      end
    end

    private

    attr_reader :config

    # Absent keys are written as nil on purpose: the environment is the source
    # of truth here, and the form is read-only while it is. Keeping a stored
    # value that was removed from the environment would leave, for example, an
    # obsolete API key in use with no supported way to clear it.
    def attributes
      {
        base_url: config.fetch(:base_url),
        api_key: config[:api_key],
        llm_features_enabled: ActiveRecord::Type::Boolean.new.deserialize(config.fetch(:enabled, true))
      }
    end

    def write(attributes, model: LlmConnection.active_connection)
      UpdateService
        .new(user: User.system,
             model:,
             contract_class: EnvironmentUpdateContract,
             sync_models: false)
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
