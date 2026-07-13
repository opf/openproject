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

module Admin::Import::Jira::ImportRuns
  class InfoListBoxComponent < Primer::Component
    include OpPrimer::ComponentHelpers

    attr_reader :title, :list, :system_arguments

    def initialize(title:, list:, subtitle: nil, show_icon: true, icon: :"dot-fill", icon_color: :default, **system_arguments)
      super()
      @title = title
      @subtitle = subtitle
      @list = list
      @show_icon = show_icon
      @icon = icon
      @icon_color = icon_color
      @system_arguments = system_arguments
    end

    def call
      render(OpPrimer::InsetBoxComponent.new(border: false, **system_arguments)) do
        flex_layout do |flex|
          flex.with_row(mb: 1) do
            render(Primer::Beta::Text.new(font_weight: :bold)) { title }
          end
          if @subtitle
            flex.with_row(mb: 1) do
              @subtitle
            end
          end
          list.each do |item|
            flex.with_row(mt: 2) do
              render_item(item)
            end
          end
        end
      end
    end

    def render_item(item)
      if @show_icon
        concat(render(Primer::Beta::Octicon.new(icon: @icon, color: @icon_color)))
      end
      if item[:url].present?
        concat(render(Primer::Beta::Link.new(href: item[:url], ml: 1, target: "_blank")) { item[:label] })
      else
        concat(render(Primer::Beta::Text.new(ml: 1)) { item[:label] })
      end
    end
  end
end
