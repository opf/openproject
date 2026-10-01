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
          # Searches wikis by name, so that a page can be created as a root page of the matching wiki. An
          # internal wiki is named after its project, hence matching a wiki means matching its project's name,
          # e.g. a search for "Demo" matches the wiki of the "Demo project".
          class SearchWikis < BaseQuery
            # A lower limit than for pages, because wikis are containers: a vague query matches a lot of
            # project names and those would otherwise dominate the search results.
            MAXIMUM_RESULTS = 10

            def call(input_data:, auth_strategy:)
              success(
                Wiki.visible(auth_strategy.user)
                    .where("projects.name ILIKE ?", "%#{input_data.query}%")
                    .limit(MAXIMUM_RESULTS)
                    .map { PageHierarchy.wiki_to_adapter_wiki(it, provider:) }
              )
            end
          end
        end
      end
    end
  end
end
