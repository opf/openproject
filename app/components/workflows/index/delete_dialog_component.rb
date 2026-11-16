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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Workflows
  module Index
    class DeleteDialogComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      DIALOG_ID = "workflow-deletion-dialog"

      def initialize(workflow:, url:, validation_message: nil)
        super()

        @workflow = workflow
        @url = url
        @validation_message = validation_message
      end

      private

      attr_reader :workflow, :url, :validation_message

      def title = t("workflows.delete.title", name: workflow.name)

      def variant_names
        @variant_names ||= workflow.type_variants.includes(:type).in_display_order.map(&:composite_name)
      end

      def candidates = workflow.replacement_targets
    end
  end
end
