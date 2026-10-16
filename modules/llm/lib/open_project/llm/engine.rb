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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "open_project/plugins"
require "ruby_llm"

module OpenProject::Llm
  class Engine < ::Rails::Engine
    engine_name :openproject_llm

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-llm",
             author_url: "https://www.openproject.org",
             bundled: true do
      menu :admin_menu,
           :llm_connection,
           { controller: "/admin/llm_connections", action: :show },
           if: ->(_) { User.current.admin? && OpenProject::FeatureDecisions.llm_connection_active? },
           caption: :"menus.admin.llm_connection",
           parent: :ai,
           before: :mcp_configurations
    end

    class_inflection_override("ruby_llm_provider_headers" => "RubyLLMProviderHeaders")

    # RubyLLM's legacy acts_as API warns on boot unless the new one is chosen,
    # and the choice has to be made before its railtie reaches ActiveRecord.
    # OpenProject uses the plain client rather than either ActiveRecord API.
    config.before_initialize do
      RubyLLM.configure { |llm| llm.use_new_acts_as = true }
    end

    initializer "openproject_llm.feature_decisions" do
      OpenProject::FeatureDecisions.add :llm_connection,
                                        description: "Enables the administration page connecting OpenProject to an " \
                                                     "OpenAI-API-compatible LLM server, and the AI features built on it."

      OpenProject::FeatureDecisions.add :semantic_search,
                                        description: "Enables the semantic search AI feature, which indexes work packages " \
                                                     "as embeddings so they can be found by meaning rather than by keyword."
    end

    initializer "openproject_llm.configuration" do
      ::Settings::Definition.add :llm_connection,
                                 description: "Configure the connection to an OpenAI-API-compatible LLM server " \
                                              "through environment variables",
                                 writable: false,
                                 default: {},
                                 format: :hash,
                                 string_values: true
      ::Settings::Definition.add :llm_features_enabled,
                                 description: "Enable the AI features backed by the configured LLM connection",
                                 format: :boolean,
                                 default: false
    end

    initializer "openproject_llm.features" do
      # The description assistant rewrites work package text on explicit user action.
      # Plain chat completions only: no tools, no JSON mode, no streaming. Individual
      # actions may override the model, which is why it is overridable.
      OpenProject::Llm::Features.register :description_assistant,
                                          kind: :chat,
                                          prefers: %i[structured_output],
                                          overridable: true

      # Semantic search embeds work packages into a pgvector index. The stored vectors
      # are meaningless under a different model, so it is not overridable: changing it
      # is a destructive re-index rather than a swap.
      #
      # The feature itself is not built yet, so it carries its own flag rather than
      # riding on :llm_connection. Until that flag is on it is registered but never
      # available, which keeps it off the feature configuration tab and out of the
      # health checks.
      OpenProject::Llm::Features.register :semantic_search,
                                          kind: :embedding,
                                          requires: %i[embeddings],
                                          available: -> { OpenProject::FeatureDecisions.semantic_search_active? }
    end

    initializer "openproject_llm.load_patches" do
      require_relative "patches/ruby_llm_provider_headers"

      OpenProject::Patches.patch_gem_version("ruby_llm", "1.16.0") do
        RubyLLM::Configuration.register_provider_options(%i[openproject_custom_headers])

        RubyLLM::Provider.providers.each_value do |provider_class|
          provider_class.prepend(OpenProject::Llm::Patches::RubyLLMProviderHeaders)
        end
      end
    end

    add_cron_jobs do
      {
        "Llm::HealthCheckJob": {
          cron: "7 */6 * * *", # every six hours at xx:07
          class: ::Llm::HealthCheckJob.name
        },
        "Llm::PruneHealthReportsJob": {
          cron: "25 3 * * *", # runs at 3:25 nightly
          class: ::Llm::PruneHealthReportsJob.name
        }
      }
    end
  end
end
