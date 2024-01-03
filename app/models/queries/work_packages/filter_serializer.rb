#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

  def self.load(serialized_filter_hash)
    return [] if serialized_filter_hash.nil?

    # yeah, dunno, but apparently '=' may have been serialized as a Syck::DefaultKey instance...
    yaml = serialized_filter_hash
           .gsub('!ruby/object:Syck::DefaultKey {}', '"="')

    (YAML.load(yaml, permitted_classes: [Symbol, Date]) || {}).each_with_object([]) do |(field, options), array|
      options = options.with_indifferent_access
      filter = filter_for(field, no_memoization: true)
      filter.operator = options['operator']
      filter.values = options['values']
      array << filter
    end
  end

  def self.dump(filters)
    YAML.dump ((filters || []).map(&:to_hash).reduce(:merge) || {}).stringify_keys
  end

  def self.registered_filters
    Queries::Register.filters[Query]
  end
end
