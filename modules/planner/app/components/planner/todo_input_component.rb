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
  # The input row a group shows while to-dos are added to it, with the group's task fields, such as
  # its day part or date. It stays after adding, so that to-dos can be added one after another.
  class TodoInputComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(group:, view:, task_fields: {})
      super()
      @group = group
      @view = view
      @task_fields = task_fields
    end

    private

    attr_reader :group, :view, :task_fields

    def view_param = Views.param(view)

    def handle_space? = Views.sortable?(view)

    def cancel_path = Views.path_for(view)

    def subject_field_arguments
      {
        name: "task[subject]",
        label: t("planner.quick_add.label"),
        visually_hide_label: true,
        placeholder: t("planner.task_form.placeholder"),
        required: true,
        autocomplete: "off",
        autofocus: true,
        full_width: true
      }
    end
  end
end
