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

module OpenProject
  # Renders the documentation page listing the environment variables that can be
  # used to override settings, i.e. the documented counterpart of
  # `rake setting:available_envs`.
  #
  # The page is checked into the repository, regenerated with
  # `rake docs:env_vars` and verified by
  # spec/lib/open_project/environment_variables_documentation_spec.rb, so that it
  # cannot silently go stale when settings are added, removed or changed.
  #
  # Not every default can be printed verbatim, though: some are generated at
  # random, some are read from the database and some differ between Rails
  # environments. Those are rendered as a placeholder, which keeps the output
  # identical no matter where the task is run and therefore allows comparing the
  # generated page as a whole.
  module EnvironmentVariablesDocumentation
    PAGE_PATH = "docs/installation-and-operations/configuration/environment/" \
                "supported-environment-variables/README.md"

    RANDOM_PLACEHOLDER = "<randomly generated>"
    ENVIRONMENT_DEPENDENT_PLACEHOLDER = "<depends on environment>"

    # Settings whose default is generated anew every time it is read, so printing
    # it would both leak a secret and change the page on every run.
    RANDOM_DEFAULTS = %i[
      hashed_token_pepper
      installation_uuid
    ].freeze

    # Settings whose default is not the same everywhere. Either it differs
    # between Rails environments, or it is derived from state outside of the
    # definition (the database, the process environment).
    #
    # Some of these are resolved lazily and could in principle be evaluated with
    # a pinned environment, but others are frozen when the definition is loaded
    # (`default_by_env`, and defaults computed in the class body) and cannot be
    # recovered afterwards. They are therefore all treated the same way.
    ENVIRONMENT_DEPENDENT_DEFAULTS = %i[
      collaborative_editing_hocuspocus_secret
      collaborative_editing_hocuspocus_url
      default_projects_modules
      development_highlight_enabled
      host_name
      https
      log_level
      lookbook_enabled
      password_active_rules
      plugin_openproject_avatars
      real_time_text_collaboration_enabled
      show_warning_bars
      web
    ].freeze

    # Proc defaults that are safe to call: they return the same value in every
    # environment and do not touch the database.
    EVALUATED_PROC_DEFAULTS = %i[
      work_package_list_default_highlighting_mode
    ].freeze

    class << self
      def path
        Rails.root.join(PAGE_PATH)
      end

      # The `[env_name, definition]` pairs in the order both this page and
      # `rake setting:available_envs` list them.
      def sorted_definitions
        Settings::Definition
          .all
          .map { |_, definition| [env_name(definition), definition] }
          .sort_by { |env_name, _| env_name.downcase }
      end

      # The whole page, as it is expected to be found on disk.
      def to_markdown
        I18n.with_locale(:en) do
          "#{preamble}```text\n#{rows.join("\n")}\n```\n"
        end
      end

      # The settings whose default is rendered as a placeholder. Feature flags
      # are included wholesale: their default is
      # `force_active || Rails.env.development?`.
      def masked_setting_names
        RANDOM_DEFAULTS +
          ENVIRONMENT_DEPENDENT_DEFAULTS +
          OpenProject::FeatureDecisions.all.map { |flag| :"feature_#{flag}_active" }
      end

      private

      def rows
        masked = masked_setting_names

        sorted_definitions.map do |env_name, definition|
          # `description` is nil for a few settings, hence the `rstrip`.
          "#{env_name} (default=#{rendered_default(definition, masked)}) #{definition.description}".rstrip
        end
      end

      def rendered_default(definition, masked)
        name = definition.name.to_sym

        if RANDOM_DEFAULTS.include?(name)
          RANDOM_PLACEHOLDER
        elsif masked.include?(name)
          ENVIRONMENT_DEPENDENT_PLACEHOLDER
        else
          definition.default.inspect
        end
      end

      def env_name(definition)
        if definition.env_alias&.start_with?("OPENPROJECT_")
          definition.env_alias
        else
          Settings::Definition.possible_env_names(definition).first
        end
      end

      def preamble
        <<~MARKDOWN
          ---
          sidebar_navigation:
            title: Supported environment variables
            priority: 10
          ---

          <!-- Generated by `bundle exec rake docs:env_vars`. Do not edit this file by hand. -->

          # Supported environment variables

          The following settings can be overridden with an environment variable, listed with
          their default value and, where there is one, a description. This page is generated
          from the code and verified by a spec, so it describes the version of OpenProject
          you are reading the documentation for.

          Two kinds of default cannot be listed here:

          - `#{RANDOM_PLACEHOLDER}` — a random secret, created once when it is first used.
          - `#{ENVIRONMENT_DEPENDENT_PLACEHOLDER}` — the default differs between the
            development, test and production environments, or is derived from other
            settings. On-premises installations run in the production environment.

          To see the values your own installation actually uses, including for those
          settings, run `rake setting:available_envs` on it as described under
          [Environment variables](../).

        MARKDOWN
      end
    end
  end
end
