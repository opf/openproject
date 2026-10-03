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
      # Extended representer for a wiki page: exposes text, slug, locked
      # state, hierarchy, version number and related links in addition to
      # the id/title provided by the core representer.
      class WikiPageFullRepresenter < ::API::Decorators::Single
        include API::Decorators::DateProperty
        include API::Decorators::FormattableProperty
        include API::Decorators::LinkedResource
        include API::V3::Workspaces::LinkedResource
        include API::Caching::CachedRepresenter
        include ::API::V3::Attachments::AttachableRepresenterMixin

        cached_representer key_parts: %i(project), disabled: false

        self_link title_getter: ->(*) { represented.title }

        link :update,
             cache_if: -> { current_user.allowed_in_project?(:edit_wiki_pages, represented.project) } do
          {
            href: api_v3_paths.wiki_page(represented.id),
            method: :patch
          }
        end

        link :delete,
             cache_if: -> { current_user.allowed_in_project?(:manage_wiki, represented.project) } do
          {
            href: api_v3_paths.wiki_page(represented.id),
            method: :delete
          }
        end

        link :versions do
          { href: api_v3_paths.wiki_page_versions(represented.id) }
        end

        link :parent do
          next if represented.parent.nil?

          {
            href: api_v3_paths.wiki_page(represented.parent.id),
            title: represented.parent.title
          }
        end

        link :author do
          next if represented.author.nil?

          {
            href: api_v3_paths.user(represented.author_id),
            title: represented.author.name
          }
        end

        property :id
        property :title
        property :slug
        property :protected, as: :locked
        property :lock_version
        property :version, exec_context: :decorator

        formattable_property :text

        date_time_property :created_at
        date_time_property :updated_at

        associated_project

        def _type
          "WikiPage"
        end

        def version
          represented.version
        end
      end
    end
  end
end
