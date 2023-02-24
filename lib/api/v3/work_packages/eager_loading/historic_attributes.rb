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

module API::V3::WorkPackages::EagerLoading
  class HistoricAttributes < Base
    attr_writer :timestamps
    attr_accessor :query

    def apply(work_package)
      return unless timestamps.any?(&:historic?)

      work_package_with_historic_attributes = work_packages_with_historic_attributes[work_package.id]

      set_attributes_at_timestamp(work_package,
                                  work_package_with_historic_attributes,
                                  work_package_with_historic_attributes.timestamps.last,
                                  override_current: true)

      work_package.at_timestamps = work_package_with_historic_attributes
                                     .timestamps
                                     .map do |timestamp|
        wrapped_wp = AttributesByTimestampWorkPackage
                       .new(work_package_with_historic_attributes.at_timestamp(timestamp), timestamp)

        set_attributes_at_timestamp(wrapped_wp,
                                    work_package_with_historic_attributes,
                                    wrapped_wp.timestamp)

        wrapped_wp
      end
    end

    def self.module
      HistoricAttributesAccessors
    end

    private

    def set_attributes_at_timestamp(work_package, source, timestamp, override_current: false)
      override_attributes(work_package, source) if override_current
      set_timestamp_attributes(work_package, source, timestamp)
    end

    def work_packages_with_historic_attributes
      @work_packages_with_historic_attributes ||= Journable::WithHistoricAttributes
                                                  .wrap(work_packages,
                                                        timestamps:,
                                                        query:,
                                                        include_only_changed_attributes: true)
                                                  .index_by(&:id)
    end

    def timestamps
      @timestamps ||= query.try(:timestamps) || []
    end

    def override_attributes(work_package, source)
      work_package.attributes = source.attributes.except('timestamp')
      work_package.clear_changes_information
    end

    def set_timestamp_attributes(work_package, source, timestamp)
      work_package.matches_filters_at_timestamp = source.matches_query_filters_at_timestamps.include?(timestamp)
      work_package.exists_at_timestamp = source.exists_at_timestamps.include?(timestamp)
      work_package.attributes_changed_to_baseline = source.changed_at_timestamp(timestamp)
      work_package.with_query = source.query.present?
    end
  end

  module HistoricAttributesAccessors
    extend ActiveSupport::Concern

    included do
      attr_accessor :at_timestamps,
                    :attributes_changed_to_baseline

      attr_writer :with_query,
                  :exists_at_timestamp,
                  :matches_filters_at_timestamp

      def with_query?; @with_query; end
      def exists_at_timestamp?; @exists_at_timestamp; end
      def matches_filters_at_timestamp?; @matches_filters_at_timestamp; end
    end

    def wrapped?
      true
    end
  end

  # The wrapper around a work package only loaded to be then displayed as part of the
  # attributesByTimestamps in the work package representer.
  class AttributesByTimestampWorkPackage < SimpleDelegator
    include HistoricAttributesAccessors

    def initialize(work_package, timestamp)
      super(work_package || WorkPackage.new)

      self.timestamp = timestamp.dup
    end

    attr_writer :timestamp

    def timestamp
      new_record? ? @timestamp : Timestamp.parse(__getobj__.timestamp)
    end

    # Since custom fields are currently never displayed in the attributesByTimestamp,
    # for which this object is used, simply short circuit the loading of the custom field information.
    def available_custom_fields
      WorkPackageCustomField.none
    end

    def define_all_custom_field_accessors
      nil
    end
  end
end
