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
      def destroy
        id = @custom_field.id
        begin
          reports = CostQuery.where("serialized LIKE '%CustomField#{id}%'")

          remove_custom_field_from_cost_report(reports, id)
          remove_custom_field_from_session(id)
        rescue StandardError => e
          Rails.logger.error "Failed to remove custom_field #{id} from custom queries. " \
                             "#{e.class}: #{e.message}"
        ensure
          super
        end
      end

      private

      def remove_custom_field_from_cost_report(affected_reports, id)
        custom_field_name = "CustomField#{id}"

        affected_reports.each do |report|
          filters = reject_from_query_properties(report, :filters, custom_field_name)
          group_bys = reject_from_query_properties(report, :group_bys, custom_field_name)
          updated_report = build_query(report.engine, filters, group_bys)
          report.migrate(updated_report)
          report.save!
        end
      end

      def reject_from_query_properties(report, property, custom_field_name)
        report.serialized[property].reject { |f| f[0] == custom_field_name }
      end

      def build_query(report_engine, filters, groups = {})
        query = report_engine.deserialize({ filters:, group_bys: groups })
        query.serialize
        query
      end

      def remove_custom_field_from_session(id)
        custom_field_name = :"custom_field#{id}"
        report_engine_name = CostQuery.name.underscore.to_sym
        cookie = session[report_engine_name]

        if cookie
          cookie[:filters][:operators].delete(custom_field_name)
          cookie[:filters][:values].delete(custom_field_name)
          cookie[:groups][:rows].delete(custom_field_name.to_s)
          cookie[:groups][:columns].delete(custom_field_name.to_s)

          session[report_engine_name] = cookie
        end
      end
    end
  end
end
