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
# See COPYRIGHT and LICENSE files for more details.
#++

module ResourceAllocations
  module AllocationStep
    # The criteria of the resource an allocation asks for, shown read-only:
    # a resource is picked from the catalogue here, never described inline.
    #
    # Streamable so picking a resource refreshes just this section — the same
    # round-trip the date fields already use for their warning banner.
    class ResourceFilterComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      def initialize(allocation:)
        super
        @allocation = allocation
      end

      def call
        component_wrapper do
          next if user_resource.nil?

          render(Primer::Box.new(mt: 2)) do
            render(Primer::Beta::Text.new(tag: :div, font_weight: :bold, mb: 1)) do
              I18n.t("resource_management.allocate_resource_dialog.criteria.label")
            end + criteria_text
          end
        end
      end

      private

      def user_resource
        @allocation.user_resource
      end

      def criteria
        @criteria ||= ::Queries::FilterSummary.new(user_resource.user_filter).phrases
      end

      def criteria_text
        text = criteria.presence&.join(" · ") ||
          I18n.t("resource_management.allocate_resource_dialog.criteria.empty")

        render(Primer::Beta::Text.new(tag: :div, color: :muted)) { text }
      end
    end
  end
end
