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

module PlaceholderUsers
  class Form < ApplicationForm
    form do |f|
      f.text_field(
        name: :name,
        label: PlaceholderUser.human_attribute_name(:name),
        required: true,
        input_width: :medium,
        autocomplete: "off"
      )

      f.text_area(
        name: :description,
        label: PlaceholderUser.human_attribute_name(:description),
        input_width: :medium
      )

      if criteria?
        f.check_box(
          name: :with_criteria,
          label: I18n.t("placeholder_users.criteria.enable"),
          caption: I18n.t("placeholder_users.criteria.enable_caption"),
          scope_name_to_model: false,
          data: { "show-when-checked-target": "cause", target_name: "with_criteria" }
        ) do |check_box|
          check_box.nested_form(
            classes: ["mt-2", "d-none"],
            data: { "show-when-checked-target": "effect", target_name: "with_criteria" }
          ) do |builder|
            PlaceholderUsers::CriteriaForm.new(builder, submit: false)
          end
        end
      end

      f.submit(
        name: :submit,
        label: submit_label,
        scheme: :primary
      )
    end

    def initialize(submit_label: I18n.t(:button_save), criteria: false)
      super()
      @submit_label = submit_label
      @criteria = criteria
    end

    private

    attr_reader :submit_label

    def criteria? = @criteria
  end
end
