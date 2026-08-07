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

module Wikis
  module Adapters
    module Providers
      module Internal
        module Queries
          class SearchPages < BaseQuery
            MAXIMUM_RESULTS = 50

            def call(input_data:, auth_strategy:)
              user = auth_strategy.user

              success(matching_pages(input_data.query, user) + matching_wikis(input_data.query, user))
            end

            private

            def matching_pages(query, user)
              WikiPage.visible(user)
                      .where("title ILIKE ?", "%#{query}%")
                      .limit(MAXIMUM_RESULTS)
                      .map { PageHierarchy.wiki_page_to_page_hierarchy(it, provider:) }
            end

            # Wikis whose project name matches the query, so that searching for the name of a wiki
            # (e.g. "Demo" finding "Demo project") surfaces the wiki itself, even when none of its pages
            # match. A wiki is named after its project, hence that project is needed for every result.
            def matching_wikis(query, user)
              Wiki.where(enabled: true, project: allowed_projects(query, user))
                  .eager_load(:project)
                  .limit(MAXIMUM_RESULTS)
                  .map { PageHierarchy.wiki_to_adapter_wiki(it, provider:) }
            end

            def allowed_projects(query, user)
              Project.allowed_to(user, :view_wiki_pages).where("projects.name ILIKE ?", "%#{query}%")
            end
          end
        end
      end
    end
  end
end
