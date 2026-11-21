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

module Hotkeys
  class FallbackLinksComponent < ApplicationComponent
    include OpenProject::StaticRouting::UrlHelpers

    def initialize(project:, user:)
      super()
      @project = project
      @user = user
    end

    def new_work_package_path_for_user
      if @project
        if @project.module_enabled?(:work_package_tracking) && @user.allowed_in_project?(:add_work_packages, @project)
          new_project_work_packages_path(@project)
        end
      elsif @user.allowed_in_any_project?(:add_work_packages)
        new_work_package_path
      end
    end

    def wiki_start_path
      return unless @project && Wikis::InternalProvider.enabled?

      wiki = @project.wiki
      return unless wiki&.visible?(@user)

      project_wiki_path(@project, wiki.find_or_new_page(wiki.start_page).slug)
    end

    def new_work_package_key = OpenProject::Hotkeys.for_action(:new_work_package)

    def new_work_package_access_key = OpenProject::AccessKeys.key_for(:new_work_package)

    def shortcuts_help_key = OpenProject::Hotkeys.for_action(:shortcuts_help)

    def wiki_key = OpenProject::Hotkeys::GLOBAL_FALLBACK.fetch(:wikis)
  end
end
