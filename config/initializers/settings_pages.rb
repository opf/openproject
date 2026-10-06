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

require Rails.root.join("config/constants/settings/pages")

Settings::Pages.draw do
  page :general, menu_item: :settings_general, view_hook: :view_settings_general_form do
    setting :app_title, input_width: :medium
    setting :organization_name, input_width: :medium
    setting :per_page_options, input_width: :medium
    setting :activity_days_default, input_width: :xsmall
    setting :host_name, input_width: :medium
    setting :cache_formatted_text
    setting :allowed_link_protocols, input_width: :medium, rows: 5
    setting :feeds_enabled
    setting :feeds_limit, input_width: :xsmall
    setting :file_max_size_displayed, input_width: :xsmall
    setting :diff_max_lines_displayed, input_width: :xsmall
    setting :security_badge_displayed, if: -> { OpenProject::Configuration.security_badge_displayed? }

    section :welcome, heading: :setting_welcome_text do
      setting :welcome_title, input_width: :medium
      setting :welcome_text, cols: 60, rows: 5, id: "settings_welcome_text", rich_text_options: {}
      setting :welcome_on_homescreen
    end
  end

  page :external_links,
       menu_item: :settings_external_links,
       enterprise_feature: :capture_external_links,
       form_hook: :component_admin_settings_external_redirect do
    setting :capture_external_links
    setting :capture_external_links_require_login
  end
end
