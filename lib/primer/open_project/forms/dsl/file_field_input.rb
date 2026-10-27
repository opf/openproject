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
      module Dsl
        # :nodoc:
        class FileFieldInput < Primer::Forms::Dsl::Input
          attr_reader :name, :label, :description, :icon, :accept, :preview_url, :preview_class, :preview_data,
                      :filename, :delete_path, :delete_button_arguments, :auto_submit

          def initialize(name:, label:, description: nil, icon: :upload, accept: nil, preview_url: nil,
                         preview_class: nil, preview_data: {}, filename: nil, delete_path: nil, delete_button_arguments: {},
                         auto_submit: false, **system_arguments)
            @name = name
            @label = label
            @description = description
            @icon = icon
            @accept = accept
            @preview_url = preview_url
            @preview_class = preview_class
            @preview_data = preview_data
            @filename = filename
            @delete_path = delete_path
            @delete_button_arguments = delete_button_arguments
            @auto_submit = auto_submit

            super(**system_arguments, visually_hide_label: true)
          end

          def to_component
            FileField.new(input: self)
          end

          # :nocov:
          def type
            :file_field
          end
          # :nocov:

          # :nocov:
          def focusable?
            true
          end
          # :nocov:
        end
      end
    end
  end
end
