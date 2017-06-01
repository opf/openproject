#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module Decorators
    class OffsetPaginatedCollection < ::API::Decorators::Collection
      def self.per_page_default(relation)
        relation.base_class.per_page
      end

      def self.per_page_maximum
        Setting.api_max_page_size.to_i
      end

      def initialize(models, self_link, query: {}, page: nil, per_page: nil, current_user:)
        @self_link_base = self_link
        @query = query
        @page = page || 1
        @per_page = [per_page || self.class.per_page_default(models),
                     self.class.per_page_maximum].min

        full_self_link = make_page_link(page: @page, page_size: @per_page)
        paged = paged_models(models)

        super(paged, models.count, full_self_link, current_user: current_user)
      end

      link :jumpTo do
        {
          href: make_page_link(page: '{offset}', page_size: @per_page),
          templated: true
        }
      end

      link :changeSize do
        {
          href: make_page_link(page: @page, page_size: '{size}'),
          templated: true
        }
      end

      link :previousByOffset do
        {
          href: make_page_link(page: @page - 1, page_size: @per_page)
        } if @page > 1
      end

      link :nextByOffset do
        {
          href: make_page_link(page: @page + 1, page_size: @per_page)
        } if (@page * @per_page) < @total
      end

      property :page_size,
               exec_context: :decorator,
               getter: -> (*) { @per_page }

      property :offset,
               exec_context: :decorator,
               getter: -> (*) { @page }

      private

      def make_page_link(page:, page_size:)
        "#{@self_link_base}?#{href_query(page, page_size)}"
      end

      def href_query(page, page_size)
        @query.merge(offset: page, pageSize: page_size).to_query
      end

      def paged_models(models)
        # FIXME: calling :to_a is a hack to circumvent a counting error in will_paginate
        # see https://github.com/mislav/will_paginate/issues/449
        models.page(@page).per_page(@per_page).to_a
      end
    end
  end
end
