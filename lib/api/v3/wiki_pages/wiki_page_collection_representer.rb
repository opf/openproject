#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#++

module API
  module V3
    module WikiPages
      class WikiPageCollectionRepresenter < ::API::Decorators::UnpaginatedCollection
        link :createWikiPageImmediately do
          next unless current_user.allowed_in_any_project?(:edit_wiki_pages)

          {
            href: api_v3_paths.wiki_pages,
            method: :post
          }
        end

        link :createWikiPage do
          next unless current_user.allowed_in_any_project?(:edit_wiki_pages)

          {
            href: api_v3_paths.create_wiki_page_form,
            method: :post
          }
        end
      end
    end
  end
end
