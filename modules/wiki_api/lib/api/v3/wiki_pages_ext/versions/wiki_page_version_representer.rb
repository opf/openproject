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
      module Versions
        class WikiPageVersionRepresenter < ::API::Decorators::Single
          include API::Decorators::DateProperty
          include API::Decorators::FormattableProperty
          include API::Decorators::LinkedResource
          include API::Caching::CachedRepresenter

          cached_representer disabled: true

          def initialize(model, current_user:, page: nil, **opts)
            @page = page || WikiPage.find(model.journable_id)
            super(model, current_user:, **opts)
          end

          link :self do
            { href: api_v3_paths.wiki_page_version(@page.id, represented.version) }
          end

          link :wikiPage do
            { href: api_v3_paths.wiki_page(@page.id), title: @page.title }
          end

          link :author do
            next if represented.user_id.nil?

            { href: api_v3_paths.user(represented.user_id) }
          end

          link :restore,
               cache_if: -> { current_user.allowed_in_project?(:edit_wiki_pages, @page.project) } do
            {
              href: api_v3_paths.wiki_page_version_restore(@page.id, represented.version),
              method: :post
            }
          end

          property :id
          property :version
          property :notes

          formattable_property :text,
                               getter: ->(*) {
                                 ::API::Decorators::Formattable.new(represented.data&.text.to_s,
                                                                    object: represented)
                               },
                               exec_context: :decorator

          date_time_property :created_at

          def _type
            "WikiPageVersion"
          end
        end
      end
    end
  end
end
