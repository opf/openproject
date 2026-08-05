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

module OpenProject::TextFormatting
  module Matchers
    # OpenProject attribute macros syntax
    # Examples:
    #   workPackageLabel:subject      # Outputs work package label attribute "Subject" + help text
    #   workPackageLabel:1234:subject # Outputs work package label attribute "Subject" + help text
    #   workPackageValue:subject      # Outputs the actual subject of #1234 of the current work package 1234 if applicable
    #   workPackageValue:1234:subject # Outputs the actual subject of #1234
    #
    #   workPackageValue:1234:targetVersions:singleline # Outputs the values of #1234 on a single line
    #   workPackageValue:1234:targetVersions:multiline  # Outputs the values of #1234 on multiple lines (default)
    #
    #   projectLabel:statusExplanation # Outputs current project label attribute "Status description" + help text
    #   projectValue:statusExplanation # Outputs current project value for "Status description"
    class AttributeMacros < RegexMatcher
      # Reserved keywords of the optional layout argument. An attribute with
      # such a name can still be referenced by quoting it.
      LAYOUTS = %w[multiline singleline].freeze

      def self.regexp
        %r{
          (?<model>\w+)(?<type>Label|Value) # The model type we try to reference
          (?::(?:(?<id>[^":\s]+)|"(?<quoted_id>[^"]+)"))? # Optional: An ID or subject reference
          (?::(?<attribute>[^":\s.]+|"(?<quoted_attribute>[^"]+)")) # The attribute name we're trying to reference
          (?::(?<layout>#{LAYOUTS.join('|')})\b)? # Optional: A layout argument (whole keyword only)
        }x
      end

      ##
      # Faster inclusion check before the regex is being applied
      def self.applicable?(content)
        content.include?("Label:") || content.include?("Value:")
      end

      def self.work_package_context?(context)
        #  workPackageValue can be used in e.g. wiki and meeting notes without a work package,
        #  relative embedding is not supported in these cases
        #  work package list view or the work package fullscreen view use the wrapper via API calls, not the WorkPackage model
        context[:object].is_a?(API::V3::WorkPackages::WorkPackageEagerLoadingWrapper) || context[:object].is_a?(WorkPackage)
      end

      def self.work_package_embed?(macro_attributes)
        macro_attributes[:model] == "workPackage"
      end

      def self.project_embed?(macro_attributes)
        macro_attributes[:model] == "project"
      end

      def self.relative_embed?(macro_attributes)
        macro_attributes[:id].nil?
      end

      def self.relative_id(macro_attributes, context)
        if project_embed?(macro_attributes) && context[:project].present?
          context[:project].try(:id)
        elsif work_package_embed?(macro_attributes) && work_package_context?(context)
          context[:object].try(:id)
        end
      end

      def self.process_match(match, _matched_string, context)
        type = match[:type].downcase

        ApplicationController.helpers.content_tag "opce-macro-attribute-#{type}",
                                                  "",
                                                  data: extract_macro_attributes(match, context).compact
      end

      def self.extract_macro_attributes(match, context)
        macro_attributes = {
          model: match[:model],
          id: match[:quoted_id] || match[:id],
          attribute: match[:quoted_attribute] || match[:attribute],
          layout: match[:layout]
        }

        macro_attributes = reinterpret_as_relative_embed(macro_attributes, quoted_attribute: !match[:quoted_attribute].nil?)
        macro_attributes[:id] = relative_id(macro_attributes, context) if relative_embed?(macro_attributes)
        macro_attributes
      end

      ##
      # In the relative form (workPackageValue:targetVersions:singleline), the
      # regex binds the attribute to the id slot and the layout keyword to the
      # attribute slot. A bare attribute matching a reserved layout keyword
      # marks that form, so shift the segments into a relative embed.
      def self.reinterpret_as_relative_embed(macro_attributes, quoted_attribute:)
        return macro_attributes if macro_attributes[:layout] || quoted_attribute || macro_attributes[:id].nil?
        return macro_attributes unless LAYOUTS.include?(macro_attributes[:attribute])

        macro_attributes.merge(
          layout: macro_attributes[:attribute],
          attribute: macro_attributes[:id],
          id: nil
        )
      end
    end
  end
end
