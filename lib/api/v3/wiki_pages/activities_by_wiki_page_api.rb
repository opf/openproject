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
      class ActivitiesByWikiPageAPI < ::API::OpenProjectAPI
        resource :activities do
          after_validation do
            authorize_in_project(:view_wiki_edits, project: @wiki_page.project)
          end

          get do
            journals = @wiki_page.journals.includes(:data, :attachable_journals, :storable_journals)

            ::API::V3::Activities::ActivityCollectionRepresenter.new(
              journals,
              self_link: api_v3_paths.wiki_page_activities(@wiki_page.id),
              current_user:
            )
          end
        end
      end
    end
  end
end
