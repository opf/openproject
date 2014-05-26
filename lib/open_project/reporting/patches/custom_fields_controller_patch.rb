#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require_dependency 'costlog_controller'

module OpenProject::Reporting::Patches
  module CustomFieldsControllerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        alias_method_chain :destroy, :custom_fields
      end
    end

    module InstanceMethods

      def destroy_with_custom_fields
        id = @custom_field.id

        destroy_without_custom_fields

        if @custom_field.destroyed?
          custom_field_name = "CustomField#{id}"
          reports = CostQuery.where("serialized LIKE '%CustomField#{id}%'")

          reports.each do |report|
            filters = report.serialized[:filters].reject { |f| f[0] == custom_field_name }
            group_bys = report.serialized[:group_bys].reject { |f| f[0] == custom_field_name }
            updated_report = build_query(report.engine, filters, group_bys)
            report.migrate(updated_report)
            report.save!
          end
        end
      end

      private

      def build_query(report_engine, filters, groups = {})
        query = report_engine.deserialize({ filters: filters, group_bys: groups })
        query.serialize
        query
      end
    end
  end
end
