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

module ResourcePlannerViews::UserCardList
  # Modelled on Users::HoverCardComponent
  class CardComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include ResourceAllocations::ScheduleSummary

    MULTI_VALUE_DISPLAY_LIMIT = 3

    CardFieldRow = Data.define(:icon, :label, :value, :multi_value)

    def initialize(user:, details_path:, card_fields: [], remove_path: nil, utilization: nil, working_schedules: [])
      super

      @user = user
      @details_path = details_path
      @card_fields = card_fields
      @remove_path = remove_path
      @utilization = utilization
      @working_schedules = working_schedules
    end

    def render?
      @user&.visible?(User.current)
    end

    def status_label
      helpers.full_user_status(@user)
    end

    def status_scheme
      @user.active? ? :success : :attention
    end

    def job_title
      return unless (custom_field = UserCustomField.for_semantic_key(:job_title))

      @user.formatted_custom_value_for(custom_field).presence
    end

    def utilization?
      !@utilization.nil?
    end

    def utilization_label
      helpers.number_to_percentage(@utilization, precision: 0)
    end

    def working_hours_summary
      return t("resource_management.user_card_list.working_hours.blank") if @working_schedules.blank?

      schedule_sentence(@working_schedules, compact: true)
    end

    def card_field_rows
      @card_fields.filter_map { |id| card_field_row(id) }
    end

    private

    def card_field_row(id)
      case id
      when "department"
        department_row
      when "working_times"
        CardFieldRow.new(icon: :clock, label: nil, value: working_hours_summary, multi_value: false)
      else
        custom_field_row(id)
      end
    end

    def department_row
      name = @user.department&.name
      return if name.blank?

      CardFieldRow.new(icon: :briefcase, label: nil, value: name, multi_value: false)
    end

    def custom_field_row(id)
      custom_field = custom_fields_by_column_name[id]
      return if custom_field.nil?
      return unless filled_custom_field_ids.include?(custom_field.id)

      CardFieldRow.new(
        icon: nil,
        label: custom_field.name,
        value: @user.formatted_custom_value_for(custom_field),
        multi_value: custom_field.multi_value?
      )
    end

    def custom_fields_by_column_name
      @custom_fields_by_column_name ||= UserCustomField.visible(User.current).index_by(&:column_name)
    end

    def filled_custom_field_ids
      @filled_custom_field_ids ||= @user.custom_values.where.not(value: [nil, ""]).pluck(:custom_field_id).uniq
    end

    def render_value_labels(value)
      values = Array(value)
      remaining = values.size - MULTI_VALUE_DISPLAY_LIMIT

      labels = values.first(MULTI_VALUE_DISPLAY_LIMIT).map do |item|
        render(Primer::Beta::Label.new(scheme: :accent, mr: 1)) { item }
      end

      if remaining > 0
        labels << render(Primer::Beta::Text.new(font_size: :small, color: :muted)) do
          t("resource_management.user_card_list.card.multi_value_more", count: remaining)
        end
      end

      safe_join(labels, " ")
    end

    def card_options
      {
        classes: "op-user-card",
        test_selector: "op-user-card",
        p: 3,
        border: true,
        border_radius: 2,
        overflow: :hidden,
        data: {
          controller: "resource-management--user-card",
          "resource-management--user-card-url-value": @details_path
        }
      }
    end
  end
end
