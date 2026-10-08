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

module API
  module V3
    module WikiPagesExt
      # Shared Grape helpers for the wiki API endpoints.
      module WikiHelpers
        extend Grape::API::Helpers

        # Returns the project's wiki instance or raises `NotFound` when the
        # wiki module is not enabled for the project.
        def ensure_wiki!(project)
          wiki = project.wiki
          if wiki.nil?
            raise ::API::Errors::NotFound.new(
              I18n.t("wiki.errors.not_enabled",
                     default: "Wiki module is not enabled for this project")
            )
          end

          wiki
        end

        # Parses the request body as JSON and returns the raw hash. Raises
        # `InvalidRequestBody` if the body is not valid JSON.
        def parse_json_body(req)
          raw = req.body.read
          return {} if raw.blank?

          JSON.parse(raw)
        rescue JSON::ParserError
          raise ::API::Errors::InvalidRequestBody, "Body must be valid JSON"
        end

        # Parses the request body and maps it to attributes accepted by the
        # `WikiPages::*Service` classes. Supports both a flat JSON payload:
        #
        #   { "title": "...", "text": { "raw": "..." },
        #     "parentTitle": "...", "locked": true, "lockVersion": 3 }
        #
        # and the HAL form using `_links.parent`.
        def parse_wiki_page_body(req)
          json = parse_json_body(req)

          attrs = {}
          attrs[:title]        = json["title"] if json.key?("title")
          attrs[:text]         = json.dig("text", "raw") || json["text"] if json.key?("text")
          attrs[:protected]    = json["locked"] if json.key?("locked")
          attrs[:lock_version] = json["lockVersion"] if json.key?("lockVersion")

          parent_title = json["parentTitle"] || parent_title_from_links(json)
          attrs[:parent_title] = parent_title if parent_title

          attrs
        end

        # Extracts the parent wiki page title from a HAL link:
        # `_links.parent.href = "/api/v3/wiki_pages/123"`.
        def parent_title_from_links(json)
          href = json.dig("_links", "parent", "href")
          return nil if href.blank?

          id = href.to_s.split("/").last.to_i
          return nil if id.zero?

          WikiPage.find_by(id:)&.title
        end

        # Turns a flat list of pages into a hierarchical tree.
        def build_tree(pages)
          by_parent = pages.group_by(&:parent_id)

          render_children = ->(parent_id) do
            (by_parent[parent_id] || []).map do |page|
              {
                _type: "WikiPage",
                id: page.id,
                title: page.title,
                slug: page.slug,
                _links: {
                  self: {
                    href: ::API::V3::Utilities::PathHelper::ApiV3Path.wiki_page(page.id),
                    title: page.title
                  }
                },
                children: render_children.call(page.id)
              }
            end
          end

          render_children.call(nil)
        end
      end
    end
  end
end
