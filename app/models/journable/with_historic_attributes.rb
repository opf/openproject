#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

# This class is used to wrap a Journable and provide access to its attributes at given timestamps.
# It is used to provide the old and new values of a journable in the journables's payload.
# https://github.com/opf/openproject/pull/11783
#
# Usage:
#
#   # Wrap single work package
#   timestamps = [Timestamp.parse("2022-01-01T00:00:00Z"), Timestamp.parse("PT0S")]
#   work_package = WorkPackage.find(1)
#   work_package = Journable::WithHistoricAttributes.wrap(work_package, timestamps:)
#
#   # Wrap multiple work packages
#   timestamps = query.timestamps
#   work_packages = query.results.work_packages
#   work_packages = Journable::WithHistoricAttributes.wrap_multiple(work_packages, timestamps:)
#
#   # Access historic attributes at timestamps after wrapping
#   work_package = Journable::WithHistoricAttributes.wrap(work_package, timestamps:)
#   work_package.subject  # => "Subject at PT0S (current time)"
#   work_package.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject  # => "Subject at 2022-01-01 (baseline time)"
#
#   # Check at which timestamps the work package matches query filters after wrapping
#   query.timestamps  # => [<Timestamp 2022-01-01T00:00:00Z>, <Timestamp PT0S>]
#   work_package = Journable::WithHistoricAttributes.wrap(work_package, query:)
#   work_package.matches_query_filters_at_timestamps  # => [<Timestamp 2022-01-01T00:00:00Z>]
#
#   # Include only changed attributes in payload
#   # i.e. only historic attributes that differ from the work_package's attributes
#   timestamps = [Timestamp.parse("2022-01-01T00:00:00Z"), Timestamp.parse("PT0S")]
#   work_package = Journable::WithHistoricAttributes.wrap(work_package, timestamps:, include_only_changed_attributes: true)
#   work_package.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject  # => "Subject at 2022-01-01 (baseline time)"
#   work_package.attributes_by_timestamp["PT0S"].subject  # => nil
#
#   # Simplified interface for two timestamps
#   query.timestamps  # => [<Timestamp 2022-01-01T00:00:00Z>, <Timestamp PT0S>]
#   work_package = Journable::WithHistoricAttributes.wrap(work_package, query:)
#   work_package.baseline_timestamp  # => [<Timestamp 2022-01-01T00:00:00Z>]
#   work_package.current_timestamp  # => [<Timestamp PT0S>]
#   work_package.matches_query_filters_at_baseline_timestamp?
#   work_package.matches_query_filters_at_current_timestamp?
#   work_package.baseline_attributes.subject # => "Subject at 2022-01-01 (baseline time)"
#   work_package.subject  # => "Subject at PT0S (current time)"
#
class Journable::WithHistoricAttributes < SimpleDelegator
  attr_accessor :timestamps,
                :query,
                :include_only_changed_attributes,
                :loader

  def initialize(journable,
                 timestamps: nil,
                 query: nil,
                 include_only_changed_attributes: false,
                 loader: Loader.new(journable))
    super(journable)

    if query and not journable.is_a? WorkPackage
      raise Journable::NotImplementedError, "Journable::WithHistoricAttributes with query " \
                                            "is only implemented for WorkPackages at the moment " \
                                            "because Query objects currently only support work packages."
    end

    self.query = query
    self.timestamps = timestamps || query.try(:timestamps) || []
    self.include_only_changed_attributes = include_only_changed_attributes

    self.loader = loader
  end
  private_class_method :new

  class << self
    def wrap(journable_or_journables,
             timestamps: query.try(:timestamps) || [],
             query: nil,
             include_only_changed_attributes: false)
      wrapped = wrap_each_journable(Array(journable_or_journables), timestamps:, query:, include_only_changed_attributes:)

      case journable_or_journables
      when Array, ActiveRecord::Relation
        wrapped
      else
        wrapped.first
      end
    end

    private

    def wrap_each_journable(journables, timestamps:, query:, include_only_changed_attributes:)
      loader = Loader.new(journables)
      journables = loader.at_timestamp(timestamps.last).values if timestamps.last.try(:historic?)

      journables.map { |j| new(j, timestamps:, query:, include_only_changed_attributes:, loader:) }
    end
  end

  def attributes_by_timestamp
    @attributes_by_timestamp ||= Hash.new do |h, t|
      attributes = if include_only_changed_attributes
                     changes_at_timestamp(t)&.transform_values(&:last)
                   else
                     historic_attributes_at(t)
                   end

      h[t] = attributes ? Hashie::Mash.new(attributes) : nil
    end
  end

  def changed_at_timestamp(timestamp)
    changes_at_timestamp(timestamp)&.keys || []
  end

  def matches_query_filters_at_timestamps
    if query.present?
      timestamps.select { |timestamp| loader.work_package_ids_of_query_at_timestamp(query:, timestamp:).include?(__getobj__.id) }
    else
      []
    end
  end

  def exists_at_timestamps
    timestamps.select { |t| at_timestamp(t).present? }
  end

  def baseline_timestamp
    timestamps.first
  end

  def baseline_attributes
    attributes_by_timestamp[baseline_timestamp.to_s]
  end

  def matches_query_filters_at_baseline_timestamp?
    matches_query_filters_at_timestamps.include?(baseline_timestamp)
  end

  def current_timestamp
    timestamps.last
  end

  def matches_query_filters_at_current_timestamp?
    matches_query_filters_at_timestamps.include?(current_timestamp)
  end

  def matches_query_filters_at_timestamp?(timestamp)
    matches_query_filters_at_timestamps.include?(timestamp)
  end

  def at_timestamp(timestamp)
    loader.journable_at_timestamp(__getobj__, timestamp)
  end

  def id
    __getobj__.try(:id)
  end

  def attributes
    __getobj__.try(:attributes)
  end

  def to_ary
    __getobj__.send(:to_ary)
  end

  def inspect
    __getobj__.inspect.gsub(/#<(.+)>/m, "#<#{self.class.name} \\1>")
  end

  private

  def historic_attributes_at(timestamp)
    historic_journable = at_timestamp(Timestamp.parse(timestamp))

    return unless historic_journable

    historic_journable
      .attributes
      .select do |key, _|
        respond_to?(key)
      end
  end

  def changes_at_timestamp(timestamp)
    historic_journable = at_timestamp(Timestamp.parse(timestamp))

    return unless historic_journable

    ::Acts::Journalized::JournableDiffer
      .changes(__getobj__, historic_journable)
  end

  class NotImplemented < StandardError; end
end
