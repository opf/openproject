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

module AI
  module Assistance
    # The AI Assistance button in the app header, rendered by the view_layouts_base_top_menu
    # hook. The ai-assistance--header-button controller loads MenuButtonComponent for the
    # work package or project in the URL, and hides the button while the menu is empty.
    class HeaderButtonComponent < ApplicationComponent
      def render?
        user = User.current
        user.logged? && OpenProject::FeatureDecisions.ai_assistance_active? && LlmConnection.available? &&
          user.allowed_in_any_project?(:use_ai_assistance)
      end

      def menu_url
        url_helpers.ai_assistance_menu_path
      end
    end
  end
end
