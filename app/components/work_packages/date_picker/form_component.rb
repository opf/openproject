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

# frozen_string_literal: true

module WorkPackages
  module DatePicker
    class FormComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      attr_accessor :form_id, :show_date_form, :work_package, :schedule_manually, :focused_field, :triggering_field,
                    :touched_field_map, :date_mode

      def initialize(form_id:,
                     show_date_form:,
                     work_package:,
                     schedule_manually: true,
                     focused_field: :start_date,
                     triggering_field: nil,
                     touched_field_map: {},
                     date_mode: nil)
        super

        @form_id = form_id
        @show_date_form = show_date_form
        @work_package = work_package
        @schedule_manually = ActiveModel::Type::Boolean.new.cast(schedule_manually)
        @focused_field = focused_field
        @triggering_field = triggering_field
        @touched_field_map = touched_field_map
        @date_mode = date_mode
      end

      private

      def submit_path
        if work_package.new_record?
          # create: get json of selected dates
          date_picker_path
        else
          # update dates of work package
          work_package_date_picker_path(work_package)
        end
      end

      def dialog_content_with(schedule_manually:)
        dialog_params = params.without(:on, :controller, :action)
                              .merge(schedule_manually:)
                              .permit!
        if work_package.new_record?
          preview_date_picker_path(dialog_params)
        else
          preview_work_package_date_picker_path(work_package, dialog_params)
        end
      end

      def disabled?
        !schedule_manually && (milestone? || work_package.children.any?)
      end

      def milestone?
        # Either the work package is a milestone OR in the create form, the angular 'date' field was triggered OR
        # in the WorkPackage create form, the datepicker dialog was already updated via Turbo
        # in which case the field param is overwritten and we have to check whether the duration field is absent
        @milestone ||=
          @work_package.milestone? ||
          params[:field] == "date" ||
          (params[:work_package].present? && params[:work_package][:duration].nil?)
      end

      def disabled_checkbox?
        !schedule_manually && work_package.children.any?
      end
    end
  end
end
