# frozen_string_literal: true

# -- copyright
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
# ++

module WorkPackages
  module Progress
    # Form glue shared by every controller that renders the progress modal:
    # parses the hidden `*_touched` inputs so only fields the user actually
    # edited are written, picks the mode-appropriate attributes, and builds the
    # modal body component.
    module ModalParams
      extend ActiveSupport::Concern

      ERROR_PRONE_ATTRIBUTES = %i[status_id
                                  estimated_hours
                                  remaining_hours
                                  done_ratio].freeze

      private

      def progress_modal_component(submit_path: nil)
        modal_class.new(@work_package,
                        focused_field:,
                        touched_field_map:,
                        submit_path:)
      end

      def modal_class
        if WorkPackage.status_based_mode?
          WorkPackages::Progress::StatusBased::ModalBodyComponent
        else
          WorkPackages::Progress::WorkBased::ModalBodyComponent
        end
      end

      def focused_field
        params[:field]
      end

      def set_progress_attributes_to_work_package
        WorkPackages::SetAttributesService
          .new(user: current_user,
               model: @work_package,
               contract_class:)
          .call(work_package_progress_params)
      end

      def contract_class
        if @work_package.new_record?
          WorkPackages::CreateContract
        else
          WorkPackages::UpdateContract
        end
      end

      def work_package_progress_params
        params.require(:work_package)
              .slice(*allowed_touched_params)
              .permit!
      end

      def allowed_touched_params
        allowed_params.filter { touched?(it) }
      end

      def allowed_params
        if WorkPackage.status_based_mode?
          %i[estimated_hours status_id]
        else
          %i[estimated_hours remaining_hours done_ratio]
        end
      end

      def touched?(field)
        touched_field_map[:"#{field}_touched"]
      end

      # Tolerates a missing `work_package` param so the modal can be opened
      # without carrying the form values along (e.g. from a context menu).
      def touched_field_map
        (params[:work_package] || ActionController::Parameters.new)
          .slice("estimated_hours_touched",
                 "remaining_hours_touched",
                 "done_ratio_touched",
                 "status_id_touched")
          .transform_values { it == "true" }
          .permit!
      end

      def extra_error_messages(service_call)
        errors_not_handled_by_progress_modal = service_call.errors.reject do |error|
          ERROR_PRONE_ATTRIBUTES.include?(error.attribute)
        end

        join_flash_messages(errors_not_handled_by_progress_modal.map(&:full_message))
      end
    end
  end
end
