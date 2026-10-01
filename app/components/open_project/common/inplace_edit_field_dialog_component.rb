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
    class InplaceEditFieldDialogComponent < ViewComponent::Base
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      def initialize(model:, attribute:, system_arguments: {})
        super()
        @model = model
        @attribute = attribute
        @system_arguments = system_arguments
      end

      private

      def writable?
        @system_arguments[:writable] == true
      end

      def dialog_title
        @system_arguments[:label] || @model.class.human_attribute_name(@attribute)
      end

      def dialog_id
        model_class = @model.class.name.parameterize(separator: "_")
        "inplace-edit-field-dialog--#{model_class}-#{@model.id}--#{@attribute}"
      end

      def wrapper_id
        "##{dialog_id}"
      end

      def form_id
        "inplace-edit-field-form-#{dialog_id}"
      end

      def edit_component
        OpenProject::Common::InplaceEditFieldComponent.new(
          model: @model,
          attribute: @attribute,
          enforce_edit_mode: true,
          **@system_arguments.merge(
            wrapper_id:,
            form_id:,
            show_action_buttons: false
          )
        )
      end
    end
  end
end
