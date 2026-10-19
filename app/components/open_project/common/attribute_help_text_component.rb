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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module Common
    class AttributeHelpTextComponent < ApplicationComponent
      renders_one :additional_label, lambda { |**system_arguments|
        Primer::Beta::Text.new(**system_arguments)
      }

      def initialize(help_text:, **system_arguments) # rubocop:disable Metrics/AbcSize
        super()

        @help_text = help_text

        @system_arguments = system_arguments
        @system_arguments[:id] ||= self.class.generate_id(help_text)
        @system_arguments[:classes] = class_names(
          @system_arguments[:classes],
          "op-attribute-help-text"
        )
        @system_arguments[:data] ||= {}
        @system_arguments[:data][:controller] = "async-dialog"

        @tooltip = Primer::Alpha::Tooltip.new(
          for_id: @system_arguments[:id],
          type: :label,
          text: I18n.t("js.help_texts.show_modal"),
          direction: :sw
        )
        @system_arguments[:aria] ||= {}
        @system_arguments[:aria][:labelledby] = @tooltip.id
      end

      private

      def render?
        @help_text.present?
      end

      def before_render
        return unless @help_text

        @system_arguments[:href] = show_dialog_attribute_help_text_path(@help_text)
        @system_arguments[:data][:qa_help_text_for] = @help_text.attribute_name.camelize(:lower)
      end
    end
  end
end
