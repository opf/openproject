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
      work_package_with_historic_attributes = work_packages_with_historic_attributes.detect { |wp| wp.id == work_package.id }
      work_package.attributes = work_package_with_historic_attributes.attributes.except('timestamp')
      work_package.baseline_attributes = work_package_with_historic_attributes.baseline_attributes
      work_package.attributes_by_timestamp = work_package_with_historic_attributes.attributes_by_timestamp
    end

    def self.module
      HistoricAttributesAccessors
    end

    private

    def work_packages_with_historic_attributes
      @work_packages_with_historic_attributes ||= begin
        @timestamps ||= @query.try(:timestamps) || []
        Journable::WithHistoricAttributes.wrap_multiple(work_packages, timestamps: @timestamps, query: @query)  # TODO: rename wrap to wrap_one, wrap_multiple to wrap
      end
    end

  end

  module HistoricAttributesAccessors
    extend ActiveSupport::Concern

    included do
      attr_accessor :baseline_attributes, :attributes_by_timestamp
    end
  end
end
