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
  # Renders the list of environment variables that can be used to override
  # settings, i.e. the documented counterpart of `rake setting:available_envs`.
  #
  # The list lives in the middle of a hand-written page, delimited by the two
  # markers below, and is rewritten in place by `rake docs:env_vars`. Everything
  # outside the markers is left untouched.
  #
  # Regenerate with `RAILS_ENV=production rake docs:env_vars`. Production is not
  # incidental: a good number of defaults differ per environment, and the page
  # documents on-premises installations, which run in production. The task
  # therefore refuses to run in any other environment.
  #
  # Two defaults are derived from other settings, so they come out as whatever
  # the generating instance has configured: `default_projects_modules` and
  # `real_time_text_collaboration_enabled` both consult
  # `Setting.collaborative_editing_hocuspocus_url`. Generate on an instance that
  # has none of that configured, or pass
  # `OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__URL=`,
  # `OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET=` and
  # `OPENPROJECT_REAL__TIME__TEXT__COLLABORATION__ENABLED=false` to get the
  # defaults of a fresh installation.
  #
  # Since the list is generated in production, the test suite cannot regenerate it
  # and compare it. What
  # spec/lib/open_project/environment_variables_documentation_spec.rb verifies
  # instead is everything that does not depend on the environment: that every
  # setting is listed, that nothing is listed that no longer exists, and that each
  # one carries its current description.
  module EnvironmentVariablesDocumentation
    DOC_PATH = "docs/installation-and-operations/configuration/environment/README.md"

    BEGIN_MARKER = "<!-- BEGIN GENERATED LIST: RAILS_ENV=production bundle exec rake docs:env_vars -->"
    END_MARKER = "<!-- END GENERATED LIST -->"
    BLOCK_PATTERN = /#{Regexp.escape(BEGIN_MARKER)}.*?#{Regexp.escape(END_MARKER)}/m

    RANDOM_PLACEHOLDER = "<randomly generated>"

    # Settings whose default is generated anew every time it is read. Printing it
    # would put something that looks like this instance's secret into the
    # documentation, and change the page on every run.
    RANDOM_DEFAULTS = %i[
      hashed_token_pepper
      installation_uuid
    ].freeze

    # Settings that other settings derive their default from, mapped to the
    # override that puts them back into their fresh-installation state.
    #
    # `real_time_text_collaboration_enabled` derives its default from the two
    # hocuspocus settings, and `default_projects_modules` derives its own from
    # that one. They are read as values, so a configured instance - or just a row
    # in the settings table - makes the generated list document that instance
    # rather than a fresh installation. `docs:env_vars` refuses to run then.
    DERIVED_DEFAULT_INPUTS = {
      collaborative_editing_hocuspocus_url: "OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__URL=",
      collaborative_editing_hocuspocus_secret: "OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET=",
      real_time_text_collaboration_enabled: "OPENPROJECT_REAL__TIME__TEXT__COLLABORATION__ENABLED=false"
    }.freeze

    class << self
      def path
        Rails.root.join(DOC_PATH)
      end

      # The `[env_name, definition]` pairs in the order both this list and
      # `rake setting:available_envs` show them.
      def sorted_definitions
        Settings::Definition
          .all
          .map { |_, definition| [env_name(definition), definition] }
          .sort_by { |env_name, _| env_name.downcase }
      end

      # The description documented for each environment variable. Unlike the
      # defaults, descriptions do not depend on the environment, which is what
      # allows the spec to check them.
      def descriptions
        I18n.with_locale(:en) do
          sorted_definitions.to_h { |env_name, definition| [env_name, definition.description.presence] }
        end
      end

      # The DERIVED_DEFAULT_INPUTS this instance has configured, mapped to the
      # override that neutralises each. Empty on a fresh installation.
      def configured_derived_inputs
        DERIVED_DEFAULT_INPUTS.select { |setting, _| Setting[setting].present? }
      end

      # The delimited block, markers included, as it is expected to be found in
      # the page.
      def block
        I18n.with_locale(:en) do
          "#{BEGIN_MARKER}\n\n```text\n#{rows.join("\n")}\n```\n\n#{END_MARKER}"
        end
      end

      # The given page with its delimited block replaced by a freshly generated
      # one.
      def update(page)
        unless page.include?(BEGIN_MARKER) && page.include?(END_MARKER)
          raise "#{DOC_PATH} is missing the #{BEGIN_MARKER} / #{END_MARKER} markers " \
                "delimiting the generated list."
        end

        page.sub(BLOCK_PATTERN, block)
      end

      private

      def rows
        sorted_definitions.map do |env_name, definition|
          # `description` is nil for a few settings, hence the `rstrip`.
          "#{env_name} (default=#{rendered_default(definition)}) #{definition.description}".rstrip
        end
      end

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
