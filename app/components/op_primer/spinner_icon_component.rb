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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpPrimer
  class SpinnerIconComponent < ApplicationComponent
    include Primer::ClassNameHelper

    # taken from Primer::Beta::Spinner which sadly does not expose the paths for use in other components
    # https://github.com/opf/primer_view_components/blob/main/app/components/primer/beta/spinner.html.erb
    PATHS = <<~SVG.html_safe
      <circle cx="8" cy="8" r="7" fill="none" stroke="currentColor" stroke-opacity="0.25" stroke-width="2" vector-effect="non-scaling-stroke"></circle>
      <path d="M15 8a7.002 7.002 0 00-7-7" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" vector-effect="non-scaling-stroke"></path>
    SVG

    # Attributes for embedding PATHS directly into an svg tag rendered by
    # another component, e.g. `Primer::Beta::Button#with_leading_visual_svg`.
    def self.svg_arguments
      {
        viewBox: "0 0 16 16",
        fill: "none",
        "aria-hidden": true,
        classes: "anim-rotate"
      }
    end

    def initialize(size: 16, **system_arguments)
      super()

      @system_arguments = self.class.svg_arguments.merge(system_arguments)
      @system_arguments[:tag] = :svg
      @system_arguments[:height] = "#{size}px"
      @system_arguments[:width] = "#{size}px"
      @system_arguments[:classes] = class_names(self.class.svg_arguments[:classes], system_arguments[:classes])
    end
  end
end
