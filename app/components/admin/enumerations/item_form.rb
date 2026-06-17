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

module Admin
  module Enumerations
    class ItemForm < ApplicationForm
      delegate :object, to: :@builder

      form do |form|
        form.text_field(
          name: :name,
          label: object.class.human_attribute_name(:name),
          required: true,
          input_width: :medium
        )

        if object.colored?
          form.color_select_list(
            label: attribute_name(:color_id),
            name: :color_id,
            caption: object.color_label,
            input_width: :medium
          )
        end

        form.check_box(
          name: :active,
          label: object.class.human_attribute_name(:active),
          disabled: object.is_default,
          data: { "admin--enumerations-target": "active" }
        )

        if object.class.can_have_default_value?
          form.check_box(
            name: :is_default,
            label: I18n.t(:label_default),
            caption: I18n.t(:enumeration_default_value_caption,
                            model: object.class.model_name.human.downcase),
            data: { action: "admin--enumerations#lockstepActive",
                    "admin--enumerations-target": "default" }
          )
        end

        form.submit(
          name: :submit,
          label: I18n.t(:button_save),
          scheme: :primary
        )
      end
    end
  end
end
