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

class WorkPackageRelationsController < ApplicationController
  include OpTurbo::ComponentStream
  include OpTurbo::FlashStreamHelper
  include WorkPackageRelationsTab::UpdateResponses

  before_action :set_work_package
  before_action :set_relation, only: %i[edit update]
  before_action :authorize

  def new
    @relation = @work_package.relations.build(
      from: @work_package,
      relation_type: params[:relation_type]
    )

    respond_with_dialog(
      WorkPackageRelationsTab::WorkPackageRelationDialogComponent
        .new(work_package: @work_package, relation: @relation)
    )
  end

  def edit
    contract = Relations::UpdateContract.new(@relation, current_user)

    if contract.valid?
      respond_with_dialog(
        WorkPackageRelationsTab::WorkPackageRelationDialogComponent
          .new(work_package: @work_package, relation: @relation)
      )
    else
      respond_with_flash_error(message: I18n.t(:"activerecord.errors.models.relation.attributes.base.error_not_editable"))
    end
  end

  def create
    service_result = Relations::CreateService.new(user: current_user)
                                             .call(create_relation_params)

    if service_result.failure?
      update_via_turbo_stream(
        component: WorkPackageRelationsTab::WorkPackageRelationFormComponent.new(work_package: @work_package,
                                                                                 relation: service_result.result,
                                                                                 base_errors: service_result.errors[:base]),
        status: :bad_request
      )
    end

    respond_with_relations_tab_update(service_result, relation_to_scroll_to: service_result.result)
  end

  def update
    service_result = Relations::UpdateService
      .new(user: current_user,
           model: @relation)
      .call(update_relation_params)

    respond_with_relations_tab_update(service_result)

    if service_result.failure?
      update_via_turbo_stream(
        component: WorkPackageRelationsTab::WorkPackageRelationFormComponent.new(work_package: @work_package,
                                                                                 relation: service_result.result,
                                                                                 base_errors: service_result.errors[:base]),
        status: :bad_request
      )
    end
  end

  def destroy
    @relation = @work_package.relations.find_by(id: params[:id])
    service_result =
      if @relation
        Relations::DeleteService.new(user: current_user, model: @relation).call
      else
        ServiceResult.success
      end

    if service_result.failure?
      respond_with_flash_error(message: service_result.message)
    else
      respond_with_relations_tab_update(service_result)
    end
  end

  private

  def set_work_package
    @work_package = WorkPackage.visible.find(params[:work_package_id])
  end

  def set_relation
    @relation = @work_package.relations.visible.find(params[:id])
  end

  def create_relation_params
    if params[:relation][:from_id].present?
      params.require(:relation)
            .permit(:relation_type, :from_id, :description, :lag)
            .merge(to_id: @work_package.id)
    else
      params.require(:relation)
            .permit(:relation_type, :to_id, :description, :lag)
            .merge(from_id: @work_package.id)
    end
  end

  def update_relation_params
    params.require(:relation)
          .permit(:description, :lag)
  end
end
