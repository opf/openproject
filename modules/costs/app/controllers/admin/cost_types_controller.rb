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

module Admin
  class CostTypesController < ApplicationController
    # Allow only admins here
    before_action :require_admin
    before_action :find_cost_type, only: %i[edit update set_rate destroy restore rates]
    layout "admin"
    menu_item :cost_types

    helper :sort
    include SortHelper

    helper :cost_types
    include CostTypesHelper

    def index # rubocop:disable Metrics/AbcSize
      sort_init "name", "asc"
      sort_columns = { "name" => "#{CostType.table_name}.name",
                       "unit" => "#{CostType.table_name}.unit",
                       "unit_plural" => "#{CostType.table_name}.unit_plural" }
      sort_update sort_columns

      @query = load_query
      @status = @query.find_active_filter(:status).values.first
      @cost_types = @query.results.reorder(sort_clause)

      render action: "index", layout: !request.xhr?
    end

    def new
      @cost_type = CostType.new

      @cost_type.rates.build(valid_from: Time.zone.today) if @cost_type.rates.empty?

      render action: :edit, layout: !request.xhr?
    end

    def edit
      render action: :edit, layout: !request.xhr?
    end

    def rates
      render action: :rates, layout: !request.xhr?
    end

    def create # rubocop:disable Metrics/AbcSize
      @cost_type = CostType.new(permitted_params.cost_type)

      if @cost_type.save
        flash[:notice] = t(:notice_successful_update)
        redirect_back_or_default({ action: "index" })
      else
        @cost_type.rates.build(valid_from: Time.zone.today) if @cost_type.rates.empty?
        render action: :edit, status: :unprocessable_entity, layout: !request.xhr?
      end
    rescue ActiveRecord::StaleObjectError
      # Optimistic locking exception
      flash.now[:error] = t(:notice_locking_conflict)
    end

    def update # rubocop:disable Metrics/AbcSize
      @cost_type.attributes = permitted_params.cost_type

      if @cost_type.save
        flash[:notice] = t(:notice_successful_update)
        redirect_to redirect_target_after_update
      else
        render action: render_action_for_failed_update, status: :unprocessable_entity, layout: !request.xhr?
      end
    rescue ActiveRecord::StaleObjectError
      # Optimistic locking exception
      flash.now[:error] = t(:notice_locking_conflict)
    end

    def destroy
      @cost_type.deleted_at = DateTime.now
      @cost_type.default = false

      if @cost_type.save
        flash[:notice] = t(:notice_successful_lock)

        redirect_back_or_default({ action: "index" }, status: :see_other)
      end
    end

    def restore
      @cost_type.deleted_at = nil
      @cost_type.default = false

      if @cost_type.save
        flash[:notice] = t(:notice_successful_restore)

        redirect_back_or_default({ action: "index" }, status: :see_other)
      end
    end

    def set_rate # rubocop:disable Metrics/AbcSize
      today = Time.zone.today

      rate = @cost_type.rate_at(today)
      rate ||= CostRate.new.tap do |cr|
        cr.cost_type  = @cost_type
        cr.valid_from = today
      end

      rate.rate = CostRate.parse_number_string_to_number(params[:rate])
      if rate.save
        flash[:notice] = t(:notice_successful_update)
      else
        # FIXME: Do some real error handling here
        flash[:error] = t(:notice_something_wrong)
      end
      redirect_to action: "index"
    end

    private

    def load_query
      query = ParamsToQueryService.new(CostType, current_user).call(params)
      query.where("status", "=", ["active"]) unless query.find_active_filter(:status)
      query
    end

    def find_cost_type
      @cost_type = CostType.find(params[:id])
    end

    def rates_submission?
      params.dig(:cost_type, :new_rate_attributes).present? ||
        params.dig(:cost_type, :existing_rate_attributes).present?
    end

    def redirect_target_after_update
      rates_submission? ? rates_admin_cost_type_path(@cost_type) : edit_admin_cost_type_path(@cost_type)
    end

    def render_action_for_failed_update
      rates_submission? ? :rates : :edit
    end
  end
end
