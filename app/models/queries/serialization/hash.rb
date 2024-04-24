#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Queries
  module Serialization
    module Hash
      extend ActiveSupport::Concern

      class_methods do
        def from_hash(hash)
          new(user: hash[:user]).tap do |query|
            query.add_filters hash[:filters] if hash[:filters].present?
            query.order hash[:orders] if hash[:orders].present?
            query.group hash[:group_by] if hash[:group_by].present?
            query.select(*hash[:selects]) if hash[:selects].present?
          end
        end
      end

      def to_hash
        {
          filters: filters.map { |f| { name: f.name, operator: f.operator, values: f.values } },
          orders: orders.to_h { |o| [o.attribute, o.direction] },
          group_by: respond_to?(:group_by) ? group_by : nil,
          selects: selects.map(&:attribute),
          user:
        }
      end

      def add_filters(filters)
        filters.each do |f|
          where(f[:name], f[:operator], f[:values])
        end
      end
    end
  end
end
