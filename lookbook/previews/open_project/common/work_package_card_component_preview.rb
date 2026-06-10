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

module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class WorkPackageCardComponentPreview < ViewComponent::Preview
      # See the [component documentation](/lookbook/pages/components/work_packages/card) for more details.
      #
      # @param show_assignee toggle
      # @param show_priority toggle
      # @param show_drag_handle toggle
      # @param show_parent toggle
      # @param link_subject toggle
      # @param show_metric toggle
      # @param show_menu toggle
      # @param additional_details toggle
      # @param status_scheme select [default, secondary]
      def playground(show_assignee: false, show_priority: false, show_drag_handle: false,
                     show_parent: false, link_subject: true, show_metric: false, show_menu: false,
                     additional_details: false, status_scheme: :default)
        work_package = WorkPackage.visible.where.not(parent_id: nil).first || WorkPackage.visible.first
        return preview_message("No work packages in the database.") unless work_package

        render_with_template(template: "open_project/common/work_package_card_component_preview/playground",
                             locals: {
                               work_package:,
                               show_assignee:,
                               show_priority:,
                               show_drag_handle:,
                               show_parent:,
                               link_subject:,
                               show_metric:,
                               show_menu:,
                               additional_details:,
                               status_scheme:
                             })
      end

      # Minimal card showing only the info line, subject and actions menu.
      def default
        work_package = WorkPackage.visible.first
        return preview_message("No work packages in the database.") unless work_package

        render OpenProject::Common::WorkPackageCardComponent.new(work_package:)
      end

      # Card with a numeric metric (e.g. story points) in the top-right area.
      def with_metric
        work_package = WorkPackage.visible.first
        return preview_message("No work packages in the database.") unless work_package

        render OpenProject::Common::WorkPackageCardComponent.new(work_package:) do |card|
          card.with_metric { (work_package.try(:story_points) || 8).to_s }
        end
      end

      # Card with a custom actions menu.
      def with_menu
        work_package = WorkPackage.visible.first
        return preview_message("No work packages in the database.") unless work_package

        render OpenProject::Common::WorkPackageCardComponent.new(work_package:) do |card|
          card.with_menu do |menu|
            menu.with_item(label: "Open", href: "/work_packages/#{work_package.id}")
            menu.with_item(label: "Edit", href: "/work_packages/#{work_package.id}/edit")
            menu.with_divider
            menu.with_item(label: "Delete", scheme: :danger)
          end
        end
      end

      # Card with a drag handle icon for reorderable lists.
      def with_drag_handle
        work_package = WorkPackage.visible.first
        return preview_message("No work packages in the database.") unless work_package

        render OpenProject::Common::WorkPackageCardComponent.new(
          work_package:,
          show_drag_handle: true
        )
      end

      # Card with show_parent enabled. Renders a link to the parent work package in row 3.
      # Only visible when the work package actually has a parent.
      def with_parent
        work_package = WorkPackage.visible.where.not(parent_id: nil).first
        return preview_message("No work packages with a parent found.") unless work_package

        render OpenProject::Common::WorkPackageCardComponent.new(
          work_package:,
          show_parent: true
        )
      end

      # Card with additional content in the bottom slot (row 3), rendered alongside the parent link.
      def with_additional_details
        work_package = WorkPackage.visible.first
        return preview_message("No work packages in the database.") unless work_package

        render_with_template(template: "open_project/common/work_package_card_component_preview/with_additional_details",
                             locals: { work_package: })
      end

      private

      def preview_message(text)
        render(Primer::Beta::Blankslate.new) do |b|
          b.with_heading(tag: :h4).with_content(text)
        end
      end
    end
  end
end
