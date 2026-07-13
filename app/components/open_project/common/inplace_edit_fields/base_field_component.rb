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

module OpenProject
  module Common
    module InplaceEditFields
      class BaseFieldComponent < ViewComponent::Base
        include Primer::AttributesHelper

        attr_reader :form, :attribute, :model, :show_action_buttons

        def self.display_class
          DisplayFields::DisplayFieldComponent
        end

        def self.open_in_dialog?
          false
        end

        def initialize(form:, attribute:, model:, show_action_buttons: true, **system_arguments)
          super()
          @form = form
          @attribute = attribute
          @model = model
          @show_action_buttons = show_action_buttons
          @system_arguments = system_arguments
        end

        def comment_field_if_enabled(form)
          return unless show_comment_field?

          form.text_area(name: "#{model.class.model_name.param_key}[custom_comments][#{custom_field.id}]",
                         scope_name_to_model: false,
                         label: I18n.t("attributes.comment"),
                         value: model.custom_comment_for(custom_field)&.text,
                         rows: 5)
        end

        def show_comment_field?
          custom_field? && custom_field&.has_comment?
        end

        def custom_field?
          attribute.to_s.start_with?("custom_field_")
        end

        def custom_field
          return @custom_field if defined?(@custom_field)

          @custom_field = CustomField.find_by(id: attribute.to_s.sub("custom_field_", "").to_i)
        end

        def test_selector
          if custom_field?
            "custom-field-#{custom_field.id}"
          end
        end
      end
    end
  end
end
