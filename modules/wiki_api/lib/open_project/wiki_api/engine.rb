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

require "open_project/plugins"

module OpenProject
  module WikiAPI
    class Engine < ::Rails::Engine
      engine_name :openproject_wiki_api

      include ::OpenProject::Plugins::ActsAsOpEngine

      register "openproject-wiki_api",
               author_url: "https://www.openproject.org",
               bundled: true do
        # Uses the core wiki permissions (view_wiki_pages, view_wiki_edits,
        # edit_wiki_pages and manage_wiki). No new permissions are introduced.
      end

      add_api_path :wiki_pages_by_project do |project_id|
        "#{project(project_id)}/wiki_pages"
      end

      add_api_path :wiki_pages_tree do |project_id|
        "#{wiki_pages_by_project(project_id)}/tree"
      end

      add_api_path :wiki_pages_search do |project_id|
        "#{wiki_pages_by_project(project_id)}/search"
      end

      add_api_path :wiki_page_versions do |id|
        "#{wiki_page(id)}/versions"
      end

      add_api_path :wiki_page_version do |id, version|
        "#{wiki_page_versions(id)}/#{version}"
      end

      add_api_path :wiki_page_version_restore do |id, version|
        "#{wiki_page_version(id, version)}/restore"
      end

      add_api_path :wiki_page_lock do |id|
        "#{wiki_page(id)}/lock"
      end

      add_api_path :wiki_page_unlock do |id|
        "#{wiki_page(id)}/unlock"
      end

      add_api_path :wiki_page_move do |id|
        "#{wiki_page(id)}/move"
      end

      add_api_path :wiki_page_copy do |id|
        "#{wiki_page(id)}/copy"
      end

      # All new endpoints are provided by a single standalone Grape API mounted
      # under Root. Keeping them separate from the core `wiki_pages_api.rb`
      # avoids conflicts with the `:id` route parameter already declared there.
      add_api_endpoint "API::V3::Root" do
        mount ::API::V3::WikiPagesExt::WikiAPI
      end
    end
  end
end
