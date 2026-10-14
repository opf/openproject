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

module Planner
  # Shared by the Planner views, which refresh themselves via Turbo Streams. A view keeps the "Add
  # to-do" form of the group named by `adding` open, so that to-dos can be added one after another.
  class BaseComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    DRAG_TYPE = "todo"

    def initialize(model, adding: nil, filter: View::FILTERS.first)
      super(model)
      @adding = adding
      @filter = filter
    end

    attr_reader :filter

    # The date and day part the "Add to-do" dialog starts with, if the view takes to-dos.
    def add_todo_defaults = nil

    private

    attr_reader :adding

    def todos_shown? = filter != "meetings"

    def meetings_shown? = filter != "todos"

    def shown_meetings(group) = meetings_shown? ? group.meetings : []

    def shown_work_packages(group) = todos_shown? ? group.work_packages : []

    def adding?(group) = adding.to_s == group.to_s

    # Today and Upcoming are sortable lists: dropping a to-do on another day part or day plans it there.
    def sortable_root_data(view)
      {
        controller: "sortable-lists",
        sortable_lists_move_url_templates_value: { DRAG_TYPE => drop_url_template(view) }.to_json,
        sortable_lists_sortable_lists__list_outlet: "##{wrapper_key} [data-controller~='sortable-lists--list']",
        sortable_lists_sortable_lists__item_outlet: "##{wrapper_key} [data-controller~='sortable-lists--item']"
      }
    end

    def sortable_list_data(id, name)
      {
        controller: "sortable-lists--list",
        sortable_lists__list_type_value: DRAG_TYPE,
        sortable_lists__list_accepted_type_value: DRAG_TYPE,
        sortable_lists__list_id_value: id,
        sortable_lists__list_name_value: name
      }
    end

    def sortable_item_data(work_package)
      {
        controller: "sortable-lists--item",
        sortable_lists__item_id_value: work_package.id,
        sortable_lists__item_type_value: DRAG_TYPE,
        sortable_lists__item_label_value: work_package.subject
      }
    end

    # Built with a sentinel so that relative URL roots are kept; the controller expands {id}.
    def drop_url_template(view)
      drop_planner_task_path("__id__", view: Views.param(view)).sub("__id__", "{id}")
    end

    def weekday_and_day(date) = "#{I18n.l(date, format: '%A')} #{date.day.ordinalize}"

    def counts(group)
      meetings = shown_meetings(group)
      work_packages = shown_work_packages(group)
      return t("planner.no_entries") if meetings.empty? && work_packages.empty?

      [
        (t("planner.todos", count: work_packages.size) if work_packages.any?),
        (t("planner.meetings", count: meetings.size) if meetings.any?)
      ].compact.join(" | ")
    end
  end
end
