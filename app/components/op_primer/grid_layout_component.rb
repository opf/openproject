#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
  class GridLayoutComponent < Primer::Component
    attr_reader :css_class

    def initialize(css_class, **args)
      super

      @css_class = css_class
      @system_arguments = args
      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        css_class
      )
    end

    renders_many :areas, lambda { |area_name, component = ::Primer::BaseComponent, **sysargs, &block|
      styles = [
        "grid-area: #{area_name}",
        sysargs[:justify_self] ? "justify-self: #{sysargs[:justify_self]}" : nil,
      ]
      sysargs[:style] = join_style_arguments(sysargs[:style], *styles)
      sysargs[:classes] = class_names(
        sysargs[:classes],
        "#{css_class}--#{area_name}"
      )

      render(component.new(**sysargs), &block)
    }
  end
end
