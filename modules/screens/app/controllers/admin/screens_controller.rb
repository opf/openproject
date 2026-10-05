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
  class ScreensController < ApplicationController
    MAX_ROWS = 1000

    layout "admin"
    menu_item :screens

    before_action :require_admin
    before_action :find_screen, only: %i[edit update clone activate deactivate]

    def index
      @screens = Screen.order(:name)
      @section_counts = ScreenSection.group(:screen_id).count
      @usage_counts = usage_counts(@screens.map(&:id))
    end

    def new
      @screen = Screen.new(active: true, screen_type: "create")
      load_field_groups
    end

    def edit
      load_field_groups
    end

    def create
      result = ::Screens::ScreenService.create(screen_params(creating: true))
      if result.success?
        redirect_to admin_screens_path, notice: t(:notice_successful_create), status: :see_other
      else
        @screen = result.result
        load_field_groups
        flash.now[:error] = result.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @impact = ::Screens::ScreenService.impact(@screen)

      if @impact[:scheme_count].positive? && params[:confirm] != "1"
        @screen_params = confirmation_params
        return render :confirm, status: :unprocessable_entity
      end

      result = ::Screens::ScreenService.update(@screen, screen_params)
      if result.success?
        redirect_to admin_screens_path, notice: t(:notice_successful_update), status: :see_other
      else
        @screen = result.result
        load_field_groups
        flash.now[:error] = result.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def clone
      respond(::Screens::ScreenService.clone(@screen), t(:notice_successful_create))
    end

    def activate
      respond(::Screens::ScreenService.activate(@screen), t(:notice_successful_update))
    end

    def deactivate
      respond(::Screens::ScreenService.deactivate(@screen), t(:notice_successful_update))
    end

    private

    def respond(result, notice)
      if result.success?
        flash[:notice] = notice
      else
        flash[:error] = result.errors.full_messages.to_sentence
      end
      redirect_to admin_screens_path, status: :see_other
    end

    def find_screen
      @screen = Screen.find(params[:id])
    end

    def load_field_groups
      @native_fields = ::Screens::Fields.native_keys.index_with { |key| ::Screens::Fields.label(key) }
      @custom_fields = WorkPackageCustomField.order(:name).map do |field|
        [field.attribute_name, field.name]
      end.to_h
    end

    def usage_counts(ids)
      counts = Hash.new(0)
      { create_screen_id: :create_screen_id, edit_screen_id: :edit_screen_id,
        view_screen_id: :view_screen_id, transition_screen_id: :transition_screen_id }.each_value do |column|
        ScreenSchemeItem.where(column => ids).group(column).distinct.count(:scheme_id).each do |screen_id, count|
          counts[screen_id] += count
        end
      end
      counts
    end

    def screen_rows
      raw = params.dig(:screen, :sections)
      return unless raw.respond_to?(:each_pair)

      raw.to_unsafe_h.filter_map do |_index, row|
        next unless row.is_a?(Hash)

        { id: row["id"], name: row["name"], position: row["position"], items: item_rows(row["items"]) }
      end.sort_by { |row| row[:position].to_i }
    end

    def item_rows(items)
      return [] unless items.respond_to?(:each_pair)

      items.to_unsafe_h.filter_map do |_index, item|
        next unless item.is_a?(Hash)

        { id: item["id"], field_key: item["field_key"], width: item["width"],
          visible: item["visible"], position: item["position"] }
      end.sort_by { |item| item[:position].to_i }
    end

    def screen_params(creating: false)
      attrs = { name: params.dig(:screen, :name), description: params.dig(:screen, :description) }
      attrs[:screen_type] = params.dig(:screen, :screen_type) if creating
      rows = screen_rows
      attrs[:sections] = rows if rows
      attrs
    end

    def confirmation_params
      { name: params.dig(:screen, :name), description: params.dig(:screen, :description),
        sections: screen_rows }.with_indifferent_access
    end
  end
end
