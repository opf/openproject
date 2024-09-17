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
  module Decorators
    class OffsetPaginatedCollection < ::API::Decorators::Collection
      include ::API::Utilities::UrlPropsParsingHelper

      def self.per_page_default(relation)
        relation.base_class.per_page
      end

      def initialize(models, self_link:, current_user:, query_params: {}, page: nil, per_page: nil, groups: nil)
        @self_link_base = self_link
        @query_params = query_params
        @page = page.to_i > 0 ? page.to_i : 1
        resolved_page_size = resolve_page_size(per_page)
        @per_page = resulting_page_size(resolved_page_size, models)

        full_self_link = make_page_link(page: @page, page_size: @per_page)
        paged = paged_models(models)

        super(paged, total_count(models), self_link: full_self_link, current_user:, groups:)
      end

      link :jumpTo do
        {
          href: make_page_link(page: "{offset}", page_size: @per_page),
          templated: true
        }
      end

      link :changeSize do
        {
          href: make_page_link(page: @page, page_size: "{size}"),
          templated: true
        }
      end

      link :previousByOffset do
        next unless @page > 1

        {
          href: make_page_link(page: @page - 1, page_size: @per_page)
        }
      end

      link :nextByOffset do
        next if (@page * @per_page) >= @total

        {
          href: make_page_link(page: @page + 1, page_size: @per_page)
        }
      end

      property :page_size,
               exec_context: :decorator,
               getter: ->(*) { @per_page }

      property :offset,
               exec_context: :decorator,
               getter: ->(*) { @page }

      protected

      def total_count(models)
        models.count(:id)
      end

      private

      def make_page_link(page:, page_size:)
        "#{@self_link_base}?#{href_query(page, page_size)}"
      end

      def href_query(page = @page, page_size = @per_page)
        query_params(page, page_size).to_query
      end

      def query_params(page = @page, page_size = @per_page)
        @query_params.merge(offset: page, pageSize: page_size)
      end

      def paged_models(models)
        if @per_page == 0
          # Optimization. If we are not interested in the model, we can
          # save the round trip to the database.
          models.none
        else
          # Using WillPaginate as we have used it before but avoid the builtin
          # page(@page).per_page(@per_page) way of fetching
          # as it will, on top of fetching the values, also do a count of all elements matching the query
          # which we do not need at this place.
          page_number = ::WillPaginate::PageNumber(@page.nil? ? 1 : @page)
          models
            .offset(page_number.to_offset(@per_page).to_i)
            .limit(@per_page)
        end
      end
    end
  end
end
