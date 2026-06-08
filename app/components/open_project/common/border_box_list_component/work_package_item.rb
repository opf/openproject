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

module OpenProject
  module Common
    class BorderBoxListComponent
      # BorderBox list row that renders a work package card.
      #
      # Specialized rows can subclass this component and override `build_card`
      # to provide a different card component while keeping row behavior.
      class WorkPackageItem < ApplicationComponent
        include ActionView::RecordIdentifier
        include Primer::ClassNameHelper
        include Primer::AttributesHelper

        attr_reader :work_package,
                    :project,
                    :container,
                    :params,
                    :current_user

        # Delegates card slots so callers can configure the rendered card from
        # `with_work_package_item`.
        delegate :with_metric, :with_menu, to: :card

        # @param work_package [WorkPackage] work package rendered by the card.
        # @param project [Project] project context for row behavior.
        # @param container [String, Array<String, Symbol>] parent list container id seed.
        # @param params [Hash] request params used by specialized item classes.
        # @param current_user [User] user context for specialized item classes.
        # @param system_arguments [Hash] forwarded to Primer's BorderBox row.
        def initialize(
          work_package:,
          project:,
          container:,
          params: {},
          current_user: User.current,
          **system_arguments
        )
          super()

          @work_package = work_package
          @project = project
          @container = container
          @params = params
          @current_user = current_user
          @system_arguments = system_arguments
        end

        # @return [Hash] arguments forwarded to Primer's BorderBox row.
        def row_args
          row_arguments = @system_arguments.deep_dup
          row_arguments[:id] ||= dom_id(work_package)
          row_arguments[:tabindex] ||= 0
          row_arguments[:test_selector] ||= "work-package-#{work_package.id}"
          row_arguments[:classes] = class_names(
            row_classes,
            row_arguments[:classes]
          )
          row_arguments[:data] = merge_data(
            { data: row_data },
            row_arguments
          )
          row_arguments
        end

        def before_render
          content
        end

        def call
          render(card)
        end

        # @return [ApplicationComponent] card component rendered inside the row.
        def card
          @card ||= build_card
        end

        private

        # Override in subclasses to render a specialized work-package card.
        #
        # @return [ApplicationComponent]
        def build_card
          WorkPackageCardComponent.new(work_package:, classes: "Box-card")
        end

        def row_classes
          class_names(
            "Box-row--hover-blue",
            "Box-row--focus-gray",
            "Box-row--clickable",
            "Box-row--draggable" => draggable?
          )
        end

        def row_data
          draggable? ? draggable_data : {}
        end

        def draggable?
          false
        end

        def draggable_data
          {}
        end
      end
    end
  end
end
