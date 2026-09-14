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

module OpenProject::Reporting::Patches
  module CustomFieldsControllerPatch
    def self.included(base) # :nodoc:
      base.prepend InstanceMethods
    end

    module InstanceMethods
      # A saved cost report may filter or group by the custom field being
      # deleted, which would leave it referring to something that no longer
      # exists.
      def destroy
        remove_custom_field_from_cost_reports(@custom_field.id)
      rescue StandardError => e
        Rails.logger.error "Failed to remove custom_field #{@custom_field.id} from cost reports. " \
                           "#{e.class}: #{e.message}"
      ensure
        super
      end

      private

      def remove_custom_field_from_cost_reports(id)
        attribute = "cf_#{id}"

        CostReport.includes(:query).find_each do |report|
          remove_dimension_and_filter(report, attribute)
        end
      end

      def remove_dimension_and_filter(report, attribute)
        return unless report.uses_dimension?(attribute) || report.query.uses_filter?(attribute)

        report.remove_dimension(attribute)
        report.query.remove_filter(attribute)
        report.query.save!(validate: false)
        report.save!(validate: false)
      end
    end
  end
end
