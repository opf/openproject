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
  module AllocationStep
    class FooterComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      # `dialog_id` and `submit_label` default to the create wizard's; the edit
      # dialog passes its own. `allocation` is only passed by the edit dialog, so
      # the destructive Delete action stays out of the create wizard.
      def initialize(dialog_id: ResourceAllocations::NewDialogComponent::DIALOG_ID,
                     submit_label: I18n.t("resource_management.allocate_resource_dialog.submit"),
                     allocation: nil)
        super

        @dialog_id = dialog_id
        @submit_label = submit_label
        @allocation = allocation
      end

      def wrapper_key
        ResourceAllocations::NewDialogComponent::FOOTER_ID
      end

      def call
        # The flex wrapper lets the destructive Delete action sit at the far left
        # (via `mr: :auto`) while Cancel/Save stay right-aligned.
        component_wrapper(class: "d-flex flex-items-center flex-justify-end width-full") do
          component_collection do |buttons|
            delete_button(buttons) if deletable?

            buttons.with_component(
              Primer::Beta::Button.new(
                data: { "close-dialog-id": @dialog_id },
                mr: 1
              )
            ) { I18n.t(:button_cancel) }

            buttons.with_component(
              Primer::Beta::Button.new(
                scheme: :primary,
                form: ResourceAllocations::NewDialogComponent::FORM_ID,
                type: :submit
              )
            ) { @submit_label }
          end
        end
      end

      private

      def delete_button(buttons)
        buttons.with_component(
          Primer::Beta::Button.new(
            tag: :a,
            href: helpers.project_resource_allocation_path(@allocation.project, @allocation),
            scheme: :danger,
            mr: :auto,
            data: {
              turbo_method: :delete,
              turbo_stream: true,
              turbo_confirm: I18n.t("resource_management.work_package_allocations_dialog.delete_confirmation")
            }
          )
        ) { I18n.t(:button_delete) }
      end

      # The same `:allocate_user_resources` permission that gates editing also
      # gates deletion (see ResourceAllocations::DeleteContract).
      def deletable?
        @allocation&.persisted? &&
          User.current.allowed_in_project?(:allocate_user_resources, @allocation.project)
      end
    end
  end
end
