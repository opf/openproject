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

module OpPrimer
  module QuickFilter
    # A multi-select quick filter whose selection lives in a plain array query
    # parameter, for pages that filter without a Queries object.
    class ParamSelectPanelComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(title:, param:, records:, selected:, all_label:, many_label_key:, test_selector: nil)
        super()

        @title = title
        @param = param
        @records = records
        @selected = selected
        @all_label = all_label
        @many_label_key = many_label_key
        @test_selector = test_selector
      end

      private

      attr_reader :title, :param, :records, :selected, :all_label, :many_label_key, :test_selector

      def button_label
        case selected.size
        when 0 then all_label
        when 1 then selected.first.name
        else t(many_label_key, count: selected.size)
        end
      end

      def data_attributes
        {
          controller: "quick-filter--param-select-panel",
          "quick-filter--param-select-panel-param-value": param
        }
      end
    end
  end
end
