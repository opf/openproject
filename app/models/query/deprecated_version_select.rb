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

# Translates the `version` / `target_versions` select names when reading the
# stored query attributes: only one of the two is available at a time, so a name
# stored while Setting::WorkPackageMultipleVersions was in the other state would
# otherwise be dropped from the columns, the grouping or the sort criterion.
#
# TODO(COMMS-949): remove this and the `version` select once that ticket has
# migrated the stored names.
module Query::DeprecatedVersionSelect
  extend ActiveSupport::Concern

  INTERCHANGEABLE_NAMES = %w[version target_versions].freeze

  # @return [String, Symbol, nil] the available counterpart (a String) of an
  #   interchangeable version name, or the given name untouched
  def self.normalize_name(name)
    return name if INTERCHANGEABLE_NAMES.exclude?(name.to_s)

    Setting::WorkPackageMultipleVersions.active? ? "target_versions" : "version"
  end

  # Prepended, not included: `sort_criteria` is defined in the Query class body,
  # so an include would sit below it and never be consulted.
  module PrependNormalizedSelectNames
    def column_names
      normalize_select_names(super)
    end

    def group_by
      normalize_select_name(super)
    end

    def sort_criteria
      super.map { |attr, direction| [normalize_select_name(attr), direction] }
    end
  end

  included do
    prepend PrependNormalizedSelectNames
  end

  private

  def normalize_select_names(names)
    names.map { normalize_select_name(it).to_sym }.uniq
  end

  def normalize_select_name(name)
    Query::DeprecatedVersionSelect.normalize_name(name)
  end
end
