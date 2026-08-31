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

module Admin
  module CostTypes
    class DetailsForm < ApplicationForm
      form do |f|
        f.text_field(
          name: :name,
          label: ::CostType.human_attribute_name(:name),
          required: true,
          input_width: :large
        )

        f.text_field(
          name: :unit,
          label: ::CostType.human_attribute_name(:unit),
          required: true,
          input_width: :medium
        )

        f.text_field(
          name: :unit_plural,
          label: ::CostType.human_attribute_name(:unit_plural),
          required: true,
          input_width: :medium
        )

        if model.new_record?
          f.text_field(
            name: :current_rate,
            label: ::CostType.human_attribute_name(:current_rate),
            input_width: :small,
            inputmode: :decimal,
            trailing_visual: { text: { text: Setting.costs_currency } }
          )
        end

        f.check_box(
          name: :default,
          label: ::CostType.human_attribute_name(:default)
        )

        f.check_box(
          name: :for_all_projects,
          label: ::CostType.human_attribute_name(:for_all_projects)
        )
      end
    end
  end
end
