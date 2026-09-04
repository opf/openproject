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

Rails.application.configure do
  next unless OpenProject::Configuration.lookbook_enabled?

  require "factory_bot"
  require "factory_bot_rails"

  # Re-define snapshot to avoid warnings
  YARD::Tags::Library.define_tag("Snapshot preview (unused)", :snapshot)

  # Branding
  config.lookbook.project_name = "OpenProject Lookbook"
  config.lookbook.project_logo = Rails.root.join("app/assets/images/icon_logo_white.svg").read
  config.lookbook.ui_favicon = Rails.root.join("app/assets/images/icon_logo.svg").read
  config.lookbook.ui_theme = "blue"
  config.lookbook.ui_theme_overrides = {
    header_bg: "#1A67A3"
  }

  # Previews: ours, plus the ones shipped by Primer
  config.lookbook.component_paths << Primer::ViewComponents::Engine.root.join("app/components").to_s
  config.view_component.previews.paths += [
    Rails.root.join("lookbook/previews").to_s,
    Primer::ViewComponents::Engine.root.join("previews").to_s
  ]

  # Pages
  config.lookbook.page_paths = [Rails.root.join("lookbook/docs").to_s]
  # Previews ship with a filter box (preview_nav_filter), pages do not
  config.lookbook.page_nav_filter = true

  # Inspector
  # Show pages first, then previews
  config.lookbook.preview_inspector.sidebar_panels = %i[pages previews]
  # Show notes first, all other panels next
  config.lookbook.preview_inspector.drawer_panels = [:notes, "*"]

  # Custom inputs
  Lookbook.add_input_type(:octicon, "lookbook/previews/inputs/octicon")
  Lookbook.add_input_type(:medium_octicon, "lookbook/previews/inputs/medium_octicon")
end
