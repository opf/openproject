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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++
module WorkPackage::Exports
  module Macros
    # OpenProject attribute macros syntax
    # Examples:
    #   workPackageLabel:subject # Outputs work package label attribute "Subject"
    #   workPackageLabel:1234:subject # Outputs work package label attribute "Subject"

    #   workPackageValue:subject # Outputs the subject of the current work package
    #   workPackageValue:1234:subject # Outputs the subject of #1234
    #   workPackageValue:PROJ-10:subject # Outputs the subject of PROJ-10 (semantic identifier mode)
    #   workPackageValue:"custom field name" # Outputs the custom field value of the current work package
    #   workPackageValue:1234:"custom field name" # Outputs the custom field value of #1234
    #
    #   workPackageValue:1234:targetVersions:singleline # Outputs the values of #1234 comma-separated (export default)
    #   workPackageValue:PROJ-10:targetVersions:singleline # Outputs the values of PROJ-10 comma-separated
    #   workPackageValue:1234:targetVersions:multiline # Outputs the values of #1234 one per line
    #   workPackageValue:1234:categories:singleline # Outputs the values of #1234 comma-separated (export default)
    #   workPackageValue:1234:categories:multiline # Outputs the values of #1234 one per line
    #
    #   projectLabel:active # Outputs current project label attribute "active"
    #   projectLabel:1234:active # Outputs project label attribute "active"
    #   projectLabel:my-project-identifier:active # Outputs project label attribute "active"

    #   projectValue:active # Outputs current project value for "active"
    #   projectValue:1234:active # Outputs project with id 1234 value for "active"
    #   projectValue:my-project-identifier:active # Outputs project with identifier my-project-identifier value for "active"
    class Attributes < OpenProject::TextFormatting::Matchers::RegexMatcher
      extend WorkPackage::Exports::Attributes

      DISABLED_PROJECT_RICH_TEXT_FIELDS = %i[description status_explanation status_description].freeze
      DISABLED_WORK_PACKAGE_RICH_TEXT_FIELDS = %i[description].freeze
      LAYOUTS = OpenProject::TextFormatting::Matchers::AttributeMacros::LAYOUTS

      def self.regexp
        %r{
          (?<model>\w+)(?<type>Label|Value) # The model type we try to reference
          (?::(?:(?<id>[^":\s]+)|"(?<quoted_id>[^"]+)"))? # Optional: An ID or subject reference
          (?::(?<attribute>[^":\s.]+|"(?<quoted_attribute>[^".]+)")) # The attribute name we're trying to reference
          (?::(?<layout>#{LAYOUTS.join('|')})\b)? # Optional: A layout argument (whole keyword only)
        }x
      end

      ##
      # Faster inclusion check before the regex is being applied
      def self.applicable?(content)
        content.include?("Label:") || content.include?("Value:")
      end

      def self.process_match(match, _matched_string, context)
        macro_attributes = {
          model: match[:model].downcase,
          id: match[:quoted_id] || match[:id],
          attribute: match[:quoted_attribute] || match[:attribute],
          layout: match[:layout]
        }
        macro_attributes = OpenProject::TextFormatting::Matchers::AttributeMacros
          .reinterpret_as_relative_embed(macro_attributes, quoted_attribute: !match[:quoted_attribute].nil?)

        resolve_match(match[:type].downcase, macro_attributes, context)
      end

      def self.resolve_match(type, macro_attributes, context)
        id, attribute, layout = macro_attributes.values_at(:id, :attribute, :layout)

        case macro_attributes[:model]
        when "workpackage"
          resolve_work_package_match(id || context[:work_package]&.id, type, attribute, context[:user], layout:)
        when "project"
          resolve_project_match(id || context[:project]&.id, type, attribute, context[:user], layout:)
        else
          msg_macro_error I18n.t("export.macro.model_not_found", model: macro_attributes[:model])
        end
      end

      def self.msg_macro_error(message)
        msg_inline I18n.t("export.macro.error", message:)
      end

      def self.msg_inline(message)
        "[#{message}]"
      end

      def self.resolve_label_work_package(attribute)
        resolve_label(WorkPackage, attribute)
      end

      def self.resolve_label_project(attribute)
        resolve_label(Project, attribute)
      end

      def self.resolve_label(model, attribute)
        model.human_attribute_name(to_ar_name(attribute, model.new))
      end

      def self.to_ar_name(attribute, context)
        ::API::Utilities::PropertyNameConverter.to_ar_name(attribute.to_sym, context:)
      end

      ##
      # Resolves a work package or project match based on the type and id.
      # Returns the formatted value or an error message if not found.
      #
      # @param id [String] The ID of the work package or project.
      # @param type [String] The type of the match (label or value).
      # @param attribute [String] The attribute to resolve.
      # @param user [User] The user context for visibility checks.

      def self.resolve_work_package_match(id, type, attribute, user, layout: nil)
        return resolve_label_work_package(attribute) if type == "label"
        return msg_macro_error(I18n.t("export.macro.model_not_found", model: type)) unless type == "value"

        work_package = WorkPackage.visible(user).find_by_display_id(id)
        if work_package.nil?
          return msg_macro_error(I18n.t("export.macro.resource_not_found", resource: "#{WorkPackage.name} #{id}"))
        end

        resolve_value_work_package(work_package, attribute, layout:)
      end

      def self.resolve_project_match(id, type, attribute, user, layout: nil)
        return resolve_label_project(attribute) if type == "label"
        return msg_macro_error(I18n.t("export.macro.model_not_found", model: type)) unless type == "value"

        project = Project.visible(user).find_by(id:)
        project = Project.visible(user).find_by(identifier: id) if project.nil?
        if project.nil?
          return msg_macro_error(I18n.t("export.macro.resource_not_found", resource: "#{Project.name} #{id}"))
        end

        resolve_value_project(project, attribute, layout:)
      end

      # Values are comma-joined unless the multiline layout is requested
      # explicitly; its separator ends in two spaces + newline, the markdown
      # hard line break, so each value renders on its own line in the export.
      def self.array_separator(layout)
        layout == "multiline" ? "  \n" : ", "
      end

      def self.escape_tags(value)
        # only disable html tags, but do not replace html entities
        value.to_s.gsub("<", "&lt;").gsub(">", "&gt;")
      end

      def self.resolve_value_project(project, attribute, layout: nil)
        resolve_value(project, attribute, DISABLED_PROJECT_RICH_TEXT_FIELDS, layout:)
      end

      def self.resolve_value_work_package(work_package, attribute, layout: nil)
        resolve_value(work_package, attribute, DISABLED_WORK_PACKAGE_RICH_TEXT_FIELDS, layout:)
      end

      def self.resolve_value(obj, attribute, disabled_rich_text_fields, layout: nil)
        custom_field = find_custom_field(obj, attribute)

        attribute_name = convert_to_attribute_name(custom_field, attribute, obj)
        attribute_name = map_legacy_multi_value_attribute(attribute_name, obj)
        return " " unless can_view_attribute?(custom_field, obj, attribute_name)

        is_rich_text = custom_field&.formattable? || disabled_rich_text_fields.include?(attribute_name.to_sym)
        [format_attribute_value(attribute_name, obj.class, obj, is_rich_text, layout:), is_rich_text]
      end

      # The deprecated single-valued attributes render the whole set that replaces
      # them.
      LEGACY_MULTI_VALUE_ATTRIBUTES = { "version" => "target_versions", "category" => "categories" }.freeze

      def self.map_legacy_multi_value_attribute(attribute_name, obj)
        return attribute_name unless obj.is_a?(WorkPackage)

        LEGACY_MULTI_VALUE_ATTRIBUTES.fetch(attribute_name, attribute_name)
      end

      def self.can_view_attribute?(custom_field, obj, attribute_name)
        custom_field || allowed_to_view_attribute?(obj, attribute_name)
      end

      def self.convert_to_attribute_name(custom_field, attribute, obj)
        if custom_field.nil?
          to_ar_name(attribute, obj)
        else
          "cf_#{custom_field.id}"
        end
      end

      def self.find_custom_field(obj, attribute)
        obj.available_custom_fields.find { |pcf| pcf.name == attribute }
      end

      def self.format_attribute_value(ar_name, model, obj, is_rich_text, layout: nil)
        formatter = Exports::Register.formatter_for(model, ar_name, :pdf)
        value = formatter.format(obj, array_separator: array_separator(layout))
        # do NOT escape a tag for custom field link
        return value.to_html if value.is_a?(::Exports::Formatters::LinkFormatter)

        # important NOT to return empty string as this could change meaning of markdown
        # e.g. **to_be_replaced** could be rendered as **** (horizontal line and a *)
        return " " if value.blank?

        is_rich_text ? value : escape_tags(value)
      end
    end
  end
end
