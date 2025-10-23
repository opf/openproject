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

module Budgets
  module BudgetItems
    class InlineCostEditComponent < ApplicationComponent
      extend Dry::Initializer
      include Costs::NumberHelper

      CONTROLLER = "costs--budget-inline-cost-edit"

      option :control_id
      option :calculated_id

      option :input_name
      option :input_id

      option :cost_value
      option :override_value, default: -> {}
      option :show_cost, default: -> { true }
      option :label, default: -> { Budget.model_name.human }

      option :hint, default: -> {}
      option :hint_id, default: -> { "#{input_id}_hint" }

      option :cost_currency, default: -> { Setting.costs_currency }
      option :cost_currency_id, default: -> { "#{input_id}_currency" }

      option :button_arguments, default: -> { {} }
      option :edit_button_arguments, default: -> { {} }
      option :cancel_button_arguments, default: -> { {} }

      def initialize(*, **system_arguments) # rubocop:disable Metrics/AbcSize
        super

        @system_arguments = system_arguments.except(*self.class.dry_initializer.definitions.keys)
        @system_arguments[:tag] = :div

        return unless editable?

        @system_arguments[:data] ||= {}
        @system_arguments[:data][:controller] = CONTROLLER
        @system_arguments[:data][:action] = "keydown.esc->#{CONTROLLER}#cancel"
        @system_arguments[:data][:"#{CONTROLLER}-is-editing-value"] = true if overridden?

        @button_arguments[:tooltip_direction] = :sw
        @button_arguments[:classes] = class_names(@system_arguments[:classes], "rounded-right-0", "border-right-0")

        setup_edit_button_arguments
        setup_cancel_button_arguments
      end

      # Without cost visibility nothing is rendered or submitted for the row, so the
      # server leaves a saved override untouched and does not expose its amount.
      def editable? = show_cost

      def overridden? = editable? && !override_value.nil?

      def display_text
        helpers.number_to_currency(cost_value) if editable?
      end

      def calculated_text = unitless_currency_number(cost_value)

      def input_value
        unitless_currency_number(override_value) if overridden?
      end

      def described_by
        [cost_currency_id, (hint_id unless hint.nil?)].compact.join(" ")
      end

      private

      def target(name) = { "#{CONTROLLER}-target": name }

      def setup_edit_button_arguments
        @edit_button_arguments.with_defaults!(@button_arguments)
        @edit_button_arguments[:icon] = :pencil
        @edit_button_arguments[:data] = { **target("editButton"), action: "#{CONTROLLER}#edit" }
        @edit_button_arguments[:aria] = { label: t(:help_click_to_edit) }
        @edit_button_arguments[:hidden] = overridden?
        @edit_button_arguments[:test_selector] = "edit_inline_cost"
      end

      def setup_cancel_button_arguments
        @cancel_button_arguments.with_defaults!(@button_arguments)
        @cancel_button_arguments[:icon] = :x
        @cancel_button_arguments[:data] = { **target("cancelButton"), action: "#{CONTROLLER}#cancel" }
        @cancel_button_arguments[:aria] = { label: t(:button_cancel_edit_budget) }
        @cancel_button_arguments[:hidden] = !overridden?
        @cancel_button_arguments[:test_selector] = "cancel_inline_cost_edit"
      end
    end
  end
end
