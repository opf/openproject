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
    module PageLinks
      URN_INLINE_PAGE_LINK = "#{URN_PREFIX}wikiPageLinks:Inline".freeze
      URN_RELATION_PAGE_LINK = "#{URN_PREFIX}wikiPageLinks:Relation".freeze

      URN_PAGE_LINK_TYPE = {
        "Wikis::RelationPageLink" => URN_RELATION_PAGE_LINK,
        "Wikis::InlinePageLink" => URN_INLINE_PAGE_LINK
      }.freeze

      class PageLinkRepresenter < Decorators::Single
        include Decorators::LinkedResource
        include Decorators::DateProperty
        include Caching::CachedRepresenter

        property :id
        property :identifier
        property :wiki_page_link_type, getter: ->(*) { URN_INLINE_PAGE_LINK }

        date_time_property :created_at
        date_time_property :updated_at

        # Title being the identifier is kind of a placeholder until we have actual page names
        self_link(path: :wiki_page_link, title_getter: ->(*) { represented.identifier })

        associated_resource :provider,
                            v3_path: :wiki_provider,
                            link: ->(*) {
                              {
                                href: api_v3_paths.wiki_provider(represented.provider.universal_identifier),
                                title: represented.provider.name
                              }
                            },
                            setter: ->(fragment:, **) { provider_setter(fragment) }

        # TODO: Make this truly polymorphic - @mereghost 2026-04-13
        associated_resource :linkable,
                            v3_path: :work_package,
                            representer: ::API::V3::WorkPackages::WorkPackageRepresenter,
                            skip_render: ->(*) { represented.linkable_id.nil? || represented.linkable_type != "WorkPackage" },
                            setter: ->(fragment:, **) { linkable_setter(fragment) }

        def _type = "WikiPageLink"

        def wiki_page_link_type = URN_PAGE_LINK_TYPE[represented.class.name]

        def wiki_page_link_type=(value)
          represented.type = URN_PAGE_LINK_TYPE.invert[value]
        end

        private

        def linkable_setter(fragment)
          work_package_id = extract_id_from_resource_link(fragment["href"], :linkable, :work_packages)
          represented.linkable = WorkPackage.find_by(id: work_package_id) ||
                                 WorkPackage::InexistentWorkPackage.new(id: work_package_id)
        rescue API::Errors::InvalidResourceLink
          represented.linkable = nil
        end

        def provider_setter(fragment)
          provider_id = extract_id_from_resource_link(fragment["href"], :provider, :wiki_providers)

          represented.provider = Wikis::Provider.find_by(universal_identifier: provider_id) ||
                                 Wikis::InexistentProvider.new(universal_identifier: provider_id)
        rescue API::Errors::InvalidResourceLink
          represented.provider = nil
        end

        def extract_id_from_resource_link(href, property, expected_namespace)
          API::Utilities::ResourceLinkParser.parse_id(href, property:, expected_version: "3", expected_namespace:)
        end

        def user_allowed_to_manage?(model)
          if model.linkable.present?
            current_user.allowed_in_project?(:manage_wiki_page_links, model.linkable.project)
          else
            current_user == model.author
          end
        end
      end
    end
  end
end
