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

module EnvData
  # Provisions the LLM connection from OPENPROJECT_LLM__CONNECTION_* variables so
  # a container comes up connected without anyone opening the administration UI.
  #
  # Never contacts the LLM server: the catalogue refresh is enqueued, so seeding
  # succeeds even when the server starts after OpenProject does.
  class LlmConnectionSeeder < Seeder
    KNOWN_KEYS = %w[base_url api_key default_chat_model default_embedding_model enabled].freeze

    def seed_data!
      print_status "    ↳ Creating LLM connection" do
        validate_options!(config)

        result = LlmConnections::EnvSyncService.new(config).call
        raise result.errors.full_messages.join(", ") if result.failure?

        Llm::SyncModelsJob.perform_later
      end
    end

    def applicable?
      config.present?
    end

    def not_applicable_message
      "No LLM connection configured through environment variables."
    end

    private

    def config
      Setting.llm_connection
    end

    def validate_options!(options)
      check_unknown_keys!(options, KNOWN_KEYS)
      return if options["base_url"].present?

      raise "LLM connection: #{env_form('base_url')} is required."
    end

    def check_unknown_keys!(options, known_keys)
      unknown = options.keys - known_keys
      return if unknown.empty?

      raise <<~MSG.strip
        LLM connection: unknown configuration key(s): #{unknown.map { |k| env_form(k) }.join(', ')}.
        Accepted keys: #{known_keys.map { |k| env_form(k) }.join(', ')}.
        Note: in environment variable names, single underscores split path segments and double underscores encode a literal underscore (e.g. BASE__URL, not BASE_URL).
      MSG
    end

    def env_form(key)
      key.gsub("_", "__").upcase
    end
  end
end
