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

module Budgets
  class Form < ApplicationForm
    form do |f|
      f.text_field(
        name: :subject,
        label: attribute_name(:subject),
        required: true
      )

      f.rich_text_area(
        name: :description,
        label: attribute_name(:description),
        rich_text_options: { resource: }
      )

      f.single_date_picker(
        name: :fixed_date,
        label: attribute_name(:fixed_date),
        leading_visual: { icon: :calendar },
        datepicker_options: {}
      )

      f.text_field(
        name: :base_amount,
        label: attribute_name(:base_amount),
        # size: 12, TODO
        inputmode: :decimal,
        input_width: :small,
        trailing_visual: { text: { text: Setting.costs_currency } }
      )
    end

    private

    def resource
      API::V3::Budgets::BudgetRepresenter
        .create(model, current_user: User.current, embed_links: true)
    end
  end
end
