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

module OpPrimer
  class InsetBoxComponent < Primer::Component
    DEFAULT_SCHEME = :default
    SCHEME_MAPPINGS = {
      DEFAULT_SCHEME => { bg: :inset },
      info: { bg: :accent, border_color: :accent },
      warning: { bg: :attention, border_color: :attention },
      danger: { bg: :danger, border_color: :danger },
      success: { bg: :success, border_color: :success }
    }.freeze

    attr_reader :border, :scheme_arguments, :system_arguments

    renders_one :title_icon, Primer::Beta::Octicon

    renders_one :title, lambda { |tag: :h3, **system_arguments|
      Primer::Beta::Heading.new(tag:, font_size: 5, font_weight: :semibold, **system_arguments)
    }

    renders_many :actions, types: {
      button: lambda { |**system_arguments|
        Primer::Beta::Button.new(**system_arguments)
      },
      menu: lambda { |**system_arguments|
        Primer::Alpha::ActionMenu.new(**system_arguments)
      }
    }

    def initialize(border: true, scheme: DEFAULT_SCHEME, **system_arguments)
      super()
      @border = border
      @scheme_arguments = SCHEME_MAPPINGS[fetch_or_fallback(SCHEME_MAPPINGS.keys, scheme, DEFAULT_SCHEME)]
      @system_arguments = system_arguments
    end
  end
end
