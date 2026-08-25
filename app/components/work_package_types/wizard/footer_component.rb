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

module WorkPackageTypes
  module Wizard
    # Wizard footer: progress bar, Back/Cancel and the step's primary action.
    #
    # The primary action always submits the step form, which persists the step and
    # advances. It reads "Finish" on the last step.
    class FooterComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      FORM_IDENTIFIER = "type-wizard-form"

      def initialize(type:, current_step:, variant: nil, back_url: nil)
        super(type)

        @current_step = current_step
        @variant = variant
        @back_url = back_url
      end

      private

      attr_reader :current_step, :variant, :back_url

      def type = model

      def first_step? = current_step == Steps.first

      def last_step? = current_step == Steps.last_for(variant)

      def current_number = Steps.available_for(variant).index(current_step).to_i + 1

      def total_steps = Steps.available_for(variant).size

      def progress_percentage = (current_number.to_f / total_steps * 100).round

      # The last step still submits: it persists its own reuse mode before finishing.
      def primary_action_label
        last_step? ? I18n.t("types.creation_wizard.finish") : I18n.t(:button_continue)
      end

      def back_href
        previous_step = Steps.previous_before(current_step, variant)
        return unless previous_step && record_persisted?

        type_creation_wizard_path(**variant_path_args, step: previous_step, back_url:)
      end

      def variant_path_args = variant&.path_args || { type_id: type.id }

      def record_persisted? = variant ? variant.persisted? : type.persisted?

      # A project has no screen for the type itself, so cancelling there returns to its list.
      def cancel_href
        return back_url if back_url.present?
        return helpers.variant_scope_types_path if helpers.variant_scope_project || !type.persisted?

        edit_type_details_path(type_id: type.id)
      end
    end
  end
end
