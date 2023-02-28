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

# rubocop:disable Metrics/AbcSize
module API::V3::WorkPackages::EagerLoading
  class HistoricAttributes < Base
    attr_accessor :timestamps, :query

    def apply(work_package)
      work_package_array_index = work_packages.map(&:id).find_index(work_package.id)
      work_package_with_historic_attributes = work_packages_with_historic_attributes[work_package_array_index]
      work_package.attributes = work_package_with_historic_attributes.attributes.try(:except, 'timestamp')
      work_package.baseline_attributes = work_package_with_historic_attributes.baseline_attributes
      work_package.attributes_by_timestamp = work_package_with_historic_attributes.attributes_by_timestamp
      work_package.timestamps = work_package_with_historic_attributes.timestamps
      work_package.baseline_timestamp = work_package_with_historic_attributes.baseline_timestamp
      work_package.matches_query_filters_at_baseline_timestamp = \
        work_package_with_historic_attributes.matches_query_filters_at_baseline_timestamp?
      work_package.matches_query_filters_at_timestamps = work_package_with_historic_attributes.matches_query_filters_at_timestamps
      work_package.exists_at_timestamps = work_package_with_historic_attributes.exists_at_timestamps
    end

    def self.module
      HistoricAttributesAccessors
    end

    private

    def work_packages_with_historic_attributes
      @work_packages_with_historic_attributes ||= begin
        @timestamps ||= @query.try(:timestamps) || []
        Journable::WithHistoricAttributes \
          .wrap_multiple(work_packages, timestamps: @timestamps, query: @query, include_only_changed_attributes: true)
      end
    end
  end

  module HistoricAttributesAccessors
    extend ActiveSupport::Concern

    included do
      attr_accessor :baseline_attributes, :attributes_by_timestamp, :timestamps, :baseline_timestamp,
                    :matches_query_filters_at_baseline_timestamp,
                    :matches_query_filters_at_timestamps,
                    :exists_at_timestamps
    end

    # Does the work package match the query filter at the baseline timestamp?
    # Returns `nil` if no query is given.
    #
    def matches_query_filters_at_baseline_timestamp?
      matches_query_filters_at_timestamps.any? ? matches_query_filters_at_baseline_timestamp : nil
    end

    # Does the work package match the query filter at the given timestamp?
    # Returns `nil` if no query is given.
    #
    def matches_query_filters_at_timestamp?(timestamp)
      matches_query_filters_at_timestamps.any? ? matches_query_filters_at_timestamps.include?(timestamp) : nil
    end
  end
end
# rubocop:enable Metrics/AbcSize
