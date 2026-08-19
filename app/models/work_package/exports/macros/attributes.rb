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
    #   workPackageValue:"custom field name" # Outputs the custom field value of the current work package
    #   workPackageValue:1234:"custom field name" # Outputs the custom field value of #1234
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

      def self.regexp
        %r{
          (\w+)(Label|Value) # The model type we try to reference
          (?::(?:([^"\s]+)|"([^"]+)"))? # Optional: An ID or subject reference
          (?::([^"\s.]+|"([^".]+)")) # The attribute name we're trying to reference
        }x
      end

      ##
      # Faster inclusion check before the regex is being applied
      def self.applicable?(content)
        content.include?("Label:") || content.include?("Value:")
      end

      def self.process_match(match, _matched_string, context)
        type = match[2].downcase
        model_s = match[1].downcase
        id = match[4] || match[3]
        attribute = match[6] || match[5]
        resolve_match(type, model_s, id, attribute, context)
      end

      def self.resolve_match(type, model_s, id, attribute, context)
        if model_s == "workpackage"
          resolve_work_package_match(id || context[:work_package]&.id, type, attribute, context[:user])
        elsif model_s == "project"
          resolve_project_match(id || context[:project]&.id, type, attribute, context[:user])
        else
          msg_macro_error I18n.t("export.macro.model_not_found", model: model_s)
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

      def self.resolve_work_package_match(id, type, attribute, user)
        return resolve_label_work_package(attribute) if type == "label"
        return msg_macro_error(I18n.t("export.macro.model_not_found", model: type)) unless type == "value"

        work_package = WorkPackage.visible(user).find_by_display_id(id)
        if work_package.nil?
          return msg_macro_error(I18n.t("export.macro.resource_not_found", resource: "#{WorkPackage.name} #{id}"))
        end

        resolve_value_work_package(work_package, attribute)
      end

      def self.resolve_project_match(id, type, attribute, user)
        return resolve_label_project(attribute) if type == "label"
        return msg_macro_error(I18n.t("export.macro.model_not_found", model: type)) unless type == "value"

        project = Project.visible(user).find_by(id:)
        project = Project.visible(user).find_by(identifier: id) if project.nil?
        if project.nil?
          return msg_macro_error(I18n.t("export.macro.resource_not_found", resource: "#{Project.name} #{id}"))
        end

        resolve_value_project(project, attribute)
      end

      def self.escape_tags(value)
        # only disable html tags, but do not replace html entities
        value.to_s.gsub("<", "&lt;").gsub(">", "&gt;")
      end

      def self.resolve_value_project(project, attribute)
        resolve_value(project, attribute, DISABLED_PROJECT_RICH_TEXT_FIELDS)
      end

      def self.resolve_value_work_package(work_package, attribute)
        resolve_value(work_package, attribute, DISABLED_WORK_PACKAGE_RICH_TEXT_FIELDS)
      end

      def self.resolve_value(obj, attribute, disabled_rich_text_fields)
        custom_field = find_custom_field(obj, attribute)

        attribute_name = convert_to_attribute_name(custom_field, attribute, obj)
        return " " unless can_view_attribute?(custom_field, obj, attribute_name)

        is_rich_text = custom_field&.formattable? || disabled_rich_text_fields.include?(attribute_name.to_sym)
        [format_attribute_value(attribute_name, obj.class, obj, is_rich_text), is_rich_text]
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

      def self.format_attribute_value(ar_name, model, obj, is_rich_text)
        formatter = Exports::Register.formatter_for(model, ar_name, :pdf)
        value = formatter.format(obj)
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
