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
    attr_accessor :timestamps, :query

    def apply(work_package)
      work_package_with_historic_attributes = work_packages_with_historic_attributes[work_package.id]

      set_non_delegated_properties(work_package,
                                   work_package_with_historic_attributes,
                                   work_package_with_historic_attributes.timestamps.last.to_s)

      work_package.at_timestamps = work_package_with_historic_attributes
                                     .journables_by_timestamp
                                     .map do |timestamp, wp|
        wrapped_wp = HistoricAttributesDelegator.new(wp)
        wrapped_wp.timestamp = timestamp.dup

        set_non_delegated_properties(wrapped_wp,
                                     work_package_with_historic_attributes,
                                     wrapped_wp.timestamp)

        wrapped_wp
      end
    end

    def self.module
      HistoricAttributesAccessors
    end

    private

    def set_non_delegated_properties(work_package, source, timestamp)
      work_package.matches_filters_at_timestamp = source.matches_query_filters_at_timestamps.include?(timestamp)
      work_package.exists_at_timestamp = source.exists_at_timestamps.include?(timestamp)
      work_package.attributes_changed_to_baseline = (source.attributes_by_timestamp[timestamp.to_s]&.to_h || {}).keys.map(&:to_s)
      work_package.with_query = source.query.present?
    end

    # TODO: prepare by indexing by id
    def work_packages_with_historic_attributes
      @work_packages_with_historic_attributes ||= begin
        @timestamps ||= @query.try(:timestamps) || []
        Journable::WithHistoricAttributes \
          .wrap_multiple(work_packages, timestamps: @timestamps, query: @query, include_only_changed_attributes: true)
          .index_by(&:id)
      end
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

  # TODO: Get this in line with the rest of the eager loading
  class HistoricAttributesDelegator < SimpleDelegator
    include HistoricAttributesAccessors

    def initialize(work_package)
      super(work_package || WorkPackage.new)
    end

    attr_writer :timestamp

    def timestamp
      new_record? ? @timestamp : __getobj__.timestamp
    end
  end
end
