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

module Wikis
  module ProjectSettings
    class WikiController < Projects::SettingsController
      include OpTurbo::ComponentStream
      include OpTurbo::FlashStreamHelper

      menu_item :settings_project_wiki

      def create
        unless new_or_changed_wiki.save
          render_error_flash_message_via_turbo_stream(message: @wiki.errors.full_messages)
        end

        replace_via_turbo_stream(component: ProjectInternalWikiComponent.new(@project.reload))
        respond_with_turbo_streams
      end

      private

      def new_or_changed_wiki
        @wiki = Wiki.find_or_initialize_by(project: @project) { |w| w.start_page = "Wiki" }
        @wiki.enabled = params.require(:value) unless @wiki.new_record?

        @wiki
      end
    end
  end
end
