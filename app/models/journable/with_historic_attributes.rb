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
  attr_accessor :timestamps, :query, :include_only_changed_attributes, :attributes_by_timestamp,
                :matches_query_filters_at_timestamps, :exists_at_timestamps,
                :journables_by_timestamp


  def initialize(journable, timestamps: nil, query: nil, include_only_changed_attributes: false)
    super(journable)

    if query and not journable.is_a? WorkPackage
      raise Journable::NotImplementedError, "Journable::WithHistoricAttributes with query " \
                                            "is only implemented for WorkPackages at the moment " \
                                            "because Query objects currently only support work packages."
    end

    self.query = query
    self.timestamps = timestamps || query.try(:timestamps) || []
    self.include_only_changed_attributes = include_only_changed_attributes

    self.attributes_by_timestamp = {}
    self.matches_query_filters_at_timestamps = []
    self.exists_at_timestamps = []
    self.journables_by_timestamp = {}
  end

  def self.wrap(journable_or_journables, timestamps: nil, query: nil, include_only_changed_attributes: false)
    case journable_or_journables
    when Array, ActiveRecord::Relation
      wrap_multiple(journable_or_journables, timestamps:, query:, include_only_changed_attributes:)
    else
      wrap_one(journable_or_journables, timestamps:, query:, include_only_changed_attributes:)
    end
  end

  def self.wrap_one(journable, timestamps: nil, query: nil, include_only_changed_attributes: false)
    timestamps ||= query.try(:timestamps) || []
    journable = journable.at_timestamp(timestamps.last) if timestamps.last.try(:historic?)
    journable = new(journable, timestamps:, query:, include_only_changed_attributes:)
    timestamps.each do |timestamp|
      journable.assign_historic_attributes(
        timestamp:,
        historic_journable: journable.at_timestamp(timestamp),
        matching_journable: (query_work_packages(query:, timestamp:).find_by(id: journable.id) if query)
      )
    end
    journable
  end

  # rubocop:disable Metrics/AbcSize
  def self.wrap_multiple(journables, timestamps: nil, query: nil, include_only_changed_attributes: false)
    timestamps ||= query.try(:timestamps) || []
    journables = journables.first.class.at_timestamp(timestamps.last).where(id: journables) if timestamps.last.try(:historic?)
    journables = journables.map { |j| new(j, timestamps:, query:, include_only_changed_attributes:) }
    timestamps.each do |timestamp|
      assign_historic_attributes_to(
        journables,
        timestamp:,
        historic_journables: WorkPackage.at_timestamp(timestamp).where(id: journables.map(&:id)),
        matching_journables: (query_work_packages(query:, timestamp:) if query),
        query:
      )
    end
    journables
  end
  # rubocop:enable Metrics/AbcSize

  def assign_historic_attributes(timestamp:, historic_journable:, matching_journable:)
    attributes_by_timestamp[timestamp.to_s] = extract_historic_attributes_from(historic_journable:) if historic_journable
    journables_by_timestamp[timestamp.to_s] = historic_journable
    matches_query_filters_at_timestamps << timestamp if matching_journable
    exists_at_timestamps << timestamp if historic_journable
  end

  def self.assign_historic_attributes_to(journables, timestamp:, historic_journables:, matching_journables:, query:)
    journables.each do |journable|
      historic_journable = historic_journables.find_by(id: journable.id)
      matching_journable = matching_journables.find_by(id: journable.id) if query
      journable.assign_historic_attributes(timestamp:, historic_journable:, matching_journable:)
    end
  end

  def extract_historic_attributes_from(historic_journable:)
    convert_attributes_hash_to_struct(
      historic_journable.attributes.select do |key, value|
        not include_only_changed_attributes \
        or not respond_to?(key) \
        or value != send(key)
      end
    )
  end

  # This allows us to use the historic attributes in the same way as the current attributes
  # using methods rather than hash keys.
  #
  # Example:
  #   work_package.baseline_attributes.subject
  #   work_package.baseline_attributes["subject"]
  #
  # Rubocop complains about OpenStruct because it is slightly slower than Struct.
  # https://docs.rubocop.org/rubocop/cops_style.html#styleopenstructuse
  #
  # However, I prefer OpenStruct here because it makes it easier to deal with the
  # non existing attributes when using `include_only_changed_attributes: true`.
  #
  # We need to patch the `as_json` method because OpenStruct's `as_json` would
  # wrap everything into a "table" hash.
  #
  # rubocop:disable Style/OpenStructUse
  #
  def convert_attributes_hash_to_struct(attributes)
    Class.new(OpenStruct) do
      def as_json(options = nil)
        to_h.as_json(options)
      end
    end.new(attributes)
  end
  # rubocop:enable Style/OpenStructUse

  def baseline_timestamp
    timestamps.first
  end

  def baseline_attributes
    attributes_by_timestamp[baseline_timestamp.to_s]
  end

  def matches_query_filters_at_baseline_timestamp?
    query && matches_query_filters_at_timestamps.include?(baseline_timestamp)
  end

  def current_timestamp
    timestamps.last
  end

  def matches_query_filters_at_current_timestamp?
    query && matches_query_filters_at_timestamps.include?(current_timestamp)
  end

  def matches_query_filters_at_timestamp?(timestamp)
    query && matches_query_filters_at_timestamps.include?(timestamp)
  end

  def changed_at_timestamp(timestamp)
    return [] unless journables_by_timestamp[timestamp.to_s]

    ::Acts::Journalized::JournableDiffer
    .changes(__getobj__, journables_by_timestamp[timestamp.to_s])
    .keys
  end

  def self.query_work_packages(query:, timestamp: nil)
    query = query.dup
    query.timestamps = [timestamp] if timestamp
    query.results.work_packages
  end

  def to_ary
    __getobj__.send(:to_ary)
  end

  def inspect
    __getobj__.inspect.gsub(/#<(.+)>/m, "#<#{self.class.name} \\1>")
  end

  class NotImplemented < StandardError; end
end
