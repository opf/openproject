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

class CostlogController < ApplicationController
  menu_item :work_packages
  before_action :find_cost_entry_work_package_or_project, :authorize, only: %i[edit new create update destroy]
  before_action :find_associated_objects, only: %i[create update]

  helper :work_packages
  include CostlogHelper

  def new
    unless @project&.cost_types_available?
      flash[:error] = I18n.t("cost_types.errors.no_cost_types_available") # rubocop:disable Rails/ActionControllerFlashBeforeRender
      redirect_back_or_default(@work_package ? polymorphic_path(@work_package) : project_path(@project))
      return
    end

    new_default_cost_entry

    render action: "edit"
  end

  def edit
    render_403 unless @cost_entry.try(:editable_by?, User.current)
  end

  def create
    new_default_cost_entry
    update_cost_entry_from_params

    if !@cost_entry.creatable_by?(User.current)

      render_403

    elsif @cost_entry.save

      flash[:notice] = t(:notice_cost_logged_successfully)
      redirect_back_or_default polymorphic_path(@cost_entry.entity)
    else
      render action: :edit, status: :unprocessable_entity
    end
  end

  def update
    update_cost_entry_from_params

    if !@cost_entry.editable_by?(User.current)

      render_403

    elsif @cost_entry.save

      flash[:notice] = t(:notice_successful_update)
      redirect_back_or_to(polymorphic_path(@cost_entry.entity))

    else
      render action: "edit"
    end
  end

  def destroy
    render_404 and return unless @cost_entry
    render_403 and return unless @cost_entry.editable_by?(User.current)

    @cost_entry.destroy
    flash[:notice] = t(:notice_successful_delete)

    if request.referer.include?("cost_reports")
      redirect_to controller: "/cost_reports", action: :index, status: :see_other
    else
      redirect_back_or_to(polymorphic_path(@cost_entry.entity), status: :see_other)
    end
  end

  private

  def find_cost_entry_work_package_or_project # rubocop:disable Metrics/AbcSize
    if params[:id]
      @cost_entry = CostEntry.visible.find(params[:id])
      @project = @cost_entry.project
    elsif params[:work_package_id]
      @work_package = WorkPackage.visible.find(params[:work_package_id])
      @project = @work_package.project
    elsif params[:project_id]
      @project = Project.visible.find(params[:project_id])
    else
      render_404
    end
  end

  def find_associated_objects # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    user_id = cost_entry_params.delete(:user_id)
    @user = if @cost_entry.present? && @cost_entry.user_id == user_id
              @cost_entry.user
            else
              User.visible.find_by(id: user_id)
            end

    entity_id = cost_entry_params.delete(:entity_id)
    entity_type = cost_entry_params.delete(:entity_type)
    @work_package = if @cost_entry.present? && @cost_entry.entity_type == "WorkPackage" && @cost_entry.entity_id == entity_id
                      @cost_entry.entity
                    elsif entity_type == "WorkPackage"
                      WorkPackage.visible.find_by(id: entity_id)
                    end

    cost_type_id = cost_entry_params.delete(:cost_type_id)
    @cost_type = if @cost_entry.present? && @cost_entry.cost_type_id == cost_type_id
                   @cost_entry.cost_type
                 else
                   CostType.find_by(id: cost_type_id)
                 end
  end

  def new_default_cost_entry
    @cost_entry = CostEntry.new.tap do |ce|
      ce.project = @project
      ce.entity = @work_package
      ce.user = User.current
      ce.spent_on = Time.zone.today
      ce.cost_type = CostType.default_for_project(@project) if @project
    end
  end

  def update_cost_entry_from_params
    @cost_entry.user = @user
    @cost_entry.entity = @work_package
    @cost_entry.cost_type = @cost_type

    attributes = permitted_params.cost_entry
    attributes[:units] = Rate.parse_number_string_to_number(attributes[:units])

    if attributes[:overridden_costs].present?
      attributes[:overridden_costs] = Rate.parse_number_string_to_number(attributes[:overridden_costs])
    end

    @cost_entry.attributes = attributes
  end

  def cost_entry_params
    params.expect(cost_entry: %i[user_id entity_id entity_type spent_on cost_type_id units comments])
  end
end
