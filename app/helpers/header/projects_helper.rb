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

module Header
  module ProjectsHelper
    def project_node_label(project, favorited: false)
      parts = [project.name]
      parts << favorite_icon if favorited
      parts << workspace_type_badge(project) if show_workspace_type_badge?(project)

      text = parts.length == 1 ? parts.first : safe_join(parts)
      render(Primer::BaseComponent.new(tag: :span, display: :inline_flex, align_items: :center)) { text }
    end

    private

    def favorite_icon
      render(Primer::Beta::Octicon.new(icon: :"star-fill", size: :small, classes: "op-primer--star-icon", ml: 2))
    end

    def workspace_type_badge(project)
      render(Primer::BaseComponent.new(tag: :span, display: :inline_flex, align_items: :center,
                                       color: :subtle, font_size: :small, ml: 2, classes: "description")) do
        safe_join([
                    render(Primer::Beta::Octicon.new(icon: workspace_icon(project.workspace_type), size: :xsmall, mr: 1)),
                    content_tag(:span, I18n.t(:"label_#{project.workspace_type}"))
                  ])
      end
    end

    def show_workspace_type_badge?(project)
      project.workspace_type.in?(%w[portfolio program])
    end
  end
end
