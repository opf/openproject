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

module ResourceAllocations
  module Forms
    class WorkPackageForm < ApplicationForm
      # Switching the work package changes the dates the allocation is checked
      # against, so it refreshes the "outside dates" banner like the date
      # fields do.
      REFRESH_ACTION = "change->refresh-on-form-changes#triggerTurboStream"

      form do |f|
        f.hidden name: :entity_type, value: "WorkPackage"
        f.work_package_autocompleter(
          name: :entity_id,
          label: WorkPackage.model_name.human,
          required: true,
          invalid: entity_error.present?,
          validation_message: entity_error,
          autocomplete_options: {
            openDirectly: false,
            focusDirectly: false,
            dropdownPosition: "bottom",
            appendTo: "##{@dialog_id}",
            filters: [{ name: "project_id", operator: "=", values: [@project.id.to_s] }],
            hiddenFieldAction: REFRESH_ACTION
          }
        )
      end

      def initialize(project:, dialog_id:)
        super()
        @project = project
        @dialog_id = dialog_id
      end

      private

      # The field is `entity_id` but the model keys errors on the polymorphic
      # `entity`/`entity_type`; relabel them onto this field.
      def entity_error
        messages = model.errors.messages_for(:entity) + model.errors.messages_for(:entity_type)
        messages
          .map { |message| "#{WorkPackage.model_name.human} #{message}" }
          .join(" ")
          .presence
      end
    end
  end
end
