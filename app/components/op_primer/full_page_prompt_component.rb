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

module OpPrimer
  class FullPagePromptComponent < Primer::Component
    attr_reader :system_arguments

    renders_one :icon, lambda { |icon:, size: :medium, **system_arguments|
      Primer::Beta::Octicon.new(icon:, size:, **system_arguments)
    }

    renders_one :title, lambda { |tag: :h2, **system_arguments|
      Primer::Beta::Heading.new(tag:, mb: 2, font_size: 5, **system_arguments)
    }

    renders_one :action, types: {
      button: lambda { |**system_arguments|
        system_arguments[:classes] = class_names(
          system_arguments[:classes],
          "op-full-page-prompt--action"
        )
        Primer::Beta::Button.new(**system_arguments)
      }
    }

    def initialize(**system_arguments)
      super()

      @system_arguments = system_arguments
    end
  end
end
