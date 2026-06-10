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

module ProjectIdentifiers
  # Generates a unique classic-format identifier from a project name.
  # Appends -1, -2, … until a free slug is found.
  #
  # Instantiate once to load the taken-identifier set from the DB, then call +suggest_identifier+.
  class ClassicIdentifierSuggestionGenerator
    FALLBACK_BASE = "project"
    BLANK_SLUG_SUBSTITUTIONS = { "." => "dot", "!" => "bang" }.freeze

    def initialize(project: nil)
      @exclude = taken_identifiers(project:)
    end

    # Returns the most-recent classic-format slug from the project's FriendlyId history,
    # or nil if none exists. Availability is not checked — callers must handle conflicts.
    def restore_identifier(project)
      project.slugs
             .order(created_at: :desc)
             .pluck(:slug)
             .find { |slug| Project.classic_identifier_format?(slug) }
    end

    # Generates a unique classic-format identifier from +name+.
    # Appends -1, -2, … until a slug not in the taken set is found.
    # Falls back to a randomised +FALLBACK_BASE+ slug when +name+ produces no valid slug.
    def suggest_identifier(name)
      base = slugify(name) || fallback_base

      candidate = base
      n = 1
      loop do
        return candidate if @exclude.exclude?(candidate.downcase)

        candidate = "#{base}-#{n}"
        n += 1
      end
    end

    private

    def slugify(name)
      slug = name.to_url.first(Projects::Identifier::CLASSIC_IDENTIFIER_MAX_LENGTH).presence
      slug ||= BLANK_SLUG_SUBSTITUTIONS[name]
      slug if slug && Projects::Identifier::CLASSIC_FORMAT.match?(slug)
    end

    def fallback_base
      "#{FALLBACK_BASE}-#{SecureRandom.alphanumeric(5).downcase}"
    end

    def taken_identifiers(project: nil)
      current    = Project.unscoped.pluck(:identifier).compact.to_set(&:downcase)
      historical = Project.identifier_slugs.excluding_project(project).downcased_values.to_set
      reserved   = Projects::Identifier::RESERVED_IDENTIFIERS.to_set
      current | historical | reserved
    end
  end
end
