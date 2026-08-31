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

class WorkPackageHierarchyRelationsController < ApplicationController
  include OpTurbo::ComponentStream

  class InvalidRelationType < StandardError; end

  before_action :set_work_package
  before_action :authorize # Short-circuit early if not authorized

  rescue_from InvalidRelationType do |error|
    render_error(message: error.message, status: 422)
  end

  def new
    component = WorkPackageRelationsTab::AddWorkPackageHierarchyDialogComponent
      .new(work_package: @work_package, relation_type:)
    respond_with_dialog(component)
  end

  def create
    service_result = create_hierarchy_association

    if service_result.failure?
      update_via_turbo_stream(
        component: WorkPackageRelationsTab::AddWorkPackageHierarchyFormComponent.new(
          work_package: @work_package,
          relation_type:,
          related: related_work_package,
          base_errors: extract_base_errors(service_result.errors)
        ),
        status: :bad_request
      )
    end

    respond_with_relations_tab_update(service_result, relation_to_scroll_to: service_result.result)
  end

  def destroy
    related = WorkPackage.visible.find(params[:id])
    service_result =
      if related.parent_id == @work_package.id
        set_relation(child: related, parent: nil)
      elsif @work_package.parent_id == related.id
        set_relation(child: @work_package, parent: nil)
      end
    respond_with_relations_tab_update(service_result)
  end

  private

  def create_hierarchy_association
    if related_work_package.id.blank?
      related_work_package.errors.add(:id, :blank)
      return ServiceResult.failure(result: related_work_package)
    end

    if relation_type == "child"
      set_relation(parent: @work_package, child: related_work_package)
    else
      set_relation(child: @work_package, parent: related_work_package)
    end
  end

  def relation_type
    type = params[:relation_type]
    raise InvalidRelationType, "Missing relation_type parameter" if type.blank?
    raise InvalidRelationType, "Invalid relation type: #{type}" unless type.in?([Relation::TYPE_PARENT, Relation::TYPE_CHILD])

    type
  end

  def related_work_package
    @related_work_package ||=
      if params[:work_package][:id].present?
        WorkPackage.visible.find(params[:work_package][:id])
      else
        WorkPackage.new
      end
  end

  def set_relation(child:, parent:)
    if allowed_to_set_parent?(child)
      WorkPackages::UpdateService.new(
        user: current_user,
        model: child,
        contract_class: WorkPackages::UpdateParentContract
      ).call(parent:)
    else
      child.errors.add(:id, :cannot_add_child_because_of_lack_of_permission)
      ServiceResult.failure(result: child)
    end
  end

  def allowed_to_set_parent?(child)
    WorkPackages::UpdateContract.update_parent_allowed?(work_package: child, user: current_user)
  end

  def respond_with_relations_tab_update(service_result, **)
    if service_result.success?
      @work_package.reload
      component = WorkPackageRelationsTab::IndexComponent.new(work_package: @work_package, **)
      replace_via_turbo_stream(component:)
      render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_update))

      respond_with_turbo_streams
    else
      respond_with_turbo_streams(status: :unprocessable_entity)
    end
  end

  def set_work_package
    @work_package = WorkPackage.visible.find(params[:work_package_id])
    @project = @work_package.project
  end

  def extract_base_errors(errors)
    if errors[:base].present?
      errors[:base]
    elsif errors[:id].present?
      nil
    else
      errors.full_messages
    end
  end
end
