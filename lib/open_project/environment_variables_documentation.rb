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
  # Renders the list of environment variables overriding settings, i.e. the
  # documented counterpart of `rake setting:available_envs`. `rake docs:env_vars`
  # rewrites it in place, between the markers below.
  #
  # Regenerated in production, since a good number of defaults differ per
  # environment and the page documents on-premises installations. The spec can
  # therefore not compare the defaults, only what holds in every environment.
  module EnvironmentVariablesDocumentation
    DOC_PATH = "docs/installation-and-operations/configuration/environment/README.md"

    # As used by the release notes, warning comments outside the markers included.
    BEGIN_MARKER = "<!-- BEGIN AUTOMATED SECTION -->"
    END_MARKER = "<!-- END AUTOMATED SECTION -->"
    BLOCK_PATTERN = /#{Regexp.escape(BEGIN_MARKER)}.*?#{Regexp.escape(END_MARKER)}/m

    RANDOM_PLACEHOLDER = "<randomly generated>"

    # Defaults generated anew on every read: documenting them would leak something
    # that looks like a secret, and change the page on every run.
    RANDOM_DEFAULTS = %i[
      hashed_token_pepper
      installation_uuid
    ].freeze

    # `real_time_text_collaboration_enabled` derives its default from the two
    # hocuspocus settings, `default_projects_modules` from that one - as values, so
    # a configured instance documents itself. Mapped to the override neutralising
    # each; `docs:env_vars` refuses to run while any is set.
    DERIVED_DEFAULT_INPUTS = {
      collaborative_editing_hocuspocus_url: "OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__URL=",
      collaborative_editing_hocuspocus_secret: "OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET=",
      real_time_text_collaboration_enabled: "OPENPROJECT_REAL__TIME__TEXT__COLLABORATION__ENABLED=false"
    }.freeze

    class << self
      def path
        Rails.root.join(DOC_PATH)
      end

      # `[env_name, definition]` pairs, in the order this list and
      # `setting:available_envs` show them.
      def sorted_definitions
        Settings::Definition
          .all
          .map { |_, definition| [env_name(definition), definition] }
          .sort_by { |env_name, _| env_name.downcase }
      end

      # The documented description per variable. Unlike the defaults, these do not
      # depend on the environment, so the spec can check them.
      def descriptions
        I18n.with_locale(:en) do
          sorted_definitions.to_h { |env_name, definition| [env_name, definition.description.presence] }
        end
      end

      # Empty on a fresh installation.
      def configured_derived_inputs
        DERIVED_DEFAULT_INPUTS.select { |setting, _| Setting[setting].present? }
      end

      def rows
        I18n.with_locale(:en) do
          sorted_definitions.map do |env_name, definition|
            # Using strip as description is nil for some settings
            "#{env_name} (default=#{rendered_default(definition)}) #{definition.description}".strip
          end
        end
      end

      # The delimited block, markers included, as expected on disk.
      def block
        "#{BEGIN_MARKER}\n\n```text\n#{rows.join("\n")}\n```\n\n#{END_MARKER}"
      end

      # The page with its delimited block regenerated.
      def update(page)
        unless page.include?(BEGIN_MARKER) && page.include?(END_MARKER)
          raise "#{DOC_PATH} is missing the #{BEGIN_MARKER} / #{END_MARKER} markers " \
                "delimiting the generated list."
        end

        page.sub(BLOCK_PATTERN, block)
      end

      private

      def rendered_default(definition)
        if RANDOM_DEFAULTS.include?(definition.name.to_sym)
          RANDOM_PLACEHOLDER
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
    end
  end
end
