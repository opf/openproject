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

module API
  module V3
    module WikiPages
      class WikiPageRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        include API::V3::Workspaces::LinkedResource
        include API::Decorators::DateProperty
        include API::Decorators::FormattableProperty
        include API::Caching::CachedRepresenter
        include ::API::V3::Attachments::AttachableRepresenterMixin

        cached_representer key_parts: %i[project author parent]

        self_link title_getter: ->(*) { represented.title }

        link :schema do
          {
            href: api_v3_paths.wiki_page_schema
          }
        end

        link :update,
             cache_if: -> { editable_by_current_user? } do
          {
            href: api_v3_paths.wiki_page_form(represented.id),
            method: :post
          }
        end

        link :updateImmediately,
             cache_if: -> { editable_by_current_user? } do
          {
            href: api_v3_paths.wiki_page(represented.id),
            method: :patch
          }
        end

        link :delete,
             cache_if: -> { deletable_by_current_user? } do
          {
            href: api_v3_paths.wiki_page(represented.id),
            method: :delete
          }
        end

        link :activities,
             cache_if: -> {
               current_user.allowed_in_project?(:view_wiki_edits, represented.project)
             } do
          {
            href: api_v3_paths.wiki_page_activities(represented.id)
          }
        end

        property :id

        property :title

        property :slug

        formattable_property :text

        property :lock_version

        property :version,
                 exec_context: :decorator,
                 writable: false,
                 getter: lambda { |*|
                   # A successful update appends its journal after the endpoint
                   # has already loaded the page. Discard that association's
                   # cached last journal so the mutation response exposes the
                   # newly committed revision rather than the prior one.
                   #
                   # WikiController#show wraps pages in WikiPages::AtVersion,
                   # whose #journals returns an Array (no #reset). Always reset
                   # the underlying ActiveRecord association instead.
                   journaled = if represented.is_a?(::WikiPages::AtVersion)
                                 represented.object
                               else
                                 represented
                               end
                   journaled.association(:journals).reset
                   represented.version
                 }

        property :protected

        date_time_property :created_at
        date_time_property :updated_at

        associated_resource :project,
                            representer: ::API::V3::Projects::ProjectRepresenter,
                            link: ->(*) {
                              associated_resource_default_link(represented.project,
                                                               :itself,
                                                               v3_path: :project,
                                                               skip_link: -> { false },
                                                               title_attribute: :name,
                                                               getter: :id)
                            },
                            setter: ->(fragment:, **) {
                              href = fragment["href"]
                              next if href == API::V3::URN_UNDISCLOSED

                              id = ::API::Utilities::ResourceLinkParser.parse_id(
                                href,
                                property: :project,
                                expected_version: "3",
                                expected_namespace: :projects
                              )
                              project_id = if id.to_i.to_s == id
                                             id.to_i
                                           else
                                             Project.where(identifier: id).pick(:id)
                                           end
                              represented.wiki_id = Wiki.find_by!(project_id:).id
                            }

        associated_resource :author,
                            v3_path: :user,
                            representer: ::API::V3::Users::UserRepresenter

        associated_resource :parent,
                            v3_path: :wiki_page,
                            representer: WikiPageRepresenter

        def self_v3_path(*)
          api_v3_paths.wiki_page(represented.id)
        end

        private

        def editable_by_current_user?
          represented.editable_by?(current_user) &&
            current_user.allowed_in_project?(:edit_wiki_pages, represented.project)
        end

        def deletable_by_current_user?
          current_user.allowed_in_project?(:manage_wiki, represented.project) &&
            represented.editable_by?(current_user)
        end

        public

        def _type
          "WikiPage"
        end
      end
    end
  end
end
