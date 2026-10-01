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
      class RelationPageLinkRepresenter < PageLinkRepresenter
        defaults

        property :wiki_page_link_type, getter: ->(*) { URN_RELATION_PAGE_LINK }

        link :delete, cache_if: ->(*) { user_allowed_to_manage?(represented) } do
          {
            href: api_v3_paths.wiki_page_link(represented.id),
            method: :delete
          }
        end

        associated_resource :user,
                            as: :author,
                            setter: ->(fragment:, **) { fetch_and_set_author(fragment) },
                            link: ::API::V3::Principals::PrincipalRepresenterFactory.create_link_lambda(:author)

        private

        def fetch_and_set_author(fragment)
          if current_user.admin? && Setting.apiv3_write_readonly_attributes?
            author_id = extract_id_from_resource_link(fragment["href"], :author, :users)
            represented.author = User.find_by(id: author_id) || ::Users::InexistentUser.new
          else
            represented.author = current_user
          end
        rescue API::Errors::InvalidResourceLink
          represented.author = nil
        end
      end
    end
  end
end
