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
    class UnpaginatedCollection < ::API::Decorators::Collection
      def initialize(models, self_link:, current_user:, query: {})
        super(models, model_count(models), self_link: make_self_link(self_link, query), current_user:)
      end

      def model_count(models)
        if models.respond_to?(:except)
          # We do not want any order/selecting with counting
          # when it would result in an invalid SELECT COUNT(DISTINCT *, ).
          # As both, order and select should have no impact on the count result, we remove them.
          models.except(:select, :order)
        else
          models
        end.count
      end

      private

      def make_self_link(self_link_base, query)
        return self_link_base if query.empty?

        "#{self_link_base}?#{query.to_query}"
      end
    end
  end
end
