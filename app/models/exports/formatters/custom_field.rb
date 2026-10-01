# frozen_string_literal: true

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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Exports
  module Formatters
    class CustomField < Default
      def self.apply?(attribute, export_format)
        export_format != :pdf && attribute.start_with?("cf_")
      end

      ##
      # Takes a WorkPackage or Project and an attribute and returns the value to be exported.
      def retrieve_value(object)
        custom_field = find_custom_field(object)
        return nil if custom_field.nil?

        format_for_export(object, custom_field)
      end

      ##
      # Print the value meant for export.
      #
      # - For boolean values, don't use the Yes/No formatting for the UI
      #   treat nil as false
      # - For long text values, output the plain value
      # - For hierarchy values, print out the full hierarchy of the item(s)
      def format_for_export(object, custom_field)
        case custom_field.field_format
        when "bool"
          value = object.typed_custom_value_for(custom_field)
          value == nil ? false : value
        when "text"
          object.typed_custom_value_for(custom_field)
        when "hierarchy", "weighted_item_list"
          HierarchyFormatter.new.format(object, custom_field)
        else
          object.formatted_custom_value_for(custom_field)
        end
      end

      ##
      # Finds a custom field from the attribute identifier
      def find_custom_field(object)
        id = attribute.to_s.delete_prefix("cf_").to_i
        object.available_custom_fields.find { it.id == id }
      end
    end
  end
end
