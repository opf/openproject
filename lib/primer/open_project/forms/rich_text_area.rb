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

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class RichTextArea < Primer::Forms::BaseComponent
        include AngularHelper

        delegate :builder, :form, to: :@input

        def initialize(input:, rich_text_options:, wrapper_data_attributes: {}, wrapper_classes: nil)
          super()
          @input = input
          @wrapper_data_attributes = wrapper_data_attributes
          @wrapper_classes = wrapper_classes
          @rich_text_data = rich_text_options.delete(:data) { {} }
          @rich_text_data[:"test-selector"] ||= "augmented-text-area-#{@input.name}"
          @rich_text_options = rich_text_options
          @text_area_id =
            if @input.id
              [builder.options[:namespace], @input.id].compact.join("_")
            else
              builder.field_id(@input.name)
            end
        end
      end
    end
  end
end
