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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module CustomFields
  module Inputs
    module VersionSelect
      protected

      def version_input_attributes
        input_attributes.deep_merge(additional_attributes)
      end

      def additional_attributes
        autocomplete_options = { groupBy: "group_by" }

        if @object.blank? || (@object.respond_to?(:project) && @object.project.blank?)
          autocomplete_options[:disabled] = true
          autocomplete_options[:placeholder] = I18n.t("custom_fields.placeholder_version_select")
        end

        { autocomplete_options: }
      end

      def assignable_versions(only_open:)
        if @object.is_a?(Project)
          @object.assignable_versions(only_open:)
        elsif @object.respond_to?(:project) && @object.project.present?
          @object.project.assignable_versions(only_open:)
        else
          Version.none
        end
      end
    end
  end
end
