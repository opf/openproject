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

module Queries::WorkPackages::FilterSerializer
  extend Queries::Filters::AvailableFilters
  extend Queries::Filters::AvailableFilters::ClassMethods

  INTERCHANGEABLE_VERSION_KEYS = %w[version_id target_version_id].freeze

  def self.load(serialized_filter_hash)
    return [] if serialized_filter_hash.nil?

    # yeah, dunno, but apparently '=' may have been serialized as a Syck::DefaultKey instance...
    yaml = serialized_filter_hash
           .gsub("!ruby/object:Syck::DefaultKey {}", '"="')

    filter_hash = YAML.load(yaml, permitted_classes: [Symbol, Date]) || {}

    collapse_interchangeable_version_keys(filter_hash).each_with_object([]) do |(field, options), array|
      options = options.with_indifferent_access
      filter = filter_for(field, no_memoization: true)
      filter.operator = options["operator"]
      filter.values = options["values"]
      array << filter
    end
  end

  def self.dump(filters)
    YAML.dump ((filters || []).map(&:to_hash).reduce(:merge) || {}).stringify_keys
  end

  def self.registered_filters
    Queries::Register.filters[Query]
  end

  # `version_id` and `target_version_id` are interchangeable representations
  # of one filter, and only one of them is available at a time. A hash naming
  # both collapses to the one currently available.
  def self.collapse_interchangeable_version_keys(filter_hash)
    filter_hash.each_with_object({}) do |(key, options), collapsed|
      normalized_key = active_version_key(key)

      next if collapsed.key?(normalized_key) && normalized_key.to_s != key.to_s

      collapsed[normalized_key] = options
    end
  end

  def self.active_version_key(key)
    return key if INTERCHANGEABLE_VERSION_KEYS.exclude?(key.to_s)

    Setting::WorkPackageMultipleVersions.active? ? "target_version_id" : "version_id"
  end
end
