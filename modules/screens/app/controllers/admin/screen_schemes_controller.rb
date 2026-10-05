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
# frozen_string_literal: true

module Admin
  class ScreenSchemesController < ApplicationController
    MAX_ROWS = 1000

    layout "admin"
    menu_item :screens

    before_action :require_admin
    before_action :find_scheme, only: %i[edit update clone activate deactivate]

    def index
      @schemes = ScreenScheme.order(:name)
      @item_counts = ScreenSchemeItem.group(:scheme_id).count
      @project_counts = ProjectScreenScheme.group(:scheme_id).count
    end

    def new
      @scheme = ScreenScheme.new(active: true)
      load_screens
    end

    def edit
      load_screens
    end

    def create
      result = ::Screens::SchemeService.create(scheme_params)
      if result.success?
        redirect_to admin_screen_schemes_path, notice: t(:notice_successful_create), status: :see_other
      else
        @scheme = result.result
        load_screens
        flash.now[:error] = result.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @impact = ::Screens::SchemeService.impact(@scheme)

      if @impact[:project_count].positive? && params[:confirm] != "1"
        @scheme_params = confirmation_params
        return render :confirm, status: :unprocessable_entity
      end

      result = ::Screens::SchemeService.update(@scheme, scheme_params)
      if result.success?
        redirect_to admin_screen_schemes_path, notice: t(:notice_successful_update), status: :see_other
      else
        @scheme = result.result
        load_screens
        flash.now[:error] = result.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def clone
      respond(::Screens::SchemeService.clone(@scheme), t(:notice_successful_create))
    end

    def activate
      respond(::Screens::SchemeService.activate(@scheme), t(:notice_successful_update))
    end

    def deactivate
      respond(::Screens::SchemeService.deactivate(@scheme), t(:notice_successful_update))
    end

    private

    def respond(result, notice)
      if result.success?
        flash[:notice] = notice
      else
        flash[:error] = result.errors.full_messages.to_sentence
      end
      redirect_to admin_screen_schemes_path, status: :see_other
    end

    def find_scheme
      @scheme = ScreenScheme.includes(:items).find(params[:id])
    end

    def load_screens
      @screens_by_type = Screen.order(:name).group_by(&:screen_type)
    end

    def scheme_rows
      raw = params.dig(:scheme, :types)
      return unless raw.respond_to?(:each_pair)

      raw.to_unsafe_h.filter_map do |type_id, row|
        next unless row.is_a?(Hash)
        next unless type_id.to_s.match?(/\A\d{1,9}\z/)

        { type_id: type_id.to_i,
          create_screen_id: row["create_screen_id"].presence,
          edit_screen_id: row["edit_screen_id"].presence,
          view_screen_id: row["view_screen_id"].presence,
          transition_screen_id: row["transition_screen_id"].presence }
      end.first(MAX_ROWS)
    end

    def scheme_params
      rows = scheme_rows
      attrs = { name: params.dig(:scheme, :name), description: params.dig(:scheme, :description) }
      attrs[:items] = rows if rows
      attrs
    end

    def confirmation_params
      { name: params.dig(:scheme, :name), description: params.dig(:scheme, :description),
        types: params.dig(:scheme, :types) }.with_indifferent_access
    end
  end
end
