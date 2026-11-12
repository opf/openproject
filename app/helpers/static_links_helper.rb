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

module StaticLinksHelper
  ##
  # Create a static link to the given key entry
  # *path - the path segments to look up the link for static links
  # href: - optional override for the href if no static link is found or given
  # label: - optional override for the label if no static link label is found or given
  def static_link_to(*path, href: nil, label: nil, url_params: {}, **system_arguments)
    link = OpenProject::Static::Links.url_for(*path, url_params:) || href
    raise ArgumentError, "No href found for static link #{path.inspect}" if link.nil?

    label_text = label || OpenProject::Static::Links.label_for(*path)

    render(
      Primer::Beta::Link.new(href: link,
                             data: { allow_external_link: true },
                             **system_arguments,
                             rel: "noopener",
                             target: "_blank")
    ) do |link|
      link.with_trailing_visual_icon(icon: "link-external")
      label_text
    end
  end

  ##
  # Link to the correct installation guides for the current selected method
  def installation_guide_link
    val = OpenProject::Configuration.installation_type
    # Try specific installation type first, fallback to general installation guides
    OpenProject::Static::Links.url_for(:"#{val}_installation") || OpenProject::Static::Links.url_for(:installation_guides)
  end
end
