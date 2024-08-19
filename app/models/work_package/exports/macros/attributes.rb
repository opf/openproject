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
        context => { user:, work_package: }
        type = match[2].downcase
        model_s = match[1]
        id = match[4] || match[3]
        attribute = match[6] || match[5]
        resolve_match(type, model_s, id, attribute, work_package, user)
      end

      def self.resolve_match(type, model_s, id, attribute, work_package, user)
        if model_s == "workPackage"
          resolve_work_package_match(id || work_package.id, type, attribute, user)
        elsif model_s == "project"
          resolve_project_match(id || work_package.project.id, type, attribute, user)
        else
          msg_macro_error I18n.t("export.macro.model_not_found", model: model_s)
        end
      end

      def self.msg_macro_error(message)
        msg_inline I18n.t("export.macro.error", message:)
      end

      def self.msg_macro_error_rich_text
        msg_inline I18n.t("export.macro.rich_text_unsupported")
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
        model.human_attribute_name(
          ::API::Utilities::PropertyNameConverter.to_ar_name(attribute.to_sym, context: model.new)
        )
      end

      def self.resolve_work_package_match(id, type, attribute, user)
        return resolve_label_work_package(attribute) if type == "label"
        return msg_macro_error(I18n.t("export.macro.model_not_found", model: type)) unless type == "value"

        work_package = WorkPackage.visible(user).find_by(id:)
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
        cf = obj.available_custom_fields.find { |pcf| pcf.name == attribute }

        return msg_macro_error_rich_text if cf&.formattable?

        ar_name = if cf.nil?
                    ::API::Utilities::PropertyNameConverter.to_ar_name(attribute.to_sym, context: obj)
                  else
                    "cf_#{cf.id}"
                  end
        return msg_macro_error_rich_text if disabled_rich_text_fields.include?(ar_name.to_sym)

        format_attribute_value(ar_name, obj.class, obj)
      end

      def self.format_attribute_value(ar_name, model, obj)
        formatter = Exports::Register.formatter_for(model, ar_name, :pdf)
        value = formatter.format(obj)
        # important NOT to return empty string as this could change meaning of markdown
        # e.g. **to_be_replaced** could be rendered as **** (horizontal line and a *)
        value.blank? ? " " : escape_tags(value)
      end
    end
  end
end
