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
  class FormComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    DIALOG_ID = "workflow-dialog"
    FORM_ID = "workflow-form"

    def initialize(workflow:, variant: nil)
      super()

      @workflow = workflow
      @variant = variant
    end

    def form_arguments
      {
        id: FORM_ID,
        model: workflow,
        scope: :workflow,
        url: form_url,
        method: workflow.persisted? ? :patch : :post,
        data: { turbo: true }
      }
    end

    private

    attr_reader :workflow, :variant

    def form_url
      return url_helpers.workflow_path(workflow) if workflow.persisted?
      return url_helpers.workflows_path if variant.nil?

      url_helpers.type_workflow_path(**variant.path_args)
    end

    def error_message
      return if workflow.errors.empty?

      workflow.errors.full_messages.to_sentence
    end
  end
end
