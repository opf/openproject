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
  class TypeSchemesController < ApplicationController
    layout "admin"
    menu_item :type_schemes

    before_action :require_admin
    before_action :find_scheme, only: %i[edit update clone deactivate activate]

    def index
      ::TypeSchemes::DefaultScheme.ensure!
      @schemes = TypeScheme.order(:name)
      @project_counts = ProjectTypeScheme.group(:scheme_id).count
    end

    def new
      ::TypeSchemes::DefaultScheme.ensure!
      @scheme = TypeScheme.new(active: true)
    end

    def edit; end

    def create
      result = ::TypeSchemes::SchemeService.create(scheme_params)
      if result.success?
        redirect_to admin_type_schemes_path, notice: t(:notice_successful_create), status: :see_other
      else
        @scheme = result.result
        flash.now[:error] = result.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def update
      attrs = scheme_params
      attrs.delete(:is_default) if @scheme.is_default
      removed = @scheme.items.map(&:type_id) - attrs[:items].pluck(:type_id)
      @impact = ::TypeSchemes::SchemeService.impact(@scheme, removed_type_ids: removed)

      if @impact[:project_count].positive? && params[:confirm] != "1"
        @types = Type.where(id: removed).index_by(&:id)
        @scheme_params = permitted_scheme_params
        return render :confirm
      end

      result = ::TypeSchemes::SchemeService.update(@scheme, attrs)
      if result.success?
        redirect_to admin_type_schemes_path, notice: t(:notice_successful_update), status: :see_other
      else
        flash.now[:error] = result.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def clone
      respond(::TypeSchemes::SchemeService.clone(@scheme), t(:notice_successful_create))
    end

    def deactivate
      respond(::TypeSchemes::SchemeService.deactivate(@scheme), t(:notice_successful_update))
    end

    def activate
      respond(::TypeSchemes::SchemeService.activate(@scheme), t(:notice_successful_update))
    end

    private

    def respond(result, notice)
      if result.success?
        flash[:notice] = notice
      else
        flash[:error] = result.errors.full_messages.to_sentence
      end
      redirect_to admin_type_schemes_path, status: :see_other
    end

    def find_scheme
      @scheme = TypeScheme.includes(items: :color).find(params[:id])
    end

    def bounded_position(value)
      value.is_a?(String) ? value.to_i.clamp(0, 100_000) : 0
    end

    def permitted_scheme_params
      params.require(:type_scheme).permit(:name, :description, :is_default, :default_type_id,
                                          :new_type_names, types: {})
    end

    # Builds the symbol-keyed hash SchemeService expects from the form fields.
    def scheme_params
      permitted = permitted_scheme_params
      default_id = permitted[:default_type_id].to_s
      rows = (permitted[:types] || {}).to_h.select { |_, v| v.respond_to?(:key?) && v["enabled"] == "1" }
      items = rows.map do |type_id, v|
        { type_id: type_id.to_i.clamp(0, 2_147_483_647),
          position: bounded_position(v["position"]),
          is_default: type_id == default_id,
          color_mode: v["color_mode"].presence,
          color_id: v["color_id"].presence,
          color_hex: v["color_hex"].presence }
      end
      { name: permitted[:name], description: permitted[:description],
        is_default: permitted[:is_default] == "1",
        new_type_names: new_type_names_param(permitted),
        items: }
    end

    def new_type_names_param(permitted)
      permitted[:new_type_names].to_s.split(/[\n,]/).map(&:strip).reject(&:blank?)
    end
  end
end
