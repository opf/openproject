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
      class NestedApis < ::API::OpenProjectAPI
        resources :wiki_pages do
          after_validation do
            authorize_in_project(:view_wiki_pages, project: @project)
          end

          get do
            ::API::V3::Utilities::ParamsToQuery.collection_response(
              WikiPage.visible(current_user).where(wiki: @project.wiki),
              current_user,
              params.except("id"),
              self_link: api_v3_paths.wiki_pages_by_project(@project.id)
            )
          end
        end
      end
    end
  end
end
