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
  # Guided, multi-step creation of a work package sub-type.
  #
  # Deliberately self-contained: it never reuses the tabbed type controllers so
  # the existing tabbed creation/editing flow keeps working unchanged next to it.
  # The sub-type record is created after the first step and each later step
  # persists to that same record (see FND-117).
  class CreationWizardController < ApplicationController
    layout "no_menu"

    before_action :require_admin
    before_action :require_subtypes_feature
    before_action :find_type, only: %i[show update finish]
    before_action :set_current_step, only: %i[show update]

    def show; end

    def new
      @type = Type.new(parent_id: params[:parent_id])
      @current_step = Wizard::Steps.first
      render :show
    end

    def create
      service_call = WorkPackageTypes::CreateService.new(user: current_user).call(details_params)
      @type = service_call.result

      if service_call.success?
        redirect_to_step Wizard::Steps.next_after(Wizard::Steps.first)
      else
        @current_step = Wizard::Steps.first
        render :show, status: :unprocessable_entity
      end
    end

    def update
      case @current_step.key
      when :details
        update_details
      when :workflows
        copy_workflows
      else
        advance
      end
    end

    def finish
      redirect_to types_path, notice: t("types.creation_wizard.success"), status: :see_other
    end

    private

    def update_details
      service_call = WorkPackageTypes::UpdateService
                       .new(user: current_user, model: @type, contract_class: WorkPackageTypes::UpdateSettingsContract)
                       .call(details_params)

      if service_call.success?
        advance
      else
        render :show, status: :unprocessable_entity
      end
    end

    def copy_workflows
      source = ::Type.find_by(id: params.dig(:type, :copy_workflow_from))
      @type.workflows.copy_from_type(source) if source
      advance
    end

    def advance
      redirect_to_step Wizard::Steps.next_after(@current_step)
    end

    def redirect_to_step(step)
      if step
        redirect_to type_creation_wizard_path(@type, step: step.key), status: :see_other
      else
        redirect_to finish_type_creation_wizard_path(@type), status: :see_other
      end
    end

    def find_type
      @type = ::Type.find(params.expect(:type_id))
    end

    def set_current_step
      @current_step = Wizard::Steps.for_key(params[:step]) || Wizard::Steps.first
    end

    def details_params
      params.expect(type: %i[name parent_id description])
    end

    def require_subtypes_feature
      render_404 unless OpenProject::FeatureDecisions.subtypes_active?
    end
  end
end
