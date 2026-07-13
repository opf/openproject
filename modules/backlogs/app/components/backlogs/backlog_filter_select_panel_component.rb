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

module Backlogs
  class BacklogFilterSelectPanelComponent < ApplicationComponent
    include CommonHelper

    InboxItem = Data.define(:id, :name)

    attr_reader :project, :filter_field

    def initialize(project:, field_name:)
      super()
      @project = project
      @filter_field = field_name.to_sym
    end

    private

    def filter_fields_for
      backlog_filter_params
        .except(filter_field)
        .flat_map do |name, value|
          field_name = value.is_a?(Array) ? "#{name}[]" : name
          Array(value).map { |v| [field_name, v, { id: nil }] }
        end
    end

    def items
      if filter_field == :sprint_ids
        all_sprints_for(project)
      else
        all_buckets_for(project).to_a + [InboxItem.new(id: "inbox", name: I18n.t(:label_inbox))]
      end
    end

    def selected_ids
      backlog_filters.public_send(filter_field)
    end

    def count
      @count ||= selected_ids&.size || 0
    end

    def counter_arguments
      aria = { label: I18n.t(:label_x_items, count:), live: "polite" }

      { count:, hide_if_zero: true, aria: }
    end

    def show_button_arguments
      {
        scheme: :secondary,
        color: selector_color,
        data: { test_selector: "#{filter_field_name}_filter_button" }
      }
    end

    def selector_color
      selected_ids ? :default : :muted
    end

    def filter_field_name
      filter_field == :sprint_ids ? "sprint" : "backlog_bucket"
    end

    def clear_form_id
      "#{filter_field_name}-clear-form"
    end
  end
end
