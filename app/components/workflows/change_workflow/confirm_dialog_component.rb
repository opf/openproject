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

module Workflows
  module ChangeWorkflow
    class ConfirmDialogComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      DIALOG_ID = "change-workflow-confirm-dialog"

      def initialize(variant:, missing_statuses:, form_arguments:, hidden_fields:, workflow: nil)
        super()

        @variant = variant
        @workflow = workflow
        @missing_statuses = missing_statuses
        @form_arguments = form_arguments
        @hidden_fields = hidden_fields
      end

      private

      attr_reader :variant, :workflow, :missing_statuses, :form_arguments, :hidden_fields

      def description
        return I18n.t("workflows.change.confirm.description_blank", type: variant.composite_name) if workflow.nil?

        key = target_empty? ? "description_empty" : "description"
        I18n.t("workflows.change.confirm.#{key}", name: workflow.name, type: variant.composite_name)
      end

      def target_empty?
        workflow.nil? || workflow.status_transitions.where(role: eligible_roles).none?
      end

      def eligible_roles = Workflows::StatusTransition.eligible_roles
    end
  end
end
