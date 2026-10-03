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
  class FieldRuleSetsController < ApplicationController
    layout "admin"
    menu_item :field_rule_sets

    before_action :require_admin
    before_action :find_rule_set, only: %i[edit update clone activate deactivate]

    def index
      @rule_sets = FieldRuleSet.order(:name)
      @scheme_counts = FieldRuleSchemeItem.group(:rule_set_id).distinct.count(:scheme_id)
    end

    def new
      @rule_set = FieldRuleSet.new(active: true)
    end

    def edit; end

    def create
      result = ::FieldRules::RuleSetService.create(rule_set_params)
      if result.success?
        redirect_to admin_field_rule_sets_path, notice: t(:notice_successful_create), status: :see_other
      else
        @rule_set = result.result
        flash.now[:error] = result.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def update
      attrs = rule_set_params
      @impact = ::FieldRules::RuleSetService.impact(@rule_set)

      if @impact[:project_count].positive? && params[:confirm] != "1"
        @rule_set_params = permitted_params
        return render :confirm, status: :unprocessable_entity
      end

      result = ::FieldRules::RuleSetService.update(@rule_set, attrs)
      if result.success?
        redirect_to admin_field_rule_sets_path, notice: t(:notice_successful_update), status: :see_other
      else
        flash.now[:error] = result.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def clone
      respond(::FieldRules::RuleSetService.clone(@rule_set), t(:notice_successful_create))
    end

    def activate
      respond(::FieldRules::RuleSetService.activate(@rule_set), t(:notice_successful_update))
    end

    def deactivate
      respond(::FieldRules::RuleSetService.deactivate(@rule_set), t(:notice_successful_update))
    end

    private

    def respond(result, notice)
      if result.success?
        flash[:notice] = notice
      else
        flash[:error] = result.errors.full_messages.to_sentence
      end
      redirect_to admin_field_rule_sets_path, status: :see_other
    end

    def find_rule_set
      @rule_set = FieldRuleSet.find(params[:id])
    end

    def permitted_params
      params.require(:rule_set).permit(:name, :description, rules: {})
    end

    def rule_set_params
      permitted = permitted_params
      rows = (permitted[:rules] || {}).to_h.select { |_, row| row.respond_to?(:key?) }
      rules = rows.filter_map { |key, row| build_rule(key, row) }
      { name: permitted[:name], description: permitted[:description], rules: }
    end

    def build_rule(key, row)
      rule = { field_key: key.to_s,
               hidden: row["hidden"] == "1",
               required: row["required"] == "1",
               read_only: row["read_only"] == "1",
               enforce_on_update: row["enforce_on_update"] == "1",
               default_value: row["default_value"].to_s.strip.presence }
      rule if rule.values_at(:hidden, :required, :read_only, :enforce_on_update, :default_value).any?
    end
  end
end
