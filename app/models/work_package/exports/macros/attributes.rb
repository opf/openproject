#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
    #   workPackageLabel:1234:subject # Outputs work package label attribute "Subject" + help text
    #   workPackageValue:1234:subject # Outputs the actual subject of #1234
    #
    #   projectLabel:statusExplanation # Outputs current project label attribute "Status description" + help text
    #   projectValue:statusExplanation # Outputs current project value for "Status description"
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
          "[Error: Invalid attribute macro: #{model_s}]"
        end
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
        return "[Error: Invalid attribute macro: #{type}]" unless type == "value"

        work_package = WorkPackage.find_by(id:)
        if work_package.nil? || !user.allowed_in_project?(:view_work_packages, work_package.project)
          return "[Error: #{WorkPackage.name} #{id} not found}]"
        end

        resolve_value_work_package(work_package, attribute)
      end

      def self.resolve_project_match(id, type, attribute, user)
        return resolve_label_project(attribute) if type == "label"
        return "[Error: Invalid attribute macro: #{type}]" unless type == "value"

        project = Project.find_by(id:)
        if project.nil? || !user.allowed_in_project?(:view_project, project)
          return "[Error: #{Project.name} #{id} not found}]"
        end

        resolve_value_project(project, attribute)
      end

      def self.escape_tags(value)
        # only disable html tags, but do not replace html entities
        value.to_s.gsub("<", "&lt;").gsub(">", "&gt;")
      end

      def self.resolve_value_project(project, attribute)
        cf = CustomField.find_by(name: attribute, type: "ProjectCustomField")
        if cf.nil?
          ar_name = ::API::Utilities::PropertyNameConverter.to_ar_name(attribute.to_sym, context: project)
        else
          ar_name = "cf_#{cf.id}"
          # currently we do not support embedding rich text fields: long text custom fields
          return "[Rich text embedding currently not supported in export]" if cf.formattable?

          # TODO: Is the user allowed to see this custom field/"project attribute"?
        end

        # currently we do not support embedding rich text field: e.g. projectValue:1234:description
        if DISABLED_PROJECT_RICH_TEXT_FIELDS.include?(ar_name.to_sym)
          return "[Rich text embedding currently not supported in export]"

        end

        format_attribute_value(ar_name, Project, project)
      end

      def self.resolve_value_work_package(work_package, attribute)
        cf = CustomField.find_by(name: attribute, type: "WorkPackageCustomField")
        if cf.nil?
          ar_name = ::API::Utilities::PropertyNameConverter.to_ar_name(attribute.to_sym, context: work_package)
        else
          ar_name = "cf_#{cf.id}"
          # currently we do not support embedding rich text fields: long text custom fields
          return "[Rich text embedding currently not supported in export]" if cf.formattable?

          # TODO: Are there access restrictions on work_package custom fields?
        end

        # currently we do not support embedding rich text field: workPackageValue:1234:description
        if DISABLED_WORK_PACKAGE_RICH_TEXT_FIELDS.include?(ar_name.to_sym)
          return "[Rich text embedding currently not supported in export]"

        end

        format_attribute_value(ar_name, WorkPackage, work_package)
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
