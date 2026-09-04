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

# Translates the `version_id` / `target_version_id` filter keys when reading
# stored or requested filters: only one of the two filters is available at a
# time, so a key stored while Setting::WorkPackageMultipleVersions was in the
# other state would otherwise be dropped by the valid-subset pruning.
#
# TODO(COMMS-949): remove this and the `version_id` filter once that ticket has
# migrated the stored keys.
module Query::DeprecatedVersionFilter
  extend ActiveSupport::Concern

  INTERCHANGEABLE_KEYS = %w[version_id target_version_id].freeze

  # @return [String, Symbol, nil] the available counterpart (a String) of an
  #   interchangeable version filter key, or the given key untouched
  def self.normalize_key(key)
    return key if INTERCHANGEABLE_KEYS.exclude?(key.to_s)

    Setting::WorkPackageMultipleVersions.active? ? "target_version_id" : "version_id"
  end

  # Normalizes the keys of a serialized filter hash. When both interchangeable
  # keys are stored, the entry stored under the currently available key wins -
  # keeping both would list the same filter twice.
  def self.normalize_filter_hash(filter_hash)
    filter_hash.each_with_object({}) do |(key, options), normalized|
      normalized_key = normalize_key(key)
      next if normalized.key?(normalized_key) && normalized_key.to_s != key.to_s

      normalized[normalized_key] = options
    end
  end

  # Prepended, not included: the wrapped methods are defined in the Query
  # class body, so an include would sit below them and never be consulted.
  module PrependNormalizedFilterKeys
    def filter_for(field)
      super(Query::DeprecatedVersionFilter.normalize_key(field))
    end

    def remove_filter(name)
      super(Query::DeprecatedVersionFilter.normalize_key(name))
    end

    # Matches by symbol only, so the normalized key is converted back.
    def find_active_filter(name)
      normalized = Query::DeprecatedVersionFilter.normalize_key(name)
      normalized = normalized.to_sym if name.is_a?(Symbol)

      super(normalized)
    end
  end

  included do
    prepend PrependNormalizedFilterKeys
  end
end
