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
  class FieldRuleSchemesController < ApplicationController
    MAX_ROWS = 1000

    layout "admin"
    menu_item :field_rule_sets

    before_action :require_admin
    before_action :find_scheme, only: %i[edit update clone activate deactivate]

    def index
      @schemes = FieldRuleScheme.order(:name)
      @item_counts = FieldRuleSchemeItem.group(:scheme_id).count
      @project_counts = ProjectFieldRuleScheme.group(:scheme_id).count
    end

    def new
      @scheme = FieldRuleScheme.new(active: true)
    end

    def edit; end

    def create
      result = ::FieldRules::SchemeService.create(scheme_params)
      if result.success?
        redirect_to admin_field_rule_schemes_path, notice: t(:notice_successful_create), status: :see_other
      else
        @scheme = result.result
        flash.now[:error] = result.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @impact = ::FieldRules::SchemeService.impact(@scheme)

      if @impact[:project_count].positive? && params[:confirm] != "1"
        @scheme_params = confirmation_params
        return render :confirm, status: :unprocessable_entity
      end

      result = ::FieldRules::SchemeService.update(@scheme, scheme_params)
      if result.success?
        redirect_to admin_field_rule_schemes_path, notice: t(:notice_successful_update), status: :see_other
      else
        flash.now[:error] = result.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def clone
      respond(::FieldRules::SchemeService.clone(@scheme), t(:notice_successful_create))
    end

    def activate
      respond(::FieldRules::SchemeService.activate(@scheme), t(:notice_successful_update))
    end

    def deactivate
      respond(::FieldRules::SchemeService.deactivate(@scheme), t(:notice_successful_update))
    end

    private

    def respond(result, notice)
      if result.success?
        flash[:notice] = notice
      else
        flash[:error] = result.errors.full_messages.to_sentence
      end
      redirect_to admin_field_rule_schemes_path, status: :see_other
    end

    def find_scheme
      @scheme = FieldRuleScheme.find(params[:id])
    end

    def permitted_params
      raw = params[:scheme]
      raise ActionController::BadRequest, "scheme must be an object" unless raw.is_a?(ActionController::Parameters)

      raw.permit(:name, :description, types: {})
    end

    def type_rows
      rows = permitted_params[:types]
      return {} unless rows.respond_to?(:to_h)

      rows.to_h.select { |type_id, rule_set_id| type_id.match?(/\A\d{1,9}\z/) && rule_set_id.is_a?(String) }
          .first(MAX_ROWS).to_h
    end

    def confirmation_params
      permitted = permitted_params
      { "name" => permitted[:name].to_s, "description" => permitted[:description].to_s, "types" => type_rows }.with_indifferent_access
    end

    def scheme_params
      permitted = permitted_params
      items = type_rows.filter_map do |type_id, rule_set_id|
        next unless rule_set_id.match?(/\A\d{1,9}\z/)

        { type_id: type_id.to_i, rule_set_id: rule_set_id.to_i }
      end
      { name: permitted[:name], description: permitted[:description], items: }
    end
  end
end
