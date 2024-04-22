#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module OpTurbo
  module OpPrimer
    class AsyncDialogComponent < ApplicationComponent
      include ApplicationHelper
      include ::OpPrimer::ComponentHelpers

      def initialize(id:, src:, title:, size: :auto, header_variant: :medium,
                     hide_button: false, button_icon: nil, button_icon_label: nil, button_text: nil, button_attributes: {})
        super

        @id = id
        @src = src
        @title = title
        @header_variant = header_variant
        @size = size
        @hide_button = hide_button
        @button_icon = button_icon
        @button_icon_label = button_icon_label
        @button_text = button_text
        @button_attributes = button_attributes
      end

      private

      def stimulus_attributes
        {
          controller: 'op-turbo-op-primer-async-dialog',
          'application-target': 'dynamic'
        }
      end

      def merged_text_button_attributes
        stimuls_action_ref = 'click->op-turbo-op-primer-async-dialog#reinitFrame'

        @button_attributes[:data] = {} if @button_attributes[:data].nil?
        @button_attributes[:data][:action] = stimuls_action_ref

        @button_attributes
      end

      def merged_icon_button_attributes
        merged_text_button_attributes.merge(
          icon: @button_icon, 'aria-label': @button_icon_label
        )
      end
    end
  end
end
