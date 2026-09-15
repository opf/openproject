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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module HourlyRates
  class TableComponent < OpPrimer::BorderBoxTableComponent
    options current_rate: nil,
            new_rate_url: nil

    columns :valid_from, :rate, :current
    main_column :valid_from
    mobile_labels :rate, :current

    def row_class
      ::HourlyRates::RowComponent
    end

    def mobile_title
      t(:caption_rate_history)
    end

    def headers
      [
        [:valid_from, { caption: Rate.human_attribute_name(:valid_from) }],
        [:rate, { caption: Rate.model_name.human }],
        [:current, { caption: Rate.human_attribute_name(:current_rate) }]
      ]
    end

    def blank_title
      t(:no_results_title_text)
    end

    # Creating and editing are gated by the same contract check, so the caller
    # passing a url to create with is also what enables the row edit buttons.
    def manageable?
      new_rate_url.present?
    end

    def has_actions?
      manageable?
    end

    def action_row_header_content
      return if new_rate_url.blank?

      render(Primer::Beta::IconButton.new(
               icon: "plus",
               scheme: :invisible,
               size: :small,
               tag: :a,
               href: new_rate_url,
               data: { controller: "async-dialog" },
               test_selector: "add-rate-button",
               label: t(:button_add_rate),
               aria: { label: t(:button_add_rate) }
             ))
    end
  end
end
